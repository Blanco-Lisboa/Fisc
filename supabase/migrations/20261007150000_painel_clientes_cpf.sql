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
  v_pes := fiscal_bl_tudo('you_pessoas_para_fiscal?select=pessoa_id,nome,cpf,empresa_id,papel', 'pessoa_id,empresa_id');
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
    nomes as (select distinct on (p->>'pessoa_id') p->>'pessoa_id' id, p->>'nome' nome, p->>'cpf' cpf from jsonb_array_elements(v_pes) p),
    grp as (
      select emp.resp, n.nome resp_nome, n.cpf resp_cpf,
             jsonb_agg(jsonb_build_object('empresa_id', emp.id, 'cnpj', emp.cnpj, 'empresa', emp.nome,
                                          'carteira', v_cart ->> emp.id, 'apuracao', null) order by emp.nome) empresas
        from emp left join nomes n on n.id = emp.resp
       group by emp.resp, n.nome, n.cpf)
    select jsonb_agg(jsonb_build_object('responsavel', resp_nome, 'cpf', resp_cpf, 'empresas', empresas) order by resp_nome nulls last) from grp
  ), '[]'::jsonb);
end $$;
