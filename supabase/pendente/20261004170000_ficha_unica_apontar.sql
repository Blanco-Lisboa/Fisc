-- ponte para as funcoes da ficha (banco BL)
create or replace function public.fiscal_bl_rpc(p_funcao text, p_args jsonb)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'extensions', 'vault', 'pg_temp'
as $$
declare v_chave text; v_ref text; v_resp extensions.http_response;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor chama a BL'; end if;
  if p_funcao not in ('ficha_por_whatsapp', 'ficha_ligar_whatsapp', 'ficha_criar_lead_whatsapp') then
    raise exception 'funcao da BL nao permitida: %', p_funcao;
  end if;
  select banco_bl_ref into v_ref from fiscal_config where id;
  select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'bl_service_key';
  if v_chave is null then raise exception 'falta a chave da BL no cofre'; end if;
  select * into v_resp from extensions.http((
    'POST', 'https://' || v_ref || '.supabase.co/rest/v1/rpc/' || p_funcao,
    array[extensions.http_header('apikey', v_chave),
          extensions.http_header('Authorization', 'Bearer ' || v_chave)],
    'application/json', p_args::text)::extensions.http_request);
  if v_resp.status <> 200 then
    raise exception 'a BL respondeu % em %: %', v_resp.status, p_funcao, left(v_resp.content, 200);
  end if;
  return v_resp.content::jsonb;
end $$;
revoke all on function public.fiscal_bl_rpc(text, jsonb) from public, anon, authenticated;

-- conversa aponta para a ficha
alter table wa_conversa add column if not exists lead_id uuid;
alter table wa_conversa add column if not exists empresa_ids uuid[] not null default '{}';
alter table wa_conversa add column if not exists ficha_origem text;
alter table wa_conversa add column if not exists ficha_em timestamptz;
create index if not exists wa_conversa_empresas_ix on wa_conversa using gin (empresa_ids);
create index if not exists wa_conversa_lead_ix on wa_conversa (lead_id) where lead_id is not null;

create or replace function public.wa_conversa_identificar(p_conversa_id uuid, p_criar_lead boolean default true)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare cv wa_conversa%rowtype; f jsonb; v_lead uuid; v_emp uuid[]; v_comp uuid;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  select * into cv from wa_conversa where id = p_conversa_id for update;
  if cv.id is null then return jsonb_build_object('ok', false, 'erro', 'conversa nao existe'); end if;
  if cv.e_grupo then return jsonb_build_object('ok', true, 'grupo', true); end if;

  f := fiscal_bl_rpc('ficha_por_whatsapp', jsonb_build_object('p_telefone', cv.contato_telefone, 'p_bsuid', cv.contato_bsuid));

  if coalesce((f->>'achou')::boolean, false) and f->>'origem' <> 'ultimos8' then
    select coalesce(array_agg(distinct (x->>'empresa_id')::uuid), '{}') into v_emp
      from jsonb_array_elements(coalesce(f->'empresas', '[]')) x;
    update wa_conversa set cliente_id = (f->>'cliente_id')::uuid, empresa_ids = v_emp,
                           ficha_origem = f->>'origem', ficha_em = now()
     where id = cv.id;
    return jsonb_build_object('ok', true, 'cliente_id', f->>'cliente_id', 'origem', f->>'origem',
                              'empresas', cardinality(v_emp));
  end if;

  if coalesce((f->>'achou')::boolean, false) then
    update wa_conversa set ficha_origem = 'ultimos8_a_conferir', ficha_em = now() where id = cv.id;
    return jsonb_build_object('ok', true, 'a_conferir', true);
  end if;

  v_lead := cv.lead_id;
  if v_lead is null then
    select lead_id into v_lead from wa_conversa
     where lead_id is not null and id <> cv.id
       and ((cv.contato_telefone is not null and contato_telefone = cv.contato_telefone)
         or (cv.contato_bsuid is not null and contato_bsuid = cv.contato_bsuid))
     limit 1;
  end if;
  if v_lead is null and p_criar_lead and cv.contato_telefone is not null then
    select companhia_grupo_id into v_comp from fiscal_config where id;
    f := fiscal_bl_rpc('ficha_criar_lead_whatsapp', jsonb_build_object(
           'p_telefone', cv.contato_telefone, 'p_bsuid', cv.contato_bsuid,
           'p_nome', cv.contato_nome, 'p_companhia', v_comp, 'p_por', null));
    if coalesce((f->>'ok')::boolean, false) then v_lead := (f->>'lead_id')::uuid; end if;
  end if;

  update wa_conversa set lead_id = v_lead, cliente_id = null, empresa_ids = '{}',
                         ficha_origem = case when v_lead is null then 'sem_ficha' else 'lead' end,
                         ficha_em = now()
   where id = cv.id;
  return jsonb_build_object('ok', true, 'lead_id', v_lead);
end $$;
revoke all on function public.wa_conversa_identificar(uuid, boolean) from public, anon, authenticated;
grant execute on function public.wa_conversa_identificar(uuid, boolean) to service_role;

-- quem ve a conversa: empresas da ficha x carteira (ou assistente/gerente)
create or replace function public.fiscal_pode_ver_conversa(p_empresa_ids uuid[])
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select case
    when fiscal_nivel() in ('assistente', 'gerente') then
      cardinality(p_empresa_ids) = 0 or p_empresa_ids && fiscal_empresas_da_you()
    when fiscal_nivel() is not null then
      exists (select 1 from fiscal_carteira k
               where k.usuario_id = auth.uid() and k.ativo
                 and k.empresa_id = any(p_empresa_ids)
                 and k.empresa_id = any(fiscal_empresas_da_you()))
    else false end;
$$;
revoke all on function public.fiscal_pode_ver_conversa(uuid[]) from public, anon;
grant execute on function public.fiscal_pode_ver_conversa(uuid[]) to authenticated;

drop policy if exists wa_conversa_ler on wa_conversa;
drop policy if exists wa_conversa_editar on wa_conversa;
create policy wa_conversa_ler on wa_conversa for select to authenticated
  using (fiscal_pode_ver_conversa(empresa_ids));
create policy wa_conversa_editar on wa_conversa for update to authenticated
  using (fiscal_pode_ver_conversa(empresa_ids)) with check (fiscal_pode_ver_conversa(empresa_ids));

drop policy if exists wa_mensagem_ler on wa_mensagem;
create policy wa_mensagem_ler on wa_mensagem for select to authenticated
  using (exists (select 1 from wa_conversa c where c.id = wa_mensagem.conversa_id and fiscal_pode_ver_conversa(c.empresa_ids)));

drop policy if exists wa_midia_ler on wa_midia;
create policy wa_midia_ler on wa_midia for select to authenticated
  using (exists (select 1 from wa_mensagem m join wa_conversa c on c.id = m.conversa_id
                  where m.id = wa_midia.mensagem_id and fiscal_pode_ver_conversa(c.empresa_ids)));

drop policy if exists wa_conversa_evento_ler on wa_conversa_evento;
create policy wa_conversa_evento_ler on wa_conversa_evento for select to authenticated
  using (exists (select 1 from wa_conversa c where c.id = wa_conversa_evento.conversa_id and fiscal_pode_ver_conversa(c.empresa_ids)));

drop policy if exists wa_conversa_etiqueta_ler on wa_conversa_etiqueta;
drop policy if exists wa_conversa_etiqueta_marcar on wa_conversa_etiqueta;
create policy wa_conversa_etiqueta_ler on wa_conversa_etiqueta for select to authenticated
  using (exists (select 1 from wa_conversa c where c.id = wa_conversa_etiqueta.conversa_id and fiscal_pode_ver_conversa(c.empresa_ids)));
create policy wa_conversa_etiqueta_marcar on wa_conversa_etiqueta for all to authenticated
  using (exists (select 1 from wa_conversa c where c.id = wa_conversa_etiqueta.conversa_id and fiscal_pode_ver_conversa(c.empresa_ids)))
  with check (exists (select 1 from wa_conversa c where c.id = wa_conversa_etiqueta.conversa_id and fiscal_pode_ver_conversa(c.empresa_ids)));

-- conversa da Meta sem cadastro de contato no Fiscal
drop function if exists public.wa_meta_conversa(uuid, uuid, text, text, text);
create or replace function public.wa_meta_conversa(p_numero uuid, p_tel text, p_bsuid text, p_nome text)
returns uuid
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_conv uuid;
begin
  select id into v_conv from wa_conversa
   where numero_id = p_numero and estado <> 'arquivada'
     and ((p_tel is not null and contato_telefone = p_tel) or (p_bsuid is not null and contato_bsuid = p_bsuid))
   order by (contato_telefone = p_tel) desc nulls last
   limit 1;
  if v_conv is null then
    begin
      insert into wa_conversa (numero_id, contato_telefone, contato_bsuid, contato_nome, estado, primeiro_em)
      values (p_numero, p_tel, p_bsuid, p_nome, 'nova', now())
      returning id into v_conv;
    exception when unique_violation then
      select id into v_conv from wa_conversa
       where numero_id = p_numero and estado <> 'arquivada'
         and (contato_telefone = p_tel or contato_bsuid = p_bsuid)
       limit 1;
    end;
  else
    update wa_conversa set contato_nome = coalesce(contato_nome, p_nome),
                           contato_telefone = coalesce(contato_telefone, p_tel),
                           contato_bsuid = coalesce(contato_bsuid, p_bsuid)
     where id = v_conv and (contato_nome is null or contato_telefone is null or contato_bsuid is null);
  end if;
  return v_conv;
end $$;
revoke all on function public.wa_meta_conversa(uuid, text, text, text) from public, anon, authenticated;
drop function if exists public.wa_meta_contato(text, text, text, text);
