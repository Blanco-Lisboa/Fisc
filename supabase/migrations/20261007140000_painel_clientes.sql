create or replace function public.fiscal_bl_tudo(p_caminho text, p_ordem text)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_tudo jsonb := '[]'; v_lote jsonb; v_pag int := 0; v_tam int := 1000;
begin
  if not fiscal_e_servidor() and coalesce(fiscal_nivel(), '') not in ('assistente', 'gerente') then
    raise exception 'so gestor do Fiscal';
  end if;
  loop
    v_lote := fiscal_bl(p_caminho || '&order=' || p_ordem || '&limit=' || v_tam || '&offset=' || (v_pag * v_tam));
    v_tudo := v_tudo || v_lote;
    exit when jsonb_array_length(v_lote) < v_tam;
    v_pag := v_pag + 1;
    exit when v_pag > 50;
  end loop;
  return v_tudo;
end $$;
revoke all on function public.fiscal_bl_tudo(text, text) from public, anon, authenticated;
grant execute on function public.fiscal_bl_tudo(text, text) to service_role;

create or replace function public.fiscal_clientes_painel()
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_emp jsonb; v_pes jsonb; v_qt jsonb := '[]'; v_assunto text; v_cart jsonb; v_tit jsonb; v_qtm jsonb;
begin
  if not fiscal_e_servidor() and coalesce(fiscal_nivel(), '') not in ('assistente', 'gerente') then
    raise exception 'so gestor do Fiscal';
  end if;
  v_emp := fiscal_bl_tudo('you_clientes_para_fiscal?select=empresa_id,razao_social,nome_fantasia,cnpj', 'empresa_id');
  v_pes := fiscal_bl_tudo('you_pessoas_para_fiscal?select=pessoa_id,nome,empresa_id,papel', 'pessoa_id,empresa_id');
  v_assunto := fiscal_bl('cliente_assunto?select=id&ativo=eq.true&nome=ilike.*quem%20trata*') -> 0 ->> 'id';
  if v_assunto is not null then
    v_qt := fiscal_bl_tudo('cliente_empresa_assunto?select=empresa_id,cliente_id&removido_em=is.null&assunto_id=eq.' || v_assunto, 'id');
  end if;
  select coalesce(jsonb_object_agg(k.empresa_id::text, u.nome), '{}') into v_cart
    from fiscal_carteira k join fiscal_usuario u on u.id = k.usuario_id where k.ativo;
  select coalesce(jsonb_object_agg(p->>'empresa_id', p->>'pessoa_id'), '{}') into v_tit from jsonb_array_elements(v_pes) p where p->>'papel' = 'titular';
  select coalesce(jsonb_object_agg(q->>'empresa_id', q->>'cliente_id'), '{}') into v_qtm from jsonb_array_elements(v_qt) q;

  return coalesce((
    with emp as (
      select e->>'empresa_id' id, e->>'cnpj' cnpj, coalesce(nullif(e->>'razao_social', ''), e->>'nome_fantasia') nome,
             coalesce(v_qtm ->> (e->>'empresa_id'), v_tit ->> (e->>'empresa_id')) resp
        from jsonb_array_elements(v_emp) e),
    nomes as (select distinct on (p->>'pessoa_id') p->>'pessoa_id' id, p->>'nome' nome from jsonb_array_elements(v_pes) p),
    grp as (
      select emp.resp, n.nome resp_nome,
             jsonb_agg(jsonb_build_object('empresa_id', emp.id, 'cnpj', emp.cnpj, 'empresa', emp.nome,
                                          'carteira', v_cart ->> emp.id, 'apuracao', null) order by emp.nome) empresas
        from emp left join nomes n on n.id = emp.resp
       group by emp.resp, n.nome)
    select jsonb_agg(jsonb_build_object('responsavel', resp_nome, 'empresas', empresas) order by resp_nome nulls last) from grp
  ), '[]'::jsonb);
end $$;
revoke all on function public.fiscal_clientes_painel() from public, anon;
grant execute on function public.fiscal_clientes_painel() to authenticated, service_role;

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
             'id', u.id, 'nome', u.nome, 'nivel', u.nivel, 'foto_url', null, 'entrada_hoje', null, 'atencao', false,
             'carteira', (select count(*) from fiscal_carteira k
                           where k.usuario_id = u.id and k.ativo and k.empresa_id = any(v_you)))
           order by u.nome)
      from fiscal_usuario u
     where u.ativo), '[]'::jsonb);
end $$;
