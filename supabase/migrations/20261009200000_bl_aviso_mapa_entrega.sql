create or replace function public.fiscal_bl_rpc(p_funcao text, p_args jsonb)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_chave text; v_ref text; v_resp extensions.http_response;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if p_funcao !~ '^[a-z_][a-z0-9_]*$' then raise exception 'funcao invalida'; end if;
  select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'bl_service_key';
  if v_chave is null then raise exception 'falta a chave da BL no cofre'; end if;
  select banco_bl_ref into v_ref from fiscal_config where id;
  select * into v_resp from extensions.http((
    'POST', 'https://' || v_ref || '.supabase.co/rest/v1/rpc/' || p_funcao,
    array[extensions.http_header('apikey', v_chave), extensions.http_header('Authorization', 'Bearer ' || v_chave)],
    'application/json', coalesce(p_args, '{}')::text)::extensions.http_request);
  if v_resp.status not in (200, 204) then
    raise exception 'a BL respondeu % : %', v_resp.status, left(v_resp.content, 300);
  end if;
  return nullif(v_resp.content, '')::jsonb;
end $function$;
revoke all on function public.fiscal_bl_rpc(text, jsonb) from public, anon, authenticated;

create table if not exists public.fiscal_sync (
  destino text primary key,
  ultimo_seq bigint not null default 0,
  estado text not null default 'resync_pendente' check (estado in ('ok', 'resync_pendente')),
  atualizado_em timestamptz not null default now()
);
alter table public.fiscal_sync enable row level security;
revoke all on public.fiscal_sync from anon, authenticated;
insert into public.fiscal_sync (destino) values ('fiscal') on conflict do nothing;

create table if not exists public.wa_rota_carteira (
  empresa_id uuid primary key,
  dono_id uuid,
  seq bigint,
  atualizado_em timestamptz not null default now()
);
alter table public.wa_rota_carteira enable row level security;
drop policy if exists wa_rota_carteira_ler on public.wa_rota_carteira;
create policy wa_rota_carteira_ler on public.wa_rota_carteira for select to authenticated using (fiscal_nivel() is not null);
revoke insert, update, delete on public.wa_rota_carteira from anon, authenticated;

create table if not exists public.wa_rota_numero (
  telefone_chave text primary key,
  pessoa_id uuid,
  empresa_id uuid,
  empresas jsonb not null default '[]',
  ambiguo boolean not null default false,
  resolvido_em timestamptz,
  pedido_em timestamptz not null default now()
);
create index if not exists wa_rota_numero_pessoa_ix on public.wa_rota_numero (pessoa_id);
create index if not exists wa_rota_numero_pendente_ix on public.wa_rota_numero (pedido_em) where resolvido_em is null;
alter table public.wa_rota_numero enable row level security;
drop policy if exists wa_rota_numero_ler on public.wa_rota_numero;
create policy wa_rota_numero_ler on public.wa_rota_numero for select to authenticated using (fiscal_nivel() is not null);
revoke insert, update, delete on public.wa_rota_numero from anon, authenticated;

create or replace function public.wa_bl_aviso_assinatura_ok(p_corpo text, p_assinatura text)
 returns boolean language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_seg text;
begin
  if not fiscal_e_servidor() then return false; end if;
  select decrypted_secret into v_seg from vault.decrypted_secrets where name = 'aviso_bl_fiscal_hmac';
  if v_seg is null or coalesce(p_assinatura, '') = '' then return false; end if;
  return encode(extensions.hmac(convert_to(p_corpo, 'UTF8'), convert_to(v_seg, 'UTF8'), 'sha256'), 'hex') = lower(p_assinatura);
end $function$;
revoke all on function public.wa_bl_aviso_assinatura_ok(text, text) from public, anon, authenticated;

create or replace function public.wa_rota_marcar_numero(p_telefone text)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v text := wa_telefone_chave(p_telefone);
begin
  if v is null then return; end if;
  insert into wa_rota_numero (telefone_chave, resolvido_em, pedido_em) values (v, null, now())
  on conflict (telefone_chave) do update set resolvido_em = null, pedido_em = now();
end $function$;
revoke all on function public.wa_rota_marcar_numero(text) from public, anon, authenticated;

create or replace function public.wa_rota_aplicar(p_seq bigint, p_tipo text, p_payload jsonb)
 returns text language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare s fiscal_sync%rowtype; v_emp uuid; v_pes uuid;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  select * into s from fiscal_sync where destino = 'fiscal' for update;
  if p_seq <= s.ultimo_seq then return 'repetido'; end if;
  if s.estado <> 'ok' or p_seq > s.ultimo_seq + 1 then
    update fiscal_sync set estado = 'resync_pendente', atualizado_em = now() where destino = 'fiscal';
    return 'buraco';
  end if;
  v_emp := nullif(p_payload->>'empresa_id', '')::uuid;
  v_pes := coalesce(nullif(p_payload->>'pessoa_id', ''), nullif(p_payload->>'cliente_id', ''))::uuid;
  if p_payload ? 'aberta' and v_emp is not null then
    if (p_payload->>'aberta')::boolean then
      insert into wa_rota_carteira (empresa_id, dono_id, seq, atualizado_em) values (v_emp, (p_payload->>'usuario_id')::uuid, p_seq, now())
      on conflict (empresa_id) do update set dono_id = excluded.dono_id, seq = excluded.seq, atualizado_em = now();
    else
      update wa_rota_carteira set dono_id = null, seq = p_seq, atualizado_em = now()
       where empresa_id = v_emp and dono_id = (p_payload->>'usuario_id')::uuid;
    end if;
  elsif p_payload->>'op' = 'ATIVO' and v_emp is not null and not coalesce((p_payload->>'ativo')::boolean, true) then
    update wa_rota_carteira set dono_id = null, seq = p_seq, atualizado_em = now() where empresa_id = v_emp;
    update wa_rota_numero set resolvido_em = null, pedido_em = now() where empresa_id = v_emp or empresas @> jsonb_build_array(jsonb_build_object('empresa_id', v_emp));
  else
    if coalesce(p_payload->>'whatsapp', '') <> '' then perform wa_rota_marcar_numero(p_payload->>'whatsapp'); end if;
    if coalesce(p_payload->>'whatsapp_antigo', '') <> '' then perform wa_rota_marcar_numero(p_payload->>'whatsapp_antigo'); end if;
    update wa_rota_numero set resolvido_em = null, pedido_em = now()
     where (v_pes is not null and pessoa_id = v_pes)
        or (v_emp is not null and (empresa_id = v_emp or empresas @> jsonb_build_array(jsonb_build_object('empresa_id', v_emp))));
    if p_payload ? 'contato_id' and coalesce(p_payload->>'whatsapp', '') = '' then
      update wa_rota_numero set resolvido_em = null, pedido_em = now() where pessoa_id is null and empresa_id is null;
    end if;
  end if;
  update fiscal_sync set ultimo_seq = p_seq, atualizado_em = now() where destino = 'fiscal';
  return 'aplicado';
end $function$;
revoke all on function public.wa_rota_aplicar(bigint, text, jsonb) from public, anon, authenticated;

create or replace function public.wa_rota_ressincronizar()
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare snap jsonb; v_seq bigint;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  perform 1 from fiscal_sync where destino = 'fiscal' for update;
  snap := fiscal_bl_rpc('rota_snapshot', jsonb_build_object('p_destino', 'fiscal'));
  v_seq := coalesce((snap->>'ultimo_seq')::bigint, 0);
  delete from wa_rota_carteira;
  insert into wa_rota_carteira (empresa_id, dono_id, seq, atualizado_em)
  select (x->>'empresa_id')::uuid, (x->>'usuario_id')::uuid, v_seq, now() from jsonb_array_elements(coalesce(snap->'carteira', '[]')) x
  on conflict (empresa_id) do update set dono_id = excluded.dono_id, seq = excluded.seq, atualizado_em = now();
  insert into wa_rota_numero (telefone_chave, resolvido_em, pedido_em)
  select distinct telefone_chave, null::timestamptz, now() from wa_contato where telefone_chave is not null
  on conflict (telefone_chave) do update set resolvido_em = null, pedido_em = now();
  update fiscal_sync set ultimo_seq = v_seq, estado = 'ok', atualizado_em = now() where destino = 'fiscal';
  return jsonb_build_object('ok', true, 'ultimo_seq', v_seq, 'carteira', jsonb_array_length(coalesce(snap->'carteira', '[]')));
end $function$;
revoke all on function public.wa_rota_ressincronizar() from public, anon, authenticated;

create or replace function public.wa_rota_resolver(p_limite int default 50)
 returns int language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare r record; d jsonb; n int := 0;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  for r in select telefone_chave from wa_rota_numero where resolvido_em is null order by pedido_em limit greatest(1, least(p_limite, 200)) for update skip locked loop
    begin
      d := fiscal_bl_rpc('whatsapp_destino', jsonb_build_object('p_whatsapp', r.telefone_chave, 'p_bsuid', null));
      update wa_rota_numero set
        pessoa_id = nullif(d->>'pessoa_id', '')::uuid,
        empresa_id = nullif(d->>'empresa_id', '')::uuid,
        empresas = coalesce(d->'empresas', '[]'),
        ambiguo = coalesce(d->>'erro', '') = 'ambiguo',
        resolvido_em = now()
       where telefone_chave = r.telefone_chave;
      n := n + 1;
    exception when others then
      raise warning 'resolver % falhou: %', r.telefone_chave, sqlerrm;
    end;
  end loop;
  return n;
end $function$;
revoke all on function public.wa_rota_resolver(int) from public, anon, authenticated;

create or replace function public.wa_rota_dono(p_telefone_chave text)
 returns uuid language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  with r as (select * from wa_rota_numero where telefone_chave = p_telefone_chave and resolvido_em is not null and not ambiguo),
       donos as (
         select e.dono_id from r join wa_rota_carteira e on e.empresa_id = r.empresa_id where e.dono_id is not null
         union
         select e.dono_id from r, jsonb_array_elements(r.empresas) x join wa_rota_carteira e on e.empresa_id = (x->>'empresa_id')::uuid
          where r.empresa_id is null and e.dono_id is not null)
  select case when (select count(distinct dono_id) from donos) = 1 then (select dono_id from donos limit 1) end;
$function$;
revoke all on function public.wa_rota_dono(text) from public, anon;
grant execute on function public.wa_rota_dono(text) to authenticated;

do $$ begin
  if not exists (select 1 from vault.secrets where name = 'bl_aviso_chave_interna') then
    perform vault.create_secret(encode(extensions.gen_random_bytes(32), 'hex'), 'bl_aviso_chave_interna');
  end if;
end $$;

create or replace function public.bl_aviso_chave_ok(p_chave text)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select coalesce(p_chave, '') <> '' and p_chave = (select decrypted_secret from vault.decrypted_secrets where name = 'bl_aviso_chave_interna');
$function$;
revoke all on function public.bl_aviso_chave_ok(text) from public, anon, authenticated;

create or replace function public.wa_contato_rota_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_chave text;
begin
  if new.telefone_chave is null then return null; end if;
  if exists (select 1 from wa_rota_numero where telefone_chave = new.telefone_chave) then return null; end if;
  perform wa_rota_marcar_numero(new.telefone_chave);
  begin
    select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'bl_aviso_chave_interna';
    perform net.http_post(url := 'https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/bl-aviso',
      body := jsonb_build_object('acao', 'resolver'),
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-chave-interna', v_chave));
  exception when others then raise warning 'pedir rota falhou: %', sqlerrm;
  end;
  return null;
end $function$;
revoke all on function public.wa_contato_rota_tg() from public, anon, authenticated;
drop trigger if exists wa_contato_rota on public.wa_contato;
create trigger wa_contato_rota after insert or update of telefone_chave on public.wa_contato for each row execute function public.wa_contato_rota_tg();

do $$ begin
  begin alter publication supabase_realtime add table public.wa_rota_carteira; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.wa_rota_numero; exception when duplicate_object then null; end;
end $$;
