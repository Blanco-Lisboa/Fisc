create or replace function public.apu_tarefa_sugestao_decidir(p_tarefa uuid, p_aceitar boolean, p_justificativa text default null)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare t apu_tarefa%rowtype; v_para text; r jsonb;
begin
  if auth.uid() is null or fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  select * into t from apu_tarefa where id = p_tarefa;
  if t.id is null or not apu_pode_ver_tarefa(p_tarefa) then raise exception 'tarefa nao encontrada'; end if;
  if t.sugestao_fase_id is null then raise exception 'Não há sugestão para validar.'; end if;
  select nome into v_para from modelo_etapa_fases_status where id = t.sugestao_fase_id;
  if p_aceitar then
    r := apu_tarefa_mudar_fase(t.id, t.sugestao_fase_id, coalesce(nullif(btrim(p_justificativa), ''), t.sugestao_texto), null);
    insert into apu_tarefa_historico (tarefa_id, tipo_evento_id, origem, descricao, usuario_id)
    values (t.id, (select id from tipos_evento_historico where codigo = 'outro'), 'manual', 'Sugestão do sistema confirmada: ' || t.sugestao_texto, auth.uid());
    return r;
  end if;
  if coalesce(btrim(p_justificativa), '') = '' then raise exception 'Descreva o que estava errado.'; end if;
  update apu_tarefa set sugestao_fase_id = null, sugestao_texto = null, sugestao_em = null, sugestao_mensagem_id = null where id = t.id;
  insert into apu_tarefa_historico (tarefa_id, tipo_evento_id, origem, descricao, justificativa, usuario_id)
  values (t.id, (select id from tipos_evento_historico where codigo = 'problema_informado'), 'manual',
          'Sugestão do sistema errada (' || v_para || '): ' || t.sugestao_texto, btrim(p_justificativa), auth.uid());
  return jsonb_build_object('ok', true, 'recusada', true);
end $function$;
revoke all on function public.apu_tarefa_sugestao_decidir(uuid, boolean, text) from public, anon;
grant execute on function public.apu_tarefa_sugestao_decidir(uuid, boolean, text) to authenticated;
