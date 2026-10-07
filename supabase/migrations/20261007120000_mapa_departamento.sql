create or replace function public.fiscal_mapa_departamento()
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_you uuid[];
begin
  if not fiscal_e_servidor() and coalesce(fiscal_nivel(), '') not in ('assistente', 'gerente') then
    raise exception 'so gestor do Fiscal';
  end if;
  v_you := fiscal_empresas_da_you();
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', u.id, 'nome', u.nome, 'nivel', u.nivel, 'foto_url', null, 'entrada_hoje', null,
             'carteira', (select count(*) from fiscal_carteira k
                           where k.usuario_id = u.id and k.ativo and k.empresa_id = any(v_you)))
           order by u.nome)
      from fiscal_usuario u
     where u.ativo), '[]'::jsonb);
end $$;
revoke all on function public.fiscal_mapa_departamento() from public, anon;
grant execute on function public.fiscal_mapa_departamento() to authenticated, service_role;

create or replace function public.fiscal_carteira_detalhe(p_usuario uuid)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_you uuid[]; v_ids uuid[]; v_lista text; v_assunto text;
  v_emp jsonb; v_qt jsonb; v_pes jsonb; v_map jsonb; v_lresp text; v_dele jsonb := '[]'; v_lout text; v_eout jsonb := '[]';
begin
  if not fiscal_e_servidor() and coalesce(fiscal_nivel(), '') not in ('assistente', 'gerente') then
    raise exception 'so gestor do Fiscal';
  end if;
  v_you := fiscal_empresas_da_you();
  select coalesce(array_agg(distinct k.empresa_id), '{}') into v_ids
    from fiscal_carteira k where k.usuario_id = p_usuario and k.ativo and k.empresa_id = any(v_you);
  if coalesce(array_length(v_ids, 1), 0) = 0 then return '[]'::jsonb; end if;
  select string_agg(x::text, ',') into v_lista from unnest(v_ids) x;

  v_emp := fiscal_bl('you_clientes_para_fiscal?select=empresa_id,razao_social,nome_fantasia,cnpj&empresa_id=in.(' || v_lista || ')');
  v_assunto := fiscal_bl('cliente_assunto?select=id&ativo=eq.true&nome=ilike.*quem%20trata*') -> 0 ->> 'id';
  v_qt := case when v_assunto is null then '[]'::jsonb else
          fiscal_bl('cliente_empresa_assunto?select=empresa_id,cliente_id&removido_em=is.null&assunto_id=eq.' || v_assunto
                    || '&empresa_id=in.(' || v_lista || ')') end;
  v_pes := fiscal_bl('you_pessoas_para_fiscal?select=pessoa_id,nome,empresa_id,papel&empresa_id=in.(' || v_lista || ')');

  select coalesce(jsonb_agg(jsonb_build_object(
           'empresa_id', e->>'empresa_id', 'cnpj', e->>'cnpj',
           'empresa', coalesce(nullif(e->>'razao_social', ''), e->>'nome_fantasia'),
           'resp_id', coalesce(qt.cid, ti.pid), 'origem', case when qt.cid is not null then 'quem_trata' when ti.pid is not null then 'titular' end)), '[]')
    into v_map
    from jsonb_array_elements(v_emp) e
    left join lateral (select q->>'cliente_id' cid from jsonb_array_elements(v_qt) q where q->>'empresa_id' = e->>'empresa_id' limit 1) qt on true
    left join lateral (select p->>'pessoa_id' pid from jsonb_array_elements(v_pes) p
                        where p->>'empresa_id' = e->>'empresa_id' and p->>'papel' = 'titular' limit 1) ti on true;

  select string_agg(distinct m->>'resp_id', ',') into v_lresp from jsonb_array_elements(v_map) m where m->>'resp_id' is not null;
  if v_lresp is not null then
    v_dele := fiscal_bl('you_pessoas_para_fiscal?select=pessoa_id,nome,empresa_id&pessoa_id=in.(' || v_lresp || ')');
    select string_agg(distinct d->>'empresa_id', ',') into v_lout
      from jsonb_array_elements(v_dele) d
     where not ((d->>'empresa_id')::uuid = any(v_ids)) and (d->>'empresa_id')::uuid = any(v_you);
    if v_lout is not null then
      v_eout := fiscal_bl('you_clientes_para_fiscal?select=empresa_id,razao_social,nome_fantasia,cnpj&empresa_id=in.(' || v_lout || ')');
    end if;
  end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'empresa_id', m->>'empresa_id', 'cnpj', m->>'cnpj', 'empresa', m->>'empresa', 'origem', m->>'origem',
             'responsavel', (select d->>'nome' from jsonb_array_elements(v_dele) d where d->>'pessoa_id' = m->>'resp_id' limit 1),
             'outras', coalesce((
               select jsonb_agg(jsonb_build_object(
                        'empresa_id', o->>'empresa_id', 'cnpj', o->>'cnpj',
                        'empresa', coalesce(nullif(o->>'razao_social', ''), o->>'nome_fantasia'),
                        'carteira_de', (select u.nome from fiscal_carteira k join fiscal_usuario u on u.id = k.usuario_id
                                         where k.empresa_id = (o->>'empresa_id')::uuid and k.ativo limit 1)))
                 from jsonb_array_elements(v_dele) d
                 join jsonb_array_elements(v_eout) o on o->>'empresa_id' = d->>'empresa_id'
                where d->>'pessoa_id' = m->>'resp_id'), '[]'::jsonb))
           order by m->>'empresa')
      from jsonb_array_elements(v_map) m), '[]'::jsonb);
end $$;
revoke all on function public.fiscal_carteira_detalhe(uuid) from public, anon;
grant execute on function public.fiscal_carteira_detalhe(uuid) to authenticated, service_role;
