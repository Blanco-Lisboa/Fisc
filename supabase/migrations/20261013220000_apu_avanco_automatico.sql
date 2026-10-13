alter table public.modelo_etapa_fases_status add column if not exists avanco_resposta text;

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
      if not exists (select 1 from tipos_avanco_fase where codigo = coalesce(f->>'avanco', 'manual')) then raise exception 'jeito de avançar inválido'; end if;
      if f->>'avanco' = 'automatico_mensagem_recebida' and coalesce(btrim(f->>'avanco_resposta'), '') = '' then raise exception 'A fase "%" avança pela resposta do cliente: escreva qual resposta.', f->>'nome'; end if;
      v_fase := nullif(f->>'id', '')::uuid;
      if v_fase is not null and exists (select 1 from modelo_etapa_fases_status where id = v_fase and etapa_id = v_etapa) then
        update modelo_etapa_fases_status set nome = btrim(f->>'nome'), ordem = v_fo,
               avanco_tipo_id = (select id from tipos_avanco_fase where codigo = coalesce(f->>'avanco', 'manual')),
               exigir_justificativa = coalesce((f->>'exigir_justificativa')::boolean, false),
               avanco_padrao_arquivo = nullif(btrim(f->>'avanco_padrao_arquivo'), ''), avanco_resposta = nullif(btrim(f->>'avanco_resposta'), '')
         where id = v_fase;
      else
        insert into modelo_etapa_fases_status (etapa_id, nome, ordem, avanco_tipo_id, exigir_justificativa, avanco_padrao_arquivo, avanco_resposta)
        values (v_etapa, btrim(f->>'nome'), v_fo, (select id from tipos_avanco_fase where codigo = coalesce(f->>'avanco', 'manual')),
                coalesce((f->>'exigir_justificativa')::boolean, false), nullif(btrim(f->>'avanco_padrao_arquivo'), ''), nullif(btrim(f->>'avanco_resposta'), ''))
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
              'avanco_padrao_arquivo', f.avanco_padrao_arquivo, 'avanco_resposta', f.avanco_resposta,
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


create or replace function public.apu_avancar_por_cliente(p_conversa uuid, p_evento text, p_conteudo text)
 returns integer language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_chave text; v_codigo text; c record; v_n int := 0;
begin
  if coalesce(btrim(p_conteudo), '') = '' then return 0; end if;
  select wa_telefone_chave(contato_telefone) into v_chave from wa_conversa where id = p_conversa and not coalesce(e_grupo, false);
  if v_chave is null then return 0; end if;
  v_codigo := case p_evento when 'arquivo' then 'automatico_arquivo_detectado' when 'mensagem' then 'automatico_mensagem_recebida' end;
  if v_codigo is null then return 0; end if;
  for c in
    with emp as (
      select v.empresa_id from zz_rota_provisoria_vinculo v where v.numero_chave = v_chave and v.origem not like 'oculto%'
      union select r.empresa_id from wa_rota_numero r where r.telefone_chave = v_chave and r.empresa_id is not null
      union select (x->>'empresa_id')::uuid from wa_rota_numero r, jsonb_array_elements(r.empresas) x where r.telefone_chave = v_chave),
    cand as (
      select t.id tarefa, t.etapa_id, atual.nome de, alvo.id fase, alvo.nome para,
             row_number() over (partition by t.id order by alvo.ordem) rn
        from apu_tarefa t
        join emp on emp.empresa_id = t.empresa_id
        join modelo_etapa_fases_status atual on atual.id = t.status_id
        join tipos_avanco_fase ta on ta.id = atual.avanco_tipo_id and ta.codigo = 'manual'
        join modelo_etapa_fases_status alvo on alvo.etapa_id = t.etapa_id and alvo.ordem > atual.ordem
        join tipos_avanco_fase tb on tb.id = alvo.avanco_tipo_id and tb.codigo = v_codigo
       where case when p_evento = 'arquivo' then
                    alvo.avanco_padrao_arquivo is null
                    or exists (select 1 from regexp_split_to_table(alvo.avanco_padrao_arquivo, '[,; ]+') x
                                where x <> '' and lower(p_conteudo) like '%.' || lower(ltrim(x, '.')))
                  else lower(btrim(p_conteudo)) = lower(btrim(alvo.avanco_resposta)) end)
    select cand.*, count(*) over (partition by cand.etapa_id) qt from cand where rn = 1
  loop
    if c.qt > 1 then
      insert into apu_tarefa_historico (tarefa_id, tipo_evento_id, origem, descricao)
      values (c.tarefa, (select id from tipos_evento_historico where codigo = 'outro'), 'automatico',
              'Cliente ' || case when p_evento = 'arquivo' then 'enviou arquivo' else 'respondeu' end || ' (' || left(p_conteudo, 120)
              || '), mas o número está ligado a mais de uma demanda igual; conferir e mudar à mão');
      continue;
    end if;
    update apu_tarefa set status_id = c.fase where id = c.tarefa;
    insert into apu_tarefa_historico (tarefa_id, tipo_evento_id, origem, descricao, justificativa)
    values (c.tarefa, (select id from tipos_evento_historico where codigo = 'mudanca_fase_automatica'), 'automatico',
            c.de || ' → ' || c.para || ' · ' || case when p_evento = 'arquivo' then 'arquivo recebido: ' else 'resposta do cliente: ' end || left(p_conteudo, 120),
            case when p_evento = 'mensagem' then 'Resposta do cliente: ' || left(p_conteudo, 300) end);
    v_n := v_n + 1;
  end loop;
  return v_n;
end $function$;
revoke all on function public.apu_avancar_por_cliente(uuid, text, text) from public, anon, authenticated;

create or replace function public.apu_mensagem_cliente_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if wa_importando() or new.direcao <> 'entrada' or coalesce(new.dados->>'origem', '') = 'backup' then return null; end if;
  begin
    if new.tipo = 'documento' then perform apu_avancar_por_cliente(new.conversa_id, 'arquivo', new.texto);
    elsif new.tipo = 'texto' then perform apu_avancar_por_cliente(new.conversa_id, 'mensagem', new.texto);
    end if;
  exception when others then
    raise warning 'apu_mensagem_cliente_tg: %', sqlerrm;
  end;
  return null;
end $function$;
revoke all on function public.apu_mensagem_cliente_tg() from public, anon, authenticated;

drop trigger if exists apu_mensagem_cliente on public.wa_mensagem;
create trigger apu_mensagem_cliente after insert on public.wa_mensagem
  for each row when (new.direcao = 'entrada' and new.tipo in ('documento', 'texto'))
  execute function public.apu_mensagem_cliente_tg();
