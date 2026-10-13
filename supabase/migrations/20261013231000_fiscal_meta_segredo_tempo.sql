create or replace function public.fiscal_meta_segredo(p_slot text)
 returns text language plpgsql security definer set search_path to 'public', 'extensions', 'vault', 'pg_temp'
as $function$
declare v_int uuid; v_resp extensions.http_response; i int;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor le segredo'; end if;
  if p_slot not in ('token', 'app_secret', 'verify_token', 'pin') then raise exception 'slot invalido'; end if;
  select meta_integracao_id into v_int from fiscal_config where id;
  if v_int is null then raise exception 'integracao da Meta nao ligada no Fiscal'; end if;
  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '15000');
  for i in 1..2 loop
    begin
      v_resp := fiscal_porta(jsonb_build_object('op', 'rpc', 'funcao', 'integracao_segredo_ler',
                  'args', jsonb_build_object('p_integracao_id', v_int, 'p_slot', p_slot)));
      exit when v_resp.status = 200;
    exception when others then
      if i = 2 then raise; end if;
    end;
  end loop;
  if v_resp.status <> 200 then
    raise exception 'a BL recusou o segredo % (status %)', p_slot, v_resp.status;
  end if;
  return v_resp.content::jsonb #>> '{}';
end $function$;
