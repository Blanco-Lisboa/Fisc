alter table public.wa_chamada add column if not exists tocando_em timestamptz;

create or replace function public.wa_chamada_registrar_conversa(p_chamada uuid)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v wa_chamada%rowtype; v_txt text; v_dur text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  select * into v from wa_chamada where id = p_chamada;
  if v.id is null or v.conversa_id is null or v.estado not in ('encerrada', 'nao_atendida', 'rejeitada', 'falhou') then return; end if;
  if exists (select 1 from wa_mensagem where conversa_id = v.conversa_id and id_local = 'lig-' || v.id) then return; end if;
  v_dur := case when coalesce(v.duracao_s, 0) >= 60 then (v.duracao_s / 60) || ' min ' || (v.duracao_s % 60) || ' s'
                when coalesce(v.duracao_s, 0) > 0 then v.duracao_s || ' s' end;
  v_txt := case
    when v.direcao = 'empresa' and v.estado = 'encerrada' and v_dur is not null then 'Ligação de voz feita · ' || v_dur
    when v.direcao = 'empresa' and v.estado = 'rejeitada' then 'Ligação de voz recusada pelo cliente'
    when v.direcao = 'empresa' and v.estado = 'falhou' then 'Ligação de voz não completada'
    when v.direcao = 'empresa' then 'Ligação de voz sem resposta'
    when v.estado = 'encerrada' and v_dur is not null then 'Ligação de voz recebida · ' || v_dur
    when v.estado = 'rejeitada' then 'Ligação de voz recusada'
    else 'Ligação de voz perdida' end;
  insert into wa_mensagem (conversa_id, id_local, direcao, tipo, texto, status, autor_id, ocorrido_em, dados)
  values (v.conversa_id, 'lig-' || v.id, 'saida', 'sistema', v_txt, 'enviada', v.atendente_id,
          coalesce(v.fim_em, now()),
          jsonb_build_object('ligacao', jsonb_build_object('chamada_id', v.id, 'direcao', v.direcao, 'estado', v.estado, 'duracao_s', coalesce(v.duracao_s, 0))));
  update wa_conversa set ultima_em = greatest(coalesce(ultima_em, '-infinity'), coalesce(v.fim_em, now())),
                         ultima_previa = v_txt, atualizado_em = now()
   where id = v.conversa_id;
end $function$;
revoke all on function public.wa_chamada_registrar_conversa(uuid) from public, anon, authenticated;

create or replace function public.wa_meta_chamada_evento(v jsonb, p_numero uuid, c jsonb)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_ch wa_chamada%rowtype; v_tel text; v_bsuid text; v_cont uuid; v_conv uuid; v_ev text; v_st text; v_ts timestamptz;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  v_ev := lower(coalesce(c->>'event', ''));
  v_ts := to_timestamp(nullif(c->>'timestamp', '')::bigint);
  select * into v_ch from wa_chamada where wacid = c->>'id';

  if v_ev = 'connect' and v_ch.id is null and upper(coalesce(c->>'direction', '')) <> 'BUSINESS_INITIATED' then
    v_tel := nullif(regexp_replace(coalesce(c->>'from', ''), '\D', '', 'g'), '');
    v_bsuid := nullif(c->>'from_user_id', '');
    if v_tel is null and v_bsuid is null then raise exception 'ligacao sem numero e sem bsuid'; end if;
    v_cont := wa_meta_contato(v_tel, v_bsuid, null, null);
    v_conv := wa_meta_conversa(p_numero, v_cont, v_tel, v_bsuid, null);
    insert into wa_chamada (wacid, numero_id, contato_id, conversa_id, bsuid, direcao, estado, oferta_sdp, inicio_em)
    values (c->>'id', p_numero, v_cont, v_conv, v_bsuid, 'cliente', 'tocando', c->'session'->>'sdp', v_ts)
    returning * into v_ch;
  elsif v_ev = 'connect' and v_ch.id is not null then
    update wa_chamada set resposta_sdp = coalesce(c->'session'->>'sdp', resposta_sdp), atualizado_em = now() where id = v_ch.id;
  elsif v_ev = 'terminate' and v_ch.id is not null then
    v_st := upper(coalesce(c->>'status', ''));
    update wa_chamada set
      estado = case when v_st = 'COMPLETED' and (estado in ('em_curso', 'pre_aceita') or coalesce((c->>'duration')::int, 0) > 0) then 'encerrada'
                    when estado in ('tocando', 'chamando') then 'nao_atendida'
                    when estado = 'rejeitada' then 'rejeitada'
                    when v_st = 'FAILED' then 'falhou'
                    else 'encerrada' end,
      status_meta = v_st,
      inicio_em = coalesce(to_timestamp(nullif(c->>'start_time', '')::bigint), inicio_em),
      fim_em = coalesce(to_timestamp(nullif(c->>'end_time', '')::bigint), v_ts, now()),
      duracao_s = coalesce(nullif(c->>'duration', '')::int, duracao_s),
      oferta_sdp = null, resposta_sdp = null, atualizado_em = now()
     where id = v_ch.id
     returning * into v_ch;
    if v_ch.direcao = 'empresa' and v_ch.contato_id is not null then
      insert into wa_chamada_permissao (contato_id, situacao, nao_atendidas_seguidas)
      values (v_ch.contato_id, 'sem', case when v_ch.estado = 'nao_atendida' then 1 else 0 end)
      on conflict (contato_id) do update
        set nao_atendidas_seguidas = case when v_ch.estado = 'nao_atendida' then wa_chamada_permissao.nao_atendidas_seguidas + 1 else 0 end,
            situacao = case when v_ch.estado = 'nao_atendida' and wa_chamada_permissao.nao_atendidas_seguidas + 1 >= 4 then 'sem' else wa_chamada_permissao.situacao end,
            atualizado_em = now();
    end if;
    perform wa_chamada_registrar_conversa(v_ch.id);
  end if;

  insert into wa_chamada_evento (chamada_id, wacid, tipo, dados, ocorrido_em)
  values (v_ch.id, c->>'id', coalesce(nullif(v_ev, ''), 'desconhecido'), c - 'session', v_ts);
end $function$;
revoke all on function public.wa_meta_chamada_evento(jsonb, uuid, jsonb) from public, anon, authenticated;

create or replace function public.wa_meta_chamada_status(s jsonb)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_st text := upper(coalesce(s->>'status', '')); v_ts timestamptz := to_timestamp(nullif(s->>'timestamp', '')::bigint);
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  update wa_chamada set estado = case v_st when 'ACCEPTED' then 'em_curso' when 'REJECTED' then 'rejeitada' else estado end,
                        tocando_em = case when v_st = 'RINGING' then coalesce(tocando_em, v_ts, now()) else tocando_em end,
                        atualizado_em = now()
   where wacid = s->>'id' and estado in ('chamando', 'pre_aceita', 'tocando');
  insert into wa_chamada_evento (chamada_id, wacid, tipo, dados, ocorrido_em)
  values ((select id from wa_chamada where wacid = s->>'id'), s->>'id', 'status_' || lower(v_st), s, v_ts);
end $function$;
revoke all on function public.wa_meta_chamada_status(jsonb) from public, anon, authenticated;
