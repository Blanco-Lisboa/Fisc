create or replace function public.fiscal_central_gestor()
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_you uuid[]; v_total int; v_sem int; v_mes date := date_trunc('month', current_date)::date;
begin
  if not fiscal_e_servidor() and coalesce(fiscal_nivel(), '') not in ('assistente', 'gerente') then
    raise exception 'so gestor do Fiscal';
  end if;
  v_you := fiscal_empresas_da_you();
  v_total := coalesce(array_length(v_you, 1), 0);
  select count(*) into v_sem from unnest(v_you) e
   where not exists (select 1 from fiscal_carteira k where k.empresa_id = e and k.ativo);
  return jsonb_build_object(
    'competencia', to_char(v_mes, 'YYYY-MM'),
    'kpis', jsonb_build_object('total_clientes', v_total, 'apuracao_concluida', null, 'xml_aberto', null,
                               'sem_carteira', v_sem, 'alertas', null),
    'alertas', jsonb_build_object('prazo', null, 'respondeu', null, 'fila', null, 'ciclo', null, 'zerada', null, 'retificacao', null),
    'ciclo', jsonb_build_array(
      jsonb_build_object('chave', 'xml', 'nome', 'Solicitar XML', 'prazo', 'dia 31', 'concluido', null, 'andamento', null, 'atrasado', null),
      jsonb_build_object('chave', 'sieg', 'nome', 'Importar no SIEG', 'prazo', 'dia 31', 'concluido', null, 'andamento', null, 'atrasado', null),
      jsonb_build_object('chave', 'dominio', 'nome', 'Apurar no Domínio', 'prazo', 'dia 31', 'concluido', null, 'andamento', null, 'atrasado', null),
      jsonb_build_object('chave', 'das', 'nome', 'DAS + relatórios', 'prazo', 'dia 5 do mês seguinte', 'concluido', null, 'andamento', null, 'atrasado', null)),
    'xml_por_mes', (select jsonb_agg(jsonb_build_object('mes', to_char(m, 'YYYY-MM'), 'qtd', null, 'atual', m = v_mes) order by m)
                      from generate_series(v_mes - interval '3 months', v_mes, interval '1 month') m),
    'carga', coalesce((
      select jsonb_agg(jsonb_build_object('usuario_id', x.id, 'nome', x.nome, 'clientes', x.n) order by x.n desc, x.nome)
        from (select u.id, u.nome,
                     (select count(*) from fiscal_carteira k where k.usuario_id = u.id and k.ativo and k.empresa_id = any(v_you)) n
                from fiscal_usuario u where u.ativo) x), '[]'::jsonb));
end $$;
revoke all on function public.fiscal_central_gestor() from public, anon;
grant execute on function public.fiscal_central_gestor() to authenticated, service_role;
