create or replace function public.wa_modelos_sincronizar(p_waba text)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $$
declare v_url text; v_resp extensions.http_response; j jsonb; t jsonb; n int := 0; v_versao text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if p_waba !~ '^[0-9]{6,20}$' then raise exception 'waba invalida'; end if;
  v_versao := coalesce(fiscal_meta_config()->>'versao', 'v26.0');
  v_url := 'https://graph.facebook.com/' || v_versao || '/' || p_waba || '/message_templates?fields=id,name,language,status,category,components,rejected_reason&limit=200';
  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '30000');
  loop
    select * into v_resp from extensions.http(('GET', v_url, array[extensions.http_header('Authorization', 'Bearer ' || fiscal_meta_segredo('token'))], null, null)::extensions.http_request);
    if v_resp.status <> 200 then raise exception 'Meta respondeu %: %', v_resp.status, left(v_resp.content, 200); end if;
    j := v_resp.content::jsonb;
    for t in select * from jsonb_array_elements(coalesce(j->'data', '[]')) loop
      insert into wa_modelo (meta_id, nome, idioma, categoria, estado, motivo, componentes, atualizado_em)
      values (t->>'id', t->>'name', t->>'language', t->>'category', t->>'status', nullif(t->>'rejected_reason', 'NONE'), t->'components', now())
      on conflict (meta_id) do update set nome = excluded.nome, idioma = excluded.idioma, categoria = excluded.categoria,
        estado = excluded.estado, motivo = excluded.motivo, componentes = excluded.componentes, atualizado_em = now();
      n := n + 1;
    end loop;
    v_url := j->'paging'->>'next';
    exit when v_url is null;
  end loop;
  return jsonb_build_object('ok', true, 'modelos', n);
end $$;
revoke all on function public.wa_modelos_sincronizar(text) from public, anon, authenticated;
grant execute on function public.wa_modelos_sincronizar(text) to service_role;
