create or replace function fiscal_meus_setores() returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
begin
  if fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  return coalesce((select jsonb_agg(distinct r->>'setor_id')
                     from jsonb_array_elements(fiscal_bl('usuario_setores?select=setor_id&usuario_id=eq.' || auth.uid())) r), '[]'::jsonb);
end $$;

create or replace function fiscal_pessoas_montar(p_linhas jsonb) returns jsonb
language plpgsql stable security definer set search_path = public, pg_temp as $$
declare v_vis uuid[]; v_emp jsonb;
begin
  select coalesce(array_agg(distinct (r->>'empresa_id')::uuid), '{}') into v_vis
    from jsonb_array_elements(coalesce(p_linhas, '[]')) r
   where r->>'empresa_id' is not null
     and coalesce((r->>'vinculo_empresa_ativo')::boolean, true)
     and (fiscal_e_servidor() or fiscal_pode_ver_empresa((r->>'empresa_id')::uuid));
  if cardinality(v_vis) = 0 then return '[]'::jsonb; end if;
  v_emp := fiscal_bl('you_clientes_para_fiscal?select=empresa_id,razao_social,nome_fantasia,cnpj&empresa_id=in.('
                     || array_to_string(v_vis, ',') || ')');
  return coalesce((
    select jsonb_agg(jsonb_build_object('pessoa_id', p.pessoa_id, 'nome', p.nome, 'whatsapp', p.whatsapp, 'empresas', p.empresas) order by p.nome)
      from (select (r->>'pessoa_id')::uuid pessoa_id, max(r->>'nome') nome, max(r->>'whatsapp') whatsapp,
                   jsonb_agg(distinct jsonb_build_object('empresa_id', e->>'empresa_id',
                                                          'nome', coalesce(nullif(e->>'razao_social', ''), e->>'nome_fantasia'),
                                                          'doc', e->>'cnpj')) empresas
              from jsonb_array_elements(p_linhas) r
              join jsonb_array_elements(v_emp) e on e->>'empresa_id' = r->>'empresa_id'
             where r->>'pessoa_id' is not null and (r->>'empresa_id')::uuid = any(v_vis)
             group by 1) p), '[]'::jsonb);
end $$;

create or replace function fiscal_buscar_pessoas(p_texto text) returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare v_t text; v_d text; v_f text;
begin
  if not fiscal_e_servidor() and fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  v_t := btrim(regexp_replace(coalesce(p_texto, ''), '[^0-9A-Za-zÀ-ÿ ]', '', 'g'));
  v_d := regexp_replace(coalesce(p_texto, ''), '\D', '', 'g');
  if length(v_t) < 2 then return '[]'::jsonb; end if;
  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '30000');
  v_f := case when length(v_d) >= 3 and length(v_d) = length(replace(v_t, ' ', ''))
              then 'or=(cpf.like.*' || v_d || '*,whatsapp.like.*' || v_d || '*)'
              else 'nome=ilike.*' || replace(v_t, ' ', '*') || '*' end;
  return fiscal_pessoas_montar(fiscal_bl('you_pessoas_para_fiscal?select=pessoa_id,nome,whatsapp,empresa_id,vinculo_empresa_ativo&ativa=eq.true&'
                                         || v_f || '&limit=200'));
end $$;

create or replace function fiscal_pessoas_contato(p_ids uuid[]) returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  if not fiscal_e_servidor() and fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  if coalesce(cardinality(p_ids), 0) = 0 then return '[]'::jsonb; end if;
  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '30000');
  return fiscal_pessoas_montar(fiscal_bl('you_pessoas_para_fiscal?select=pessoa_id,nome,whatsapp,empresa_id,vinculo_empresa_ativo&pessoa_id=in.('
                                         || array_to_string(p_ids[1:100], ',') || ')'));
end $$;

revoke execute on function fiscal_meus_setores(), fiscal_pessoas_montar(jsonb), fiscal_buscar_pessoas(text), fiscal_pessoas_contato(uuid[]) from public, anon;
grant execute on function fiscal_meus_setores(), fiscal_buscar_pessoas(text), fiscal_pessoas_contato(uuid[]) to authenticated;
