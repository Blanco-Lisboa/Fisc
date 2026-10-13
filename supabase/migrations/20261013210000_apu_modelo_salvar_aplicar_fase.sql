create or replace function public.apu_modelo_salvar(p jsonb)
 returns uuid language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_id uuid; v_tipo text; m modelos%rowtype; e jsonb; f jsonb; a jsonb; v_etapa uuid; v_fase uuid;
        v_etapas uuid[] := '{}'; v_fases uuid[]; v_ordem int := 0; v_fo int; v_fases_ids uuid[]; i int;
begin
  if auth.uid() is null or fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  v_tipo := coalesce(p->>'dono_tipo', 'pessoal');
  if v_tipo not in ('oficial', 'pessoal') then raise exception 'tipo invalido'; end if;
  if coalesce(btrim(p->>'nome'), '') = '' then raise exception 'Dê um nome ao modelo.'; end if;
  if jsonb_array_length(coalesce(p->'etapas', '[]'::jsonb)) = 0 then raise exception 'O modelo precisa de pelo menos 1 etapa.'; end if;
  v_id := nullif(p->>'id', '')::uuid;
  if v_id is not null then
    select * into m from modelos where id = v_id;
    if m.id is null then raise exception 'modelo nao encontrado'; end if;
    if m.dono_tipo = 'oficial' and not fiscal_pode('editar_modelo_oficial') then raise exception 'sem permissao para editar modelo oficial'; end if;
    if m.dono_tipo = 'pessoal' and m.criado_por <> auth.uid() then raise exception 'so quem criou edita'; end if;
    v_tipo := m.dono_tipo;
    update modelos set nome = btrim(p->>'nome'), descricao = nullif(btrim(p->>'descricao'), ''), updated_at = now() where id = v_id;
  else
    if v_tipo = 'oficial' and not fiscal_pode('criar_modelo_oficial') then raise exception 'sem permissao para criar modelo oficial'; end if;
    insert into modelos (nome, descricao, dono_tipo, criado_por) values (btrim(p->>'nome'), nullif(btrim(p->>'descricao'), ''), v_tipo, auth.uid())
    returning id into v_id;
  end if;

  for e in select * from jsonb_array_elements(p->'etapas') loop
    v_ordem := v_ordem + 1;
    if coalesce(btrim(e->>'titulo'), '') = '' then raise exception 'Toda etapa precisa de um título.'; end if;
    v_etapa := nullif(e->>'id', '')::uuid;
    if v_etapa is not null and exists (select 1 from modelo_etapas where id = v_etapa and modelo_id = v_id) then
      update modelo_etapas set ordem = v_ordem, titulo = btrim(e->>'titulo'), descricao = nullif(btrim(e->>'descricao'), ''),
             mensagem_envio = nullif(btrim(e->>'mensagem_envio'), '') where id = v_etapa;
    else
      insert into modelo_etapas (modelo_id, ordem, titulo, descricao, mensagem_envio)
      values (v_id, v_ordem, btrim(e->>'titulo'), nullif(btrim(e->>'descricao'), ''), nullif(btrim(e->>'mensagem_envio'), ''))
      returning id into v_etapa;
    end if;
    v_etapas := v_etapas || v_etapa;

    insert into modelo_etapa_config (etapa_id, recorrencia_tipo_id)
    values (v_etapa, (select id from tipos_recorrencia where codigo = coalesce(e->>'recorrencia', 'mensal')))
    on conflict (etapa_id) do update set recorrencia_tipo_id = excluded.recorrencia_tipo_id;
    delete from modelo_etapa_recorrencia_dias_mes where etapa_id = v_etapa;
    insert into modelo_etapa_recorrencia_dias_mes (etapa_id, dia)
    select v_etapa, d::smallint from jsonb_array_elements_text(coalesce(e->'dias_mes', '[]'::jsonb)) d
     where d ~ '^\d+$' and d::int between 1 and 31 on conflict do nothing;

    v_fases := '{}'; v_fo := 0;
    if jsonb_array_length(coalesce(e->'fases', '[]'::jsonb)) = 0 then raise exception 'A etapa "%" precisa de pelo menos 1 fase.', e->>'titulo'; end if;
    for f in select * from jsonb_array_elements(e->'fases') loop
      v_fo := v_fo + 1;
      if coalesce(btrim(f->>'nome'), '') = '' then raise exception 'Toda fase precisa de um nome.'; end if;
      v_fase := nullif(f->>'id', '')::uuid;
      if v_fase is not null and exists (select 1 from modelo_etapa_fases_status where id = v_fase and etapa_id = v_etapa) then
        update modelo_etapa_fases_status set nome = btrim(f->>'nome'), ordem = v_fo,
               avanco_tipo_id = (select id from tipos_avanco_fase where codigo = coalesce(f->>'avanco', 'manual')),
               exigir_justificativa = coalesce((f->>'exigir_justificativa')::boolean, false)
         where id = v_fase;
      else
        insert into modelo_etapa_fases_status (etapa_id, nome, ordem, avanco_tipo_id, exigir_justificativa)
        values (v_etapa, btrim(f->>'nome'), v_fo, (select id from tipos_avanco_fase where codigo = coalesce(f->>'avanco', 'manual')),
                coalesce((f->>'exigir_justificativa')::boolean, false))
        returning id into v_fase;
      end if;
      v_fases := v_fases || v_fase;
    end loop;
    delete from modelo_etapa_fases_status where etapa_id = v_etapa and not (id = any(v_fases));

    delete from modelo_etapa_acoes_rapidas where fase_id = any(v_fases);
    i := 0;
    for f in select * from jsonb_array_elements(e->'fases') loop
      i := i + 1;
      for a in select * from jsonb_array_elements(coalesce(f->'acoes', '[]'::jsonb)) loop
        if coalesce(btrim(a->>'nome'), '') = '' then continue; end if;
        insert into modelo_etapa_acoes_rapidas (fase_id, nome, mensagem_texto, mudar_para_fase_id, tipo_evento_id, ordem)
        values (v_fases[i], btrim(a->>'nome'), nullif(btrim(a->>'mensagem_texto'), ''),
                case when (a->>'mudar_para') ~ '^\d+$' and (a->>'mudar_para')::int between 1 and array_length(v_fases, 1) then v_fases[(a->>'mudar_para')::int] end,
                (select id from tipos_evento_historico where codigo = coalesce(a->>'evento', 'mudanca_fase_manual')),
                (select coalesce(max(ordem), 0) + 1 from modelo_etapa_acoes_rapidas where fase_id = v_fases[i]));
      end loop;
    end loop;

    delete from modelo_etapa_checklist_itens where etapa_id = v_etapa;
    insert into modelo_etapa_checklist_itens (etapa_id, titulo, ordem)
    select v_etapa, btrim(t), row_number() over () from jsonb_array_elements_text(coalesce(e->'checklist', '[]'::jsonb)) t where btrim(t) <> '';
    delete from modelo_etapa_opcoes_escolha where etapa_id = v_etapa;
    insert into modelo_etapa_opcoes_escolha (etapa_id, texto_opcao, ordem)
    select v_etapa, btrim(t), row_number() over () from jsonb_array_elements_text(coalesce(e->'opcoes', '[]'::jsonb)) t where btrim(t) <> '';
  end loop;
  if exists (select 1 from apu_tarefa t join modelo_etapas me on me.id = t.etapa_id where me.modelo_id = v_id and not (me.id = any(v_etapas))) then
    raise exception 'Há etapa removida que já foi aplicada em cliente; remova as demandas antes.';
  end if;
  delete from modelo_etapas where modelo_id = v_id and not (id = any(v_etapas));
  return v_id;
end $function$;
revoke all on function public.apu_modelo_salvar(jsonb) from public, anon;
grant execute on function public.apu_modelo_salvar(jsonb) to authenticated;

create or replace function public.apu_modelo_arvore(p_modelo uuid)
 returns jsonb language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select case when apu_pode_ver_modelo(p_modelo) then (
    select jsonb_build_object('id', m.id, 'nome', m.nome, 'descricao', m.descricao, 'dono_tipo', m.dono_tipo, 'status', m.status,
      'meu', m.criado_por = auth.uid(),
      'etapas', coalesce((select jsonb_agg(jsonb_build_object(
          'id', e.id, 'titulo', e.titulo, 'descricao', e.descricao, 'mensagem_envio', e.mensagem_envio,
          'recorrencia', (select r.codigo from modelo_etapa_config c join tipos_recorrencia r on r.id = c.recorrencia_tipo_id where c.etapa_id = e.id),
          'dias_mes', coalesce((select jsonb_agg(d.dia order by d.dia) from modelo_etapa_recorrencia_dias_mes d where d.etapa_id = e.id), '[]'::jsonb),
          'checklist', coalesce((select jsonb_agg(ci.titulo order by ci.ordem) from modelo_etapa_checklist_itens ci where ci.etapa_id = e.id), '[]'::jsonb),
          'opcoes', coalesce((select jsonb_agg(o.texto_opcao order by o.ordem) from modelo_etapa_opcoes_escolha o where o.etapa_id = e.id), '[]'::jsonb),
          'fases', coalesce((select jsonb_agg(jsonb_build_object('id', f.id, 'nome', f.nome, 'ordem', f.ordem,
              'avanco', (select t.codigo from tipos_avanco_fase t where t.id = f.avanco_tipo_id), 'exigir_justificativa', f.exigir_justificativa,
              'acoes', coalesce((select jsonb_agg(jsonb_build_object('id', a.id, 'nome', a.nome, 'mensagem_texto', a.mensagem_texto,
                  'mudar_para', (select f2.ordem from modelo_etapa_fases_status f2 where f2.id = a.mudar_para_fase_id),
                  'evento', (select te.codigo from tipos_evento_historico te where te.id = a.tipo_evento_id)) order by a.ordem)
                from modelo_etapa_acoes_rapidas a where a.fase_id = f.id), '[]'::jsonb)) order by f.ordem)
            from modelo_etapa_fases_status f where f.etapa_id = e.id), '[]'::jsonb)) order by e.ordem)
        from modelo_etapas e where e.modelo_id = m.id), '[]'::jsonb))
    from modelos m where m.id = p_modelo) end;
$function$;
revoke all on function public.apu_modelo_arvore(uuid) from public, anon;
grant execute on function public.apu_modelo_arvore(uuid) to authenticated;

create or replace function public.apu_modelo_aplicar(p_modelo uuid, p_empresas uuid[], p_ciclo date)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare m modelos%rowtype; v_ciclo date; v_emp uuid; e record; v_tid uuid; v_resp uuid; v_criadas int := 0; v_existiam int := 0;
begin
  if auth.uid() is null or fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  if p_ciclo is null then raise exception 'Escolha o mês de referência.'; end if;
  if coalesce(array_length(p_empresas, 1), 0) = 0 then raise exception 'Escolha pelo menos um cliente.'; end if;
  if not fiscal_pode('aplicar_modelo_cliente') then raise exception 'sem permissao para aplicar demanda'; end if;
  if array_length(p_empresas, 1) > 1 and not fiscal_pode('aplicar_modelo_lote') then raise exception 'sem permissao para aplicar em lote'; end if;
  select * into m from modelos where id = p_modelo;
  if m.id is null or not apu_pode_ver_modelo(p_modelo) then raise exception 'modelo nao encontrado'; end if;
  if m.status <> 'ativo' then raise exception 'modelo inativo'; end if;
  v_ciclo := date_trunc('month', p_ciclo)::date;
  foreach v_emp in array p_empresas loop
    if not apu_pode_ver_empresa(v_emp) then raise exception 'cliente fora da sua carteira'; end if;
    select cc.usuario_id into v_resp from zz_rota_provisoria_carteira cc join fiscal_usuario u on u.id = cc.usuario_id and u.ativo
     where cc.empresa_id = v_emp order by cc.usuario_id limit 1;
    for e in select et.id, (select f.id from modelo_etapa_fases_status f where f.etapa_id = et.id order by f.ordem limit 1) fase
               from modelo_etapas et where et.modelo_id = m.id order by et.ordem loop
      insert into apu_tarefa (empresa_id, etapa_id, modelo_id, origem, ciclo_referencia, status_id, responsavel_id)
      values (v_emp, e.id, m.id, m.dono_tipo, v_ciclo, e.fase, coalesce(v_resp, auth.uid()))
      on conflict (empresa_id, etapa_id, ciclo_referencia) do nothing
      returning id into v_tid;
      if v_tid is null then v_existiam := v_existiam + 1;
      else
        v_criadas := v_criadas + 1;
        insert into apu_tarefa_historico (tarefa_id, tipo_evento_id, origem, descricao, usuario_id)
        values (v_tid, (select id from tipos_evento_historico where codigo = 'outro'), 'manual', 'Demanda aplicada', auth.uid());
      end if;
      v_tid := null;
    end loop;
  end loop;
  return jsonb_build_object('criadas', v_criadas, 'ja_existiam', v_existiam);
end $function$;
revoke all on function public.apu_modelo_aplicar(uuid, uuid[], date) from public, anon;
grant execute on function public.apu_modelo_aplicar(uuid, uuid[], date) to authenticated;

create or replace function public.apu_tarefa_mudar_fase(p_tarefa uuid, p_fase uuid, p_justificativa text default null, p_acao uuid default null)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare t apu_tarefa%rowtype; f modelo_etapa_fases_status%rowtype; v_de text; a modelo_etapa_acoes_rapidas%rowtype;
begin
  if auth.uid() is null or fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  select * into t from apu_tarefa where id = p_tarefa;
  if t.id is null or not apu_pode_ver_tarefa(p_tarefa) then raise exception 'tarefa nao encontrada'; end if;
  if p_acao is not null then
    select * into a from modelo_etapa_acoes_rapidas where id = p_acao;
    if a.id is null or a.fase_id is distinct from t.status_id then raise exception 'acao nao vale para a fase atual'; end if;
    p_fase := coalesce(a.mudar_para_fase_id, t.status_id);
  end if;
  select * into f from modelo_etapa_fases_status where id = p_fase and etapa_id = t.etapa_id;
  if f.id is null then raise exception 'fase nao pertence a esta etapa'; end if;
  if p_acao is null and f.exigir_justificativa and coalesce(btrim(p_justificativa), '') = '' then
    raise exception 'Esta fase pede justificativa.';
  end if;
  select nome into v_de from modelo_etapa_fases_status where id = t.status_id;
  update apu_tarefa set status_id = f.id where id = t.id;
  insert into apu_tarefa_historico (tarefa_id, tipo_evento_id, origem, descricao, justificativa, usuario_id)
  values (t.id, coalesce(a.tipo_evento_id, (select id from tipos_evento_historico where codigo = 'mudanca_fase_manual')), 'manual',
          coalesce(case when a.id is not null then 'Ação: ' || a.nome || ' · ' end, '') || coalesce(v_de, '—') || ' → ' || f.nome,
          nullif(btrim(p_justificativa), ''), auth.uid());
  return jsonb_build_object('ok', true, 'fase', f.nome, 'mensagem', a.mensagem_texto);
end $function$;
revoke all on function public.apu_tarefa_mudar_fase(uuid, uuid, text, uuid) from public, anon;
grant execute on function public.apu_tarefa_mudar_fase(uuid, uuid, text, uuid) to authenticated;
