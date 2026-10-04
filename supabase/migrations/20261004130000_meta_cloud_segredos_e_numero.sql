-- segredos e configuracao (vem da integracao do banco BL)
alter table fiscal_config add column if not exists meta_integracao_id uuid;

create index if not exists wa_mensagem_id_whatsapp_ix on wa_mensagem (id_whatsapp) where id_whatsapp is not null;

create or replace function public.fiscal_meta_segredo(p_slot text)
returns text
language plpgsql security definer
set search_path to 'public', 'extensions', 'vault', 'pg_temp'
as $$
declare v_chave text; v_ref text; v_int uuid; v_resp extensions.http_response;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor le segredo'; end if;
  if p_slot not in ('token', 'app_secret', 'verify_token') then raise exception 'slot invalido'; end if;
  select banco_bl_ref, meta_integracao_id into v_ref, v_int from fiscal_config where id;
  if v_int is null then raise exception 'integracao da Meta nao ligada no Fiscal'; end if;
  select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'bl_service_key';
  if v_chave is null then raise exception 'falta a chave da BL no cofre'; end if;

  select * into v_resp from extensions.http((
    'POST', 'https://' || v_ref || '.supabase.co/rest/v1/rpc/integracao_segredo_ler',
    array[extensions.http_header('apikey', v_chave),
          extensions.http_header('Authorization', 'Bearer ' || v_chave)],
    'application/json',
    jsonb_build_object('p_integracao_id', v_int, 'p_slot', p_slot)::text
  )::extensions.http_request);

  if v_resp.status <> 200 then
    raise exception 'a BL recusou o segredo % (status %)', p_slot, v_resp.status;
  end if;
  return v_resp.content::jsonb #>> '{}';
end $$;

create or replace function public.fiscal_meta_config()
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_int uuid; r jsonb;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor le a configuracao'; end if;
  select meta_integracao_id into v_int from fiscal_config where id;
  if v_int is null then raise exception 'integracao da Meta nao ligada no Fiscal'; end if;
  r := fiscal_bl('integracao?id=eq.' || v_int || '&select=ativa,base_url,cabecalho_extra');
  if jsonb_array_length(r) = 0 then raise exception 'integracao da Meta nao existe na BL'; end if;
  return jsonb_build_object(
    'ativa', (r->0->>'ativa')::boolean,
    'base_url', r->0->>'base_url',
    'phone_number_id', r->0->'cabecalho_extra'->>'phone_number_id',
    'waba_id', r->0->'cabecalho_extra'->>'waba_id',
    'numero', r->0->'cabecalho_extra'->>'numero',
    'versao', coalesce(r->0->'cabecalho_extra'->>'versao', 'v26.0'));
end $$;

-- assinatura do webhook
create or replace function public.fiscal_hmac_confere(p_corpo text, p_assinatura text, p_segredo text)
returns boolean
language plpgsql immutable
set search_path to 'public', 'extensions', 'pg_temp'
as $$
declare v_calc text; v_rec text; v_dif int := 0; i int;
begin
  if p_assinatura is null or p_segredo is null or left(p_assinatura, 7) <> 'sha256=' then return false; end if;
  v_calc := encode(extensions.hmac(convert_to(p_corpo, 'UTF8'), convert_to(p_segredo, 'UTF8'), 'sha256'), 'hex');
  v_rec := lower(substr(p_assinatura, 8));
  if length(v_rec) <> length(v_calc) then return false; end if;
  for i in 1..length(v_calc) loop
    v_dif := v_dif | (ascii(substr(v_calc, i, 1)) # ascii(substr(v_rec, i, 1)));
  end loop;
  return v_dif = 0;
end $$;

create or replace function public.fiscal_meta_assinatura_ok(p_corpo text, p_assinatura text)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor confere assinatura'; end if;
  return fiscal_hmac_confere(p_corpo, p_assinatura, fiscal_meta_segredo('app_secret'));
end $$;

create or replace function public.fiscal_meta_verify_ok(p_token text)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_seg text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor confere'; end if;
  if coalesce(length(p_token), 0) < 16 then return false; end if;
  v_seg := fiscal_meta_segredo('verify_token');
  return fiscal_hmac_confere(p_token,
    'sha256=' || encode(extensions.hmac(convert_to(v_seg, 'UTF8'), convert_to('verify', 'UTF8'), 'sha256'), 'hex'),
    'verify');
end $$;

-- liga o numero da Meta ao Fiscal (uma vez, pelo servidor)
create or replace function public.fiscal_meta_ligar(p_integracao_id uuid)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare cfg jsonb; v_tel text; v_num uuid; v_outro_id uuid; v_outro_prov text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor liga a integracao'; end if;
  update fiscal_config set meta_integracao_id = p_integracao_id, atualizado_em = now() where id;
  cfg := fiscal_meta_config();
  if coalesce(cfg->>'phone_number_id', '') = '' then raise exception 'falta phone_number_id na integracao da BL'; end if;
  v_tel := regexp_replace(coalesce(cfg->>'numero', ''), '\D', '', 'g');
  if length(v_tel) < 10 or length(v_tel) > 15 then raise exception 'numero da integracao invalido'; end if;

  select id, provedor into v_outro_id, v_outro_prov from wa_numero
   where telefone = v_tel and coalesce(identificador, '') <> (cfg->>'phone_number_id');
  if v_outro_id is not null then
    raise exception 'o telefone ja esta cadastrado no numero % (provedor %)', v_outro_id, v_outro_prov;
  end if;

  insert into wa_numero (nome, telefone, provedor, identificador, ativo, conectado)
  values ('Fiscal · Meta', v_tel, 'meta_cloud', cfg->>'phone_number_id', true, false)
  on conflict (identificador) do update
    set telefone = excluded.telefone, provedor = 'meta_cloud', ativo = true, atualizado_em = now()
  returning id into v_num;

  return jsonb_build_object('ok', true, 'numero_id', v_num, 'telefone', v_tel);
end $$;

revoke all on function public.fiscal_meta_segredo(text) from public, anon, authenticated;
revoke all on function public.fiscal_meta_config() from public, anon, authenticated;
revoke all on function public.fiscal_hmac_confere(text, text, text) from public, anon, authenticated;
revoke all on function public.fiscal_meta_assinatura_ok(text, text) from public, anon, authenticated;
revoke all on function public.fiscal_meta_verify_ok(text) from public, anon, authenticated;
revoke all on function public.fiscal_meta_ligar(uuid) from public, anon, authenticated;
grant execute on function public.fiscal_meta_segredo(text) to service_role;
grant execute on function public.fiscal_meta_config() to service_role;
grant execute on function public.fiscal_meta_assinatura_ok(text, text) to service_role;
grant execute on function public.fiscal_meta_verify_ok(text) to service_role;
grant execute on function public.fiscal_meta_ligar(uuid) to service_role;

insert into storage.buckets (id, name, public, file_size_limit)
values ('wa-midia', 'wa-midia', false, 104857600)
on conflict (id) do update set public = false;
