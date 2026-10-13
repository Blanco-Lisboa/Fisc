alter table public.apu_tarefa
  add column if not exists sugestao_fase_id uuid references public.modelo_etapa_fases_status(id) on delete set null,
  add column if not exists sugestao_texto text,
  add column if not exists sugestao_em timestamptz,
  add column if not exists sugestao_mensagem_id uuid;

create or replace function public.apu_avancar_por_cliente(p_conversa uuid, p_evento text, p_conteudo text, p_mensagem uuid default null)
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
    update apu_tarefa set sugestao_fase_id = c.fase, sugestao_em = now(), sugestao_mensagem_id = p_mensagem,
           sugestao_texto = case when p_evento = 'arquivo' then 'Arquivo recebido: ' else 'Resposta do cliente: ' end || left(p_conteudo, 300)
                            || case when c.qt > 1 then ' (número ligado a mais de uma empresa com esta demanda; conferir se é desta)' else '' end
     where id = c.tarefa;
    insert into apu_tarefa_historico (tarefa_id, tipo_evento_id, origem, descricao)
    values (c.tarefa, (select id from tipos_evento_historico where codigo = 'outro'), 'automatico',
            'Sugestão para validar: ' || c.de || ' → ' || c.para || ' · '
            || case when p_evento = 'arquivo' then 'arquivo recebido: ' else 'resposta do cliente: ' end || left(p_conteudo, 120));
    v_n := v_n + 1;
  end loop;
  return v_n;
end $function$;
drop function if exists public.apu_avancar_por_cliente(uuid, text, text);
revoke all on function public.apu_avancar_por_cliente(uuid, text, text, uuid) from public, anon, authenticated;

create or replace function public.apu_mensagem_cliente_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if wa_importando() or new.direcao <> 'entrada' or coalesce(new.dados->>'origem', '') = 'backup' then return null; end if;
  begin
    if new.tipo = 'documento' then perform apu_avancar_por_cliente(new.conversa_id, 'arquivo', new.texto, new.id);
    elsif new.tipo = 'texto' then perform apu_avancar_por_cliente(new.conversa_id, 'mensagem', new.texto, new.id);
    end if;
  exception when others then
    raise warning 'apu_mensagem_cliente_tg: %', sqlerrm;
  end;
  return null;
end $function$;
revoke all on function public.apu_mensagem_cliente_tg() from public, anon, authenticated;

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
  update apu_tarefa set status_id = f.id, sugestao_fase_id = null, sugestao_texto = null, sugestao_em = null, sugestao_mensagem_id = null
   where id = t.id;
  insert into apu_tarefa_historico (tarefa_id, tipo_evento_id, origem, descricao, justificativa, usuario_id)
  values (t.id, coalesce(a.tipo_evento_id, (select id from tipos_evento_historico where codigo = 'mudanca_fase_manual')), 'manual',
          coalesce(case when a.id is not null then 'Ação: ' || a.nome || ' · ' end, '') || coalesce(v_de, '—') || ' → ' || f.nome,
          nullif(btrim(p_justificativa), ''), auth.uid());
  return jsonb_build_object('ok', true, 'fase', f.nome, 'mensagem', a.mensagem_texto);
end $function$;
revoke all on function public.apu_tarefa_mudar_fase(uuid, uuid, text, uuid) from public, anon;
grant execute on function public.apu_tarefa_mudar_fase(uuid, uuid, text, uuid) to authenticated;

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
    values (t.id, (select id from tipos_evento_historico where codigo = 'outro'), 'manual', 'Sugestão validada: ' || t.sugestao_texto, auth.uid());
    return r;
  end if;
  update apu_tarefa set sugestao_fase_id = null, sugestao_texto = null, sugestao_em = null, sugestao_mensagem_id = null where id = t.id;
  insert into apu_tarefa_historico (tarefa_id, tipo_evento_id, origem, descricao, justificativa, usuario_id)
  values (t.id, (select id from tipos_evento_historico where codigo = 'outro'), 'manual',
          'Sugestão recusada (' || v_para || '): ' || t.sugestao_texto, nullif(btrim(p_justificativa), ''), auth.uid());
  return jsonb_build_object('ok', true, 'recusada', true);
end $function$;
revoke all on function public.apu_tarefa_sugestao_decidir(uuid, boolean, text) from public, anon;
grant execute on function public.apu_tarefa_sugestao_decidir(uuid, boolean, text) to authenticated;
