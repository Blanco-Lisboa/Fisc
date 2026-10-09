create or replace function public.fiscal_central_gestor()
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_mes date := date_trunc('month', current_date)::date;
begin
  if not fiscal_e_servidor() and not fiscal_pode('painel_gestor') then
    raise exception 'so gestor do Fiscal';
  end if;
  return jsonb_build_object(
    'competencia', to_char(v_mes, 'YYYY-MM'),
    'kpis', jsonb_build_object('total_clientes', null, 'apuracao_concluida', null, 'xml_aberto', null,
                               'sem_carteira', null, 'alertas', null),
    'alertas', jsonb_build_object('prazo', null, 'respondeu', null, 'fila', null, 'ciclo', null, 'zerada', null, 'retificacao', null),
    'ciclo', jsonb_build_array(
      jsonb_build_object('chave', 'xml', 'nome', 'Solicitar XML', 'prazo', 'dia 31', 'concluido', null, 'andamento', null, 'atrasado', null),
      jsonb_build_object('chave', 'sieg', 'nome', 'Importar no SIEG', 'prazo', 'dia 31', 'concluido', null, 'andamento', null, 'atrasado', null),
      jsonb_build_object('chave', 'dominio', 'nome', 'Apurar no Domínio', 'prazo', 'dia 31', 'concluido', null, 'andamento', null, 'atrasado', null),
      jsonb_build_object('chave', 'das', 'nome', 'DAS + relatórios', 'prazo', 'dia 5 do mês seguinte', 'concluido', null, 'andamento', null, 'atrasado', null)),
    'xml_por_mes', (select jsonb_agg(jsonb_build_object('mes', to_char(m, 'YYYY-MM'), 'qtd', null, 'atual', m = v_mes) order by m)
                      from generate_series(v_mes - interval '3 months', v_mes, interval '1 month') m),
    'carga', '[]'::jsonb);
end $function$;
