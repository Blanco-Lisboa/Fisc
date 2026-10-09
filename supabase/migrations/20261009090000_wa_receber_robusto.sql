create or replace function public.wa_telefone_chave(p_tel text)
 returns text language sql immutable set search_path to 'pg_catalog'
as $$
  select case
    when v ~ '^55[1-9][0-9][6-9][0-9]{7}$' then substr(v, 1, 4) || '9' || substr(v, 5)
    else v end
  from (select nullif(regexp_replace(coalesce(p_tel, ''), '\D', '', 'g'), '') v) x;
$$;

alter table public.wa_contato add column if not exists telefone_chave text
  generated always as (public.wa_telefone_chave(telefone)) stored;
create unique index if not exists wa_contato_telefone_chave_uq on public.wa_contato (telefone_chave) where telefone_chave is not null;

alter table public.wa_midia add column if not exists baixando_desde timestamptz;

create table if not exists public.wa_status_pendente (
  wamid text primary key,
  status jsonb not null,
  recebido_em timestamptz not null default now()
);
alter table public.wa_status_pendente enable row level security;
revoke all on public.wa_status_pendente from anon, authenticated;

create table if not exists public.wa_webhook_falha (
  id bigint generated always as identity primary key,
  evento_id bigint references public.wa_webhook_evento(id) on delete set null,
  campo text,
  referencia text,
  erro text not null,
  trecho jsonb,
  em timestamptz not null default now()
);
create index if not exists wa_webhook_falha_evento_ix on public.wa_webhook_falha (evento_id);
alter table public.wa_webhook_falha enable row level security;
revoke all on public.wa_webhook_falha from anon, authenticated;

create or replace function public.wa_meta_midia_a_baixar(p_limite integer default 10)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare r jsonb;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  with alvo as (
    select d.id from wa_midia d
     where d.id_externo is not null
       and d.tentativas < 5
       and (d.expira_em is null or d.expira_em > now())
       and ((d.estado in ('pendente', 'falhou') and (d.proxima_em is null or d.proxima_em <= now()))
            or (d.estado = 'baixando' and d.baixando_desde < now() - interval '10 minutes'))
     order by d.criado_em
     limit p_limite
     for update skip locked
  ), marcadas as (
    update wa_midia d set estado = 'baixando', baixando_desde = now(), tentativas = d.tentativas + 1
      from alvo where d.id = alvo.id
    returning d.id, d.id_externo, d.tipo, d.mensagem_id
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'midia_id', k.id, 'media_id', k.id_externo, 'tipo', k.tipo,
           'mensagem_id', k.mensagem_id, 'conversa_id', m.conversa_id)), '[]'::jsonb)
    into r
    from marcadas k join wa_mensagem m on m.id = k.mensagem_id;
  return r;
end $function$;

create or replace function public.wa_meta_aplicar_status(s jsonb)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_ord int; v_ts timestamptz;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  v_ord := case s->>'status' when 'sent' then 1 when 'delivered' then 2 when 'read' then 3 when 'failed' then 9 else null end;
  if v_ord is null then return true; end if;
  v_ts := to_timestamp((s->>'timestamp')::bigint);
  update wa_mensagem w set
    status = case
      when v_ord = 9 then case when w.status in ('entregue', 'lida') then w.status else 'falhou' end
      when (case w.status when 'enviada' then 1 when 'entregue' then 2 when 'lida' then 3 else 0 end) < v_ord
        then (array['enviada', 'entregue', 'lida'])[v_ord]
      else w.status end,
    enviado_em = case when v_ord between 1 and 3 then coalesce(w.enviado_em, v_ts) else w.enviado_em end,
    entregue_em = case when v_ord between 2 and 3 then coalesce(w.entregue_em, v_ts) else w.entregue_em end,
    lido_em = case when v_ord = 3 then coalesce(w.lido_em, v_ts) else w.lido_em end,
    erro = case when v_ord = 9 then left(concat_ws(' ', s->'errors'->0->>'code', s->'errors'->0->>'title',
                                                  s->'errors'->0->'error_data'->>'details'), 500)
                else w.erro end,
    preco_categoria = coalesce(s->'pricing'->>'category', w.preco_categoria),
    preco_cobrada = coalesce((s->'pricing'->>'billable')::boolean, w.preco_cobrada)
  where w.id_whatsapp = s->>'id' and w.direcao = 'saida';
  return found;
end $function$;

create or replace function public.wa_meta_contato(p_tel text, p_bsuid text, p_nome text, p_usuario text)
 returns uuid language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_por_bsuid uuid; v_por_tel uuid; v_id uuid; v_chave text := wa_telefone_chave(p_tel);
begin
  if p_bsuid is not null then select id into v_por_bsuid from wa_contato where bsuid = p_bsuid; end if;
  if v_chave is not null then select id into v_por_tel from wa_contato where telefone_chave = v_chave; end if;
  v_id := coalesce(v_por_tel, v_por_bsuid);
  if v_id is null then
    begin
      insert into wa_contato (telefone, bsuid, nome_whatsapp, usuario_whatsapp)
      values (p_tel, p_bsuid, p_nome, p_usuario)
      returning id into v_id;
    exception when unique_violation then
      select id into v_id from wa_contato
       where (v_chave is not null and telefone_chave = v_chave) or (p_bsuid is not null and bsuid = p_bsuid)
       limit 1;
      if v_id is null then raise; end if;
    end;
  else
    update wa_contato
       set telefone = coalesce(telefone, p_tel),
           bsuid = case when bsuid is null and p_bsuid is not null
                         and not exists (select 1 from wa_contato o where o.bsuid = p_bsuid) then p_bsuid else bsuid end,
           nome_whatsapp = coalesce(p_nome, nome_whatsapp),
           usuario_whatsapp = coalesce(p_usuario, usuario_whatsapp),
           atualizado_em = now()
     where id = v_id;
  end if;
  return v_id;
end $function$;

create or replace function public.wa_meta_conversa(p_numero uuid, p_contato uuid, p_tel text, p_bsuid text, p_nome text)
 returns uuid language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_conv uuid; v_chave text := wa_telefone_chave(p_tel);
begin
  select id into v_conv from wa_conversa
   where numero_id = p_numero and estado <> 'arquivada'
     and (contato_id = p_contato
       or (v_chave is not null and wa_telefone_chave(contato_telefone) = v_chave)
       or (p_bsuid is not null and contato_bsuid = p_bsuid))
   order by (contato_id = p_contato) desc nulls last
   limit 1;
  if v_conv is null then
    begin
      insert into wa_conversa (numero_id, contato_id, contato_telefone, contato_bsuid, contato_nome, estado, primeiro_em)
      values (p_numero, p_contato, p_tel, p_bsuid, p_nome, 'nova', now())
      returning id into v_conv;
    exception when unique_violation then
      select id into v_conv from wa_conversa
       where numero_id = p_numero and estado <> 'arquivada'
         and (contato_id = p_contato or contato_telefone = p_tel or contato_bsuid = p_bsuid)
       limit 1;
      if v_conv is null then raise; end if;
    end;
  else
    update wa_conversa set contato_id = coalesce(contato_id, p_contato),
                           contato_nome = coalesce(contato_nome, p_nome),
                           contato_telefone = coalesce(contato_telefone, p_tel),
                           contato_bsuid = coalesce(contato_bsuid, p_bsuid)
     where id = v_conv
       and (contato_id is null or contato_nome is null or contato_telefone is null or contato_bsuid is null);
  end if;
  return v_conv;
end $function$;

create or replace function public.wa_meta_resultado_envio(p_mensagem_id uuid, p_wamid text, p_erro_codigo integer default null, p_erro text default null)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_conv uuid; v_prev text; n int; p record;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if coalesce(p_wamid, '') <> '' then
    update wa_mensagem set id_whatsapp = p_wamid, id_provedor = p_wamid,
                           status = case when status = 'enviando' then 'aguardando' else status end,
                           tentativas = tentativas + 1, erro = null
     where id = p_mensagem_id
    returning conversa_id, left(coalesce(legenda, texto, '[' || tipo || ']'), 200) into v_conv, v_prev;
    get diagnostics n = row_count;
    update wa_conversa set ultima_em = now(), ultima_previa = v_prev, atualizado_em = now() where id = v_conv;
    for p in delete from wa_status_pendente where wamid = p_wamid returning status loop
      perform wa_meta_aplicar_status(p.status);
    end loop;
  else
    update wa_mensagem set status = 'falhou', tentativas = tentativas + 1,
                           erro = left(case p_erro_codigo
                                         when 131047 then '131047 fora da janela de 24h: so modelo aprovado'
                                         else concat_ws(' ', p_erro_codigo::text, p_erro) end, 500)
     where id = p_mensagem_id;
    get diagnostics n = row_count;
  end if;
  return n = 1;
end $function$;

create or replace function public.wa_meta_receber(p_corpo text)
 returns jsonb language plpgsql security definer set search_path to 'public', 'extensions', 'pg_temp'
as $function$
declare
  j jsonb; v_hash text; v_ev bigint; v_ja boolean;
  e jsonb; ch jsonb; v jsonb; m jsonb; s jsonb; d jsonb; ct jsonb; g jsonb;
  v_num uuid; v_tel text; v_bsuid text; v_nome text; v_usuario text; v_cont uuid; v_conv uuid; v_msg uuid;
  v_tipo text; v_texto text; v_leg text; v_ts timestamptz; v_gid text; v_autor text; v_novo text;
  v_novas int := 0; v_status int := 0; v_ign int := 0; v_outros int := 0; v_falhas int := 0; v_tinha_midia boolean := false;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor grava'; end if;
  j := p_corpo::jsonb;
  v_hash := 'sha256:' || encode(extensions.digest(convert_to(p_corpo, 'UTF8'), 'sha256'), 'hex');

  insert into wa_webhook_evento (tipo, id_evento, corpo, bytes_corpo)
  values ('meta', v_hash, p_corpo, octet_length(p_corpo))
  on conflict (id_evento) where id_evento is not null do nothing
  returning id into v_ev;
  if v_ev is null then
    select id, coalesce(processado_ok, false) into v_ev, v_ja from wa_webhook_evento where id_evento = v_hash;
    if v_ja then return jsonb_build_object('ok', true, 'repetido', true); end if;
  end if;

  if j->>'object' is distinct from 'whatsapp_business_account' then
    insert into wa_webhook_falha (evento_id, campo, erro) values (v_ev, 'object', 'objeto inesperado: ' || coalesce(j->>'object', 'nulo'));
    update wa_webhook_evento set processado_ok = true, processado_em = now(), erro = 'objeto inesperado', corpo = null where id = v_ev;
    return jsonb_build_object('ok', true, 'ignoradas', 1);
  end if;

  for e in select * from jsonb_array_elements(coalesce(j->'entry', '[]')) loop
    for ch in select * from jsonb_array_elements(coalesce(e->'changes', '[]')) loop
      v := ch->'value';
      begin

        if ch->>'field' in ('message_template_status_update', 'template_category_update', 'message_template_quality_update') then
          insert into wa_modelo (meta_id, nome, idioma, categoria, estado, motivo, detalhe)
          values (v->>'message_template_id', coalesce(v->>'message_template_name', '?'),
                  coalesce(v->>'message_template_language', '?'),
                  coalesce(v->>'message_template_category', v->>'new_category'),
                  case when ch->>'field' = 'message_template_status_update' then coalesce(v->>'event', 'PENDING') else 'PENDING' end,
                  nullif(v->>'reason', 'NONE'), v)
          on conflict (meta_id) do update
            set estado = case when ch->>'field' = 'message_template_status_update'
                              then coalesce(excluded.estado, wa_modelo.estado) else wa_modelo.estado end,
                categoria = coalesce(v->>'new_category', v->>'message_template_category', wa_modelo.categoria),
                motivo = case when ch->>'field' = 'message_template_status_update' then excluded.motivo else wa_modelo.motivo end,
                nome = case when excluded.nome = '?' then wa_modelo.nome else excluded.nome end,
                idioma = case when excluded.idioma = '?' then wa_modelo.idioma else excluded.idioma end,
                detalhe = case when ch->>'field' = 'message_template_quality_update'
                               then coalesce(wa_modelo.detalhe, '{}'::jsonb) || jsonb_build_object('qualidade', v) else v end,
                atualizado_em = now();
          v_outros := v_outros + 1;
          continue;
        end if;

        if ch->>'field' in ('phone_number_quality_update', 'account_update') then
          select id into v_num from wa_numero
           where provedor = 'meta_cloud' and ativo
             and (telefone = regexp_replace(coalesce(v->>'display_phone_number', ''), '\D', '', 'g')
                  or identificador = v->>'phone_number_id')
           limit 1;
          if v_num is not null then
            insert into wa_saude (numero_id, limite_diario, ultimo_evento, motivo)
            values (v_num, coalesce(v->>'max_daily_conversations_per_business', v->>'current_limit'),
                    ch->>'field' || ':' || coalesce(v->>'event', ''), left(v::text, 500))
            on conflict (numero_id) do update
              set limite_diario = coalesce(excluded.limite_diario, wa_saude.limite_diario),
                  ultimo_evento = excluded.ultimo_evento, motivo = excluded.motivo,
                  visto_em = now(), atualizado_em = now();
          end if;
          v_outros := v_outros + 1;
          continue;
        end if;

        if ch->>'field' in ('group_lifecycle_update', 'group_settings_update', 'group_participants_update', 'group_status_update') then
          for g in select * from jsonb_array_elements(case when jsonb_typeof(v->'groups') = 'array' then v->'groups' else jsonb_build_array(v) end) loop
            v_gid := coalesce(g->>'group_id', g->>'id');
            continue when v_gid is null;
            if ch->>'field' = 'group_lifecycle_update' and coalesce(g->>'type', g->>'event', '') ilike '%delete%' then
              update wa_conversa set arquivada = true, estado = 'resolvida' where grupo_meta_id = v_gid;
            elsif ch->>'field' = 'group_lifecycle_update' then
              perform wa_grupo_registrar(v->'metadata'->>'phone_number_id', v_gid, coalesce(g->>'subject', 'Grupo'),
                                         g->>'description', g->>'invite_link', null);
            elsif ch->>'field' = 'group_settings_update' then
              update wa_conversa set contato_nome = coalesce(g->'group_subject'->>'text', g->>'subject', contato_nome),
                                     grupo_descricao = coalesce(g->'group_description'->>'text', g->>'description', grupo_descricao)
               where grupo_meta_id = v_gid;
            end if;
          end loop;
          v_outros := v_outros + 1;
          continue;
        end if;

        if ch->>'field' is distinct from 'messages' then
          insert into wa_webhook_falha (evento_id, campo, erro, trecho) values (v_ev, ch->>'field', 'campo sem tratamento', v);
          v_ign := v_ign + 1;
          continue;
        end if;

        v_num := null;
        select id into v_num from wa_numero
         where provedor = 'meta_cloud' and identificador = v->'metadata'->>'phone_number_id' and ativo;
        if v_num is null then
          insert into wa_webhook_falha (evento_id, campo, referencia, erro, trecho)
          values (v_ev, 'messages', v->'metadata'->>'phone_number_id', 'numero da Meta nao cadastrado no Fiscal', v);
          v_falhas := v_falhas + 1;
          continue;
        end if;
        update wa_numero set visto_em = now(), conectado = true where id = v_num;

        for m in select * from jsonb_array_elements(coalesce(v->'messages', '[]')) loop
          begin
            if exists (select 1 from wa_mensagem where id_whatsapp = m->>'id') then continue; end if;

            v_tel := nullif(regexp_replace(coalesce(m->>'from', ''), '\D', '', 'g'), '');
            if v_tel is not null and (length(v_tel) < 10 or length(v_tel) > 15) then v_tel := null; end if;
            v_bsuid := nullif(m->>'from_user_id', '');
            ct := null;
            select c into ct from jsonb_array_elements(coalesce(v->'contacts', '[]')) c
             where (m->>'from' is not null and c->>'wa_id' = m->>'from')
                or (v_bsuid is not null and c->>'user_id' = v_bsuid)
             limit 1;
            v_bsuid := coalesce(v_bsuid, nullif(ct->>'user_id', ''));
            v_nome := nullif(ct->'profile'->>'name', '');
            v_usuario := nullif(ct->'profile'->>'username', '');
            v_gid := nullif(m->>'group_id', '');
            v_autor := null;
            v_ts := to_timestamp((m->>'timestamp')::bigint);

            if v_gid is not null then
              select id into v_conv from wa_conversa where grupo_meta_id = v_gid;
              if v_conv is null then
                v_conv := wa_grupo_registrar(v->'metadata'->>'phone_number_id', v_gid, 'Grupo', null, null, null);
              end if;
              v_autor := coalesce(v_nome, v_tel, v_bsuid);
            else
              if v_tel is null and v_bsuid is null then v_ign := v_ign + 1; continue; end if;
              v_cont := wa_meta_contato(v_tel, v_bsuid, v_nome, v_usuario);
              v_conv := wa_meta_conversa(v_num, v_cont, v_tel, v_bsuid, v_nome);
            end if;

            if m->>'type' = 'reaction' then
              update wa_mensagem set reacao = nullif(m->'reaction'->>'emoji', '')
               where id_whatsapp = m->'reaction'->>'message_id';
              continue;
            end if;

            if m->>'type' = 'system' and m->'system'->>'type' = 'user_changed_number' and v_gid is null then
              v_novo := nullif(regexp_replace(coalesce(m->'system'->>'wa_id', ''), '\D', '', 'g'), '');
              if v_novo is not null and not exists (select 1 from wa_contato where telefone_chave = wa_telefone_chave(v_novo)) then
                update wa_contato set telefone = v_novo, atualizado_em = now() where id = v_cont;
                update wa_conversa set contato_telefone = v_novo where contato_id = v_cont;
              end if;
              insert into wa_conversa_evento (conversa_id, tipo, detalhe)
              values (v_conv, 'trocou_numero', concat_ws(' -> ', v_tel, v_novo));
            end if;

            v_tipo := case m->>'type'
              when 'text' then 'texto' when 'image' then 'imagem' when 'audio' then 'audio'
              when 'video' then 'video' when 'document' then 'documento' when 'sticker' then 'figurinha'
              when 'contacts' then 'contato' when 'location' then 'local'
              when 'interactive' then 'texto' when 'button' then 'texto'
              else 'sistema' end;
            v_texto := case m->>'type'
              when 'text' then m->'text'->>'body'
              when 'interactive' then coalesce(m->'interactive'->'button_reply'->>'title',
                                               m->'interactive'->'list_reply'->>'title',
                                               case when m->'interactive' ? 'nfm_reply' then 'Formulário respondido' end)
              when 'button' then m->'button'->>'text'
              when 'location' then coalesce(m->'location'->>'name', m->'location'->>'address', 'Localização')
              when 'contacts' then (select string_agg(x->'name'->>'formatted_name', ', ')
                                      from jsonb_array_elements(m->'contacts') x)
              when 'document' then m->'document'->>'filename'
              when 'unsupported' then 'mensagem nao suportada'
              when 'system' then m->'system'->>'body'
              else '[' || coalesce(m->>'type', 'desconhecido') || ']' end;
            v_leg := null;
            if jsonb_typeof(m->(m->>'type')) = 'object' then v_leg := m->(m->>'type')->>'caption'; end if;
            d := case m->>'type'
              when 'location' then m->'location'
              when 'contacts' then jsonb_build_object('nome', m->'contacts'->0->'name'->>'formatted_name',
                                                      'telefone', regexp_replace(coalesce(m->'contacts'->0->'phones'->0->>'phone', ''), '\D', '', 'g'))
              when 'interactive' then case when m->'interactive' ? 'nfm_reply' then jsonb_build_object('formulario', m->'interactive'->'nfm_reply') end
              else null end;
            if m ? 'referral' then d := coalesce(d, '{}'::jsonb) || jsonb_build_object('anuncio', m->'referral'); end if;

            v_msg := null;
            insert into wa_mensagem (conversa_id, id_whatsapp, direcao, tipo, texto, legenda, status,
                                     responder_a, ocorrido_em, autor_grupo, dados, encaminhada)
            values (v_conv, m->>'id', 'entrada', v_tipo, v_texto, v_leg, 'recebida',
                    m->'context'->>'id', v_ts, v_autor, d, coalesce((m->'context'->>'forwarded')::boolean, false))
            on conflict (conversa_id, id_whatsapp) where id_whatsapp is not null do nothing
            returning id into v_msg;
            if v_msg is null then continue; end if;
            v_novas := v_novas + 1;

            update wa_conversa
               set ultima_previa = case when ultima_em is null or v_ts >= ultima_em
                                        then left(coalesce(v_leg, v_texto, '[' || v_tipo || ']'), 200) else ultima_previa end,
                   ultima_em = greatest(coalesce(ultima_em, v_ts), v_ts),
                   nao_lidas = nao_lidas + 1,
                   estado = case when estado = 'resolvida' then 'nova' else estado end,
                   atualizado_em = now()
             where id = v_conv;

            if v_tipo in ('imagem', 'audio', 'video', 'documento', 'figurinha') then
              d := m->(m->>'type');
              insert into wa_midia (mensagem_id, id_externo, tipo, mimetype, nome, sha256, estado, expira_em)
              values (v_msg, d->>'id', v_tipo, d->>'mime_type', d->>'filename', d->>'sha256', 'pendente',
                      v_ts + interval '7 days')
              on conflict (id_externo) where id_externo is not null do nothing;
              v_tinha_midia := true;
            end if;
          exception when others then
            insert into wa_webhook_falha (evento_id, campo, referencia, erro, trecho)
            values (v_ev, 'messages', m->>'id', left(sqlerrm, 500), m);
            v_falhas := v_falhas + 1;
          end;
        end loop;

        for s in select * from jsonb_array_elements(coalesce(v->'statuses', '[]')) loop
          begin
            if wa_meta_aplicar_status(s) then
              v_status := v_status + 1;
            elsif s->>'status' in ('sent', 'delivered', 'read', 'failed') then
              insert into wa_status_pendente (wamid, status) values (s->>'id', s)
              on conflict (wamid) do update
                set status = case when (case excluded.status->>'status' when 'failed' then 9 when 'read' then 3 when 'delivered' then 2 else 1 end)
                                     >= (case wa_status_pendente.status->>'status' when 'failed' then 9 when 'read' then 3 when 'delivered' then 2 else 1 end)
                                  then excluded.status else wa_status_pendente.status end,
                    recebido_em = now();
            end if;
          exception when others then
            insert into wa_webhook_falha (evento_id, campo, referencia, erro, trecho)
            values (v_ev, 'statuses', s->>'id', left(sqlerrm, 500), s);
            v_falhas := v_falhas + 1;
          end;
        end loop;

      exception when others then
        insert into wa_webhook_falha (evento_id, campo, erro, trecho) values (v_ev, ch->>'field', left(sqlerrm, 500), v);
        v_falhas := v_falhas + 1;
      end;
    end loop;
  end loop;

  update wa_webhook_evento set processado_ok = true, processado_em = now(),
                               erro = case when v_falhas > 0 then v_falhas || ' item(ns) com falha: ver wa_webhook_falha' end,
                               corpo = case when v_falhas > 0 then corpo end,
                               tinha_midia = v_tinha_midia
   where id = v_ev;

  return jsonb_build_object('ok', true, 'novas', v_novas, 'status', v_status, 'outros', v_outros,
                            'ignoradas', v_ign, 'falhas', v_falhas, 'baixar', wa_meta_midia_a_baixar(3));
end $function$;

revoke all on function public.wa_meta_aplicar_status(jsonb) from public, anon, authenticated;
revoke all on function public.wa_telefone_chave(text) from anon;

alter table public.wa_conversa_evento drop constraint if exists wa_conversa_evento_tipo_ck;
alter table public.wa_conversa_evento add constraint wa_conversa_evento_tipo_ck check (tipo = any (array[
  'abriu','assumiu','transferiu','devolveu','pausou','retomou','resolveu','reabriu','arquivou','nota','etiquetou','trocou_numero']));
