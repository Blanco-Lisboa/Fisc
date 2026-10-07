create or replace function public.fiscal_buscar_clientes(p_texto text)
returns table(empresa_id uuid, razao_social text, nome_fantasia text, cnpj text)
language plpgsql stable security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_t text; v_d text; v_filtro text;
begin
  if not fiscal_e_servidor() and fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  v_t := btrim(regexp_replace(coalesce(p_texto, ''), '[^0-9A-Za-zÀ-ÿ ]', '', 'g'));
  v_d := regexp_replace(coalesce(p_texto, ''), '\D', '', 'g');
  if length(v_t) < 2 then return; end if;
  v_filtro := '(razao_social.ilike.*' || replace(v_t, ' ', '%20') || '*,nome_fantasia.ilike.*' || replace(v_t, ' ', '%20') || '*'
              || case when length(v_d) >= 3 then ',cnpj.like.*' || v_d || '*' else '' end || ')';
  return query
  select (r->>'empresa_id')::uuid, r->>'razao_social', r->>'nome_fantasia', r->>'cnpj'
    from jsonb_array_elements(fiscal_bl('you_clientes_para_fiscal?select=empresa_id,razao_social,nome_fantasia,cnpj&ativa=eq.true&or=' || v_filtro || '&limit=60')) r
   where fiscal_e_servidor() or fiscal_pode_ver_empresa((r->>'empresa_id')::uuid)
   limit 20;
end $$;
revoke all on function public.fiscal_buscar_clientes(text) from public, anon;
grant execute on function public.fiscal_buscar_clientes(text) to authenticated, service_role;
