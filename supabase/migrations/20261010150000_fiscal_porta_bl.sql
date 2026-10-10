create or replace function public.fiscal_porta(p_corpo jsonb)
 returns extensions.http_response language plpgsql security definer set search_path to 'public', 'extensions', 'pg_temp'
as $function$
declare v_chave text; v_ref text;
begin
  select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'porta_fiscal_chave';
  if v_chave is null then raise exception 'falta a chave da porta da BL no cofre'; end if;
  select banco_bl_ref into v_ref from fiscal_config where id;
  return extensions.http((
    'POST', 'https://' || v_ref || '.supabase.co/functions/v1/porta-fiscal',
    array[extensions.http_header('x-chave-fiscal', v_chave),
          extensions.http_header('apikey', 'sb_publishable_88ukR4t1KNTc73DxbF6-Pw_0CKW16Fe')],
    'application/json', p_corpo::text)::extensions.http_request);
end $function$;
revoke all on function public.fiscal_porta(jsonb) from public, anon, authenticated;

create or replace function public.fiscal_bl(p_caminho text)
 returns jsonb language plpgsql security definer set search_path to 'public', 'extensions', 'pg_temp'
as $function$
declare v_resp extensions.http_response; v_tab text; v_q text;
begin
  v_tab := split_part(p_caminho, '?', 1);
  v_q := case when position('?' in p_caminho) > 0 then substr(p_caminho, position('?' in p_caminho) + 1) else '' end;
  v_resp := fiscal_porta(jsonb_build_object('op', 'ler', 'tabela', v_tab, 'query', v_q));
  if v_resp.status <> 200 then
    raise exception 'a BL respondeu % : %', v_resp.status, left(v_resp.content, 300);
  end if;
  return v_resp.content::jsonb;
end $function$;
revoke all on function public.fiscal_bl(text) from public, anon, authenticated;

create or replace function public.fiscal_bl_rpc(p_funcao text, p_args jsonb)
 returns jsonb language plpgsql security definer set search_path to 'public', 'extensions', 'pg_temp'
as $function$
declare v_resp extensions.http_response;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if p_funcao !~ '^[a-z_][a-z0-9_]*$' then raise exception 'funcao invalida'; end if;
  v_resp := fiscal_porta(jsonb_build_object('op', 'rpc', 'funcao', p_funcao, 'args', coalesce(p_args, '{}')));
  if v_resp.status not in (200, 204) then
    raise exception 'a BL respondeu % : %', v_resp.status, left(v_resp.content, 300);
  end if;
  return nullif(v_resp.content, '')::jsonb;
end $function$;
revoke all on function public.fiscal_bl_rpc(text, jsonb) from public, anon, authenticated;

create or replace function public.fiscal_meta_segredo(p_slot text)
 returns text language plpgsql security definer set search_path to 'public', 'extensions', 'vault', 'pg_temp'
as $function$
declare v_int uuid; v_resp extensions.http_response;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor le segredo'; end if;
  if p_slot not in ('token', 'app_secret', 'verify_token', 'pin') then raise exception 'slot invalido'; end if;
  select meta_integracao_id into v_int from fiscal_config where id;
  if v_int is null then raise exception 'integracao da Meta nao ligada no Fiscal'; end if;
  v_resp := fiscal_porta(jsonb_build_object('op', 'rpc', 'funcao', 'integracao_segredo_ler',
              'args', jsonb_build_object('p_integracao_id', v_int, 'p_slot', p_slot)));
  if v_resp.status <> 200 then
    raise exception 'a BL recusou o segredo % (status %)', p_slot, v_resp.status;
  end if;
  return v_resp.content::jsonb #>> '{}';
end $function$;
revoke all on function public.fiscal_meta_segredo(text) from public, anon, authenticated;
