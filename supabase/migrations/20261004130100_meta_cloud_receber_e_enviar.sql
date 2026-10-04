-- conversa aberta do contato
create or replace function public.wa_meta_conversa(p_numero uuid, p_contato uuid, p_tel text, p_nome text)
returns uuid
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_conv uuid;
begin
  select id into v_conv from wa_conversa
   where numero_id = p_numero and contato_telefone = p_tel and estado <> 'arquivada';
  if v_conv is null then
    insert into wa_conversa (numero_id, contato_id, contato_telefone, contato_nome, estado, primeiro_em)
    values (p_numero, p_contato, p_tel, p_nome, 'nova', now())
    on conflict (numero_id, contato_telefone) where estado <> 'arquivada' do nothing
    returning id into v_conv;
    if v_conv is null then
      select id into v_conv from wa_conversa
       where numero_id = p_numero and contato_telefone = p_tel and estado <> 'arquivada';
    end if;
  elsif p_contato is not null then
    update wa_conversa set contato_id = coalesce(contato_id, p_contato),
                           contato_nome = coalesce(contato_nome, p_nome)
     where id = v_conv and (contato_id is null or contato_nome is null);
  end if;
  return v_conv;
end $$;

-- midia: fila de download (dispara a cada evento, sem relogio)
create or replace function public.wa_meta_midia_a_baixar(p_limite int default 10)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare r jsonb;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  with alvo as (
    select d.id from wa_midia d
     where d.estado in ('pendente', 'falhou') and d.id_externo is not null
       and d.tentativas < 5
       and (d.expira_em is null or d.expira_em > now())
       and (d.proxima_em is null or d.proxima_em <= now())
     order by d.criado_em
     limit p_limite
     for update skip locked
  ), marcadas as (
    update wa_midia d set estado = 'baixando', tentativas = d.tentativas + 1
      from alvo where d.id = alvo.id
    returning d.id, d.id_externo, d.tipo, d.mensagem_id
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'midia_id', k.id, 'media_id', k.id_externo, 'tipo', k.tipo,
           'mensagem_id', k.mensagem_id, 'conversa_id', m.conversa_id)), '[]'::jsonb)
    into r
    from marcadas k join wa_mensagem m on m.id = k.mensagem_id;
  return r;
end $$;

create or replace function public.wa_meta_midia_resultado(
  p_midia_id uuid, p_ok boolean, p_caminho text default null, p_tamanho bigint default null,
  p_mime text default null, p_sha256 text default null, p_erro text default null, p_desistir boolean default false)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare n int;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if p_ok then
    update wa_midia set estado = 'guardado', caminho = p_caminho, tamanho = coalesce(p_tamanho, tamanho),
                        mimetype = coalesce(p_mime, mimetype), sha256 = coalesce(p_sha256, sha256),
                        baixado_em = now(), ultimo_erro = null, proxima_em = null
     where id = p_midia_id;
  else
    update wa_midia set estado = case when p_desistir or tentativas >= 5 then 'desistiu' else 'falhou' end,
                        ultimo_erro = left(p_erro, 500),
                        proxima_em = now() + make_interval(mins => power(2, tentativas)::int)
     where id = p_midia_id;
  end if;
  get diagnostics n = row_count;
  return n = 1;
end $$;

-- recebe o corpo do webhook ja com assinatura conferida
create or replace function public.wa_meta_receber(p_corpo text)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $$
declare
  j jsonb; v_hash text; v_ev bigint; v_ja boolean;
  e jsonb; ch jsonb; v jsonb; m jsonb; s jsonb; d jsonb;
  v_num uuid; v_tel text; v_nome text; v_cont uuid; v_conv uuid; v_msg uuid;
  v_tipo text; v_texto text; v_leg text; v_ts timestamptz; v_ord int;
  v_novas int := 0; v_status int := 0; v_ign int := 0; v_tinha_midia boolean := false;
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

  begin
    if j->>'object' is distinct from 'whatsapp_business_account' then
      raise exception 'objeto inesperado: %', j->>'object';
    end if;

    for e in select * from jsonb_array_elements(coalesce(j->'entry', '[]')) loop
      for ch in select * from jsonb_array_elements(coalesce(e->'changes', '[]')) loop
        if ch->>'field' is distinct from 'messages' then v_ign := v_ign + 1; continue; end if;
        v := ch->'value';

        select id into v_num from wa_numero
         where provedor = 'meta_cloud' and identificador = v->'metadata'->>'phone_number_id' and ativo;
        if v_num is null then
          raise exception 'numero da Meta % nao cadastrado no Fiscal', v->'metadata'->>'phone_number_id';
        end if;
        update wa_numero set visto_em = now(), conectado = true where id = v_num;

        for m in select * from jsonb_array_elements(coalesce(v->'messages', '[]')) loop
          if exists (select 1 from wa_mensagem where id_whatsapp = m->>'id') then continue; end if;

          v_tel := regexp_replace(coalesce(m->>'from', ''), '\D', '', 'g');
          if length(v_tel) < 10 or length(v_tel) > 15 then v_ign := v_ign + 1; continue; end if;
          select c->'profile'->>'name' into v_nome
            from jsonb_array_elements(coalesce(v->'contacts', '[]')) c
           where c->>'wa_id' = m->>'from' limit 1;

          insert into wa_contato (telefone, nome_whatsapp) values (v_tel, nullif(v_nome, ''))
          on conflict (telefone) do update
            set nome_whatsapp = coalesce(excluded.nome_whatsapp, wa_contato.nome_whatsapp), atualizado_em = now()
          returning id into v_cont;
          v_conv := wa_meta_conversa(v_num, v_cont, v_tel, nullif(v_nome, ''));
          v_ts := to_timestamp((m->>'timestamp')::bigint);

          if m->>'type' = 'reaction' then
            update wa_mensagem set reacao = nullif(m->'reaction'->>'emoji', '')
             where id_whatsapp = m->'reaction'->>'message_id';
            continue;
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
                                             m->'interactive'->'nfm_reply'->>'response_json')
            when 'button' then m->'button'->>'text'
            when 'location' then concat_ws(' ', m->'location'->>'name', m->'location'->>'address',
                                           '(' || (m->'location'->>'latitude') || ',' || (m->'location'->>'longitude') || ')')
            when 'contacts' then (select string_agg(x->'name'->>'formatted_name', ', ')
                                    from jsonb_array_elements(m->'contacts') x)
            when 'document' then m->'document'->>'filename'
            when 'unsupported' then 'mensagem nao suportada'
            when 'system' then m->'system'->>'body'
            else null end;
          v_leg := coalesce(m->(m->>'type')->>'caption', null);
          if jsonb_typeof(m->(m->>'type')) is distinct from 'object' then v_leg := null; end if;

          insert into wa_mensagem (conversa_id, id_whatsapp, direcao, tipo, texto, legenda, status,
                                   responder_a, ocorrido_em)
          values (v_conv, m->>'id', 'entrada', v_tipo, v_texto, v_leg, 'recebida',
                  m->'context'->>'id', v_ts)
          on conflict (conversa_id, id_whatsapp) where id_whatsapp is not null do nothing
          returning id into v_msg;
          if v_msg is null then continue; end if;
          v_novas := v_novas + 1;

          update wa_conversa
             set ultima_em = greatest(coalesce(ultima_em, v_ts), v_ts),
                 ultima_previa = left(coalesce(v_leg, v_texto, '[' || v_tipo || ']'), 200),
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
        end loop;

        for s in select * from jsonb_array_elements(coalesce(v->'statuses', '[]')) loop
          v_ord := case s->>'status' when 'sent' then 1 when 'delivered' then 2 when 'read' then 3
                                     when 'failed' then 9 else null end;
          if v_ord is null then continue; end if;
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
                        else w.erro end
          where w.id_whatsapp = s->>'id' and w.direcao = 'saida';
          if found then v_status := v_status + 1; end if;
        end loop;
      end loop;
    end loop;

    update wa_webhook_evento set processado_ok = true, processado_em = now(), erro = null,
                                 tinha_midia = v_tinha_midia
     where id = v_ev;
  exception when others then
    update wa_webhook_evento set processado_ok = false, processado_em = now(), erro = left(sqlerrm, 500)
     where id = v_ev;
    return jsonb_build_object('ok', false, 'erro', sqlerrm);
  end;

  return jsonb_build_object('ok', true, 'novas', v_novas, 'status', v_status, 'ignoradas', v_ign,
                            'baixar', wa_meta_midia_a_baixar(10));
end $$;

-- envio: 1) prepara (usuario), 2) resultado (servidor)
create or replace function public.wa_meta_preparar_envio(
  p_conversa_id uuid, p_id_local text, p_tipo text, p_texto text default null,
  p_legenda text default null, p_arquivo jsonb default null, p_responder_a text default null)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare cv wa_conversa%rowtype; nm wa_numero%rowtype; v_id uuid; v_ult timestamptz; ex wa_mensagem%rowtype;
        v_mime text; v_tam bigint; v_lim bigint; v_nome text;
begin
  if not fiscal_e_servidor() and fiscal_nivel() is null then
    return jsonb_build_object('ok', false, 'erro', 'Usuario sem cadastro no Fiscal.');
  end if;
  if coalesce(btrim(p_id_local), '') = '' then
    return jsonb_build_object('ok', false, 'erro', 'Falta o id da mensagem.');
  end if;

  select * into ex from wa_mensagem where id_local = p_id_local;
  if ex.id is not null then
    return jsonb_build_object('ok', true, 'repetida', true, 'mensagem_id', ex.id, 'status', ex.status);
  end if;

  select * into cv from wa_conversa where id = p_conversa_id;
  if cv.id is null or not (fiscal_e_servidor() or (cv.contato_id is not null and fiscal_pode_ver_contato(cv.contato_id))) then
    return jsonb_build_object('ok', false, 'erro', 'Conversa nao encontrada.');
  end if;
  select * into nm from wa_numero where id = cv.numero_id;
  if nm.provedor <> 'meta_cloud' or not nm.ativo then
    return jsonb_build_object('ok', false, 'erro', 'Esta conversa nao e do numero oficial.');
  end if;

  if p_tipo not in ('texto', 'template', 'imagem', 'audio', 'video', 'documento') then
    return jsonb_build_object('ok', false, 'erro', 'Tipo de mensagem invalido.');
  end if;
  if p_tipo = 'texto' and (coalesce(btrim(p_texto), '') = '' or length(p_texto) > 4096) then
    return jsonb_build_object('ok', false, 'erro', 'Texto vazio ou acima de 4096 caracteres.');
  end if;
  if length(coalesce(p_legenda, '')) > 1024 then
    return jsonb_build_object('ok', false, 'erro', 'Legenda acima de 1024 caracteres.');
  end if;

  if p_tipo in ('imagem', 'audio', 'video', 'documento') then
    v_mime := lower(coalesce(p_arquivo->>'mime', ''));
    v_tam := coalesce((p_arquivo->>'tamanho')::bigint, 0);
    v_nome := lower(coalesce(p_arquivo->>'nome', ''));
    if coalesce(p_arquivo->>'caminho', '') = '' or v_tam <= 0 then
      return jsonb_build_object('ok', false, 'erro', 'Arquivo nao informado.');
    end if;
    if v_mime in ('application/xml', 'text/xml', 'application/zip', 'application/x-zip-compressed')
       or v_nome like '%.xml' or v_nome like '%.zip' then
      return jsonb_build_object('ok', false, 'erro', 'A Meta nao aceita XML nem ZIP.');
    end if;
    v_lim := case p_tipo when 'imagem' then 5242880 when 'audio' then 16777216
                         when 'video' then 16777216 else 104857600 end;
    if v_tam > v_lim then
      return jsonb_build_object('ok', false, 'erro', 'Arquivo acima do limite da Meta para ' || p_tipo || '.');
    end if;
  end if;

  if p_tipo <> 'template' then
    select max(ocorrido_em) into v_ult from wa_mensagem where conversa_id = cv.id and direcao = 'entrada';
    if v_ult is null or v_ult < now() - interval '24 hours' then
      return jsonb_build_object('ok', false, 'erro', 'Fora da janela de 24h: so modelo aprovado.', 'codigo', 131047);
    end if;
  end if;

  insert into wa_mensagem (conversa_id, id_local, direcao, tipo, texto, legenda, status, autor_id,
                           responder_a, ocorrido_em)
  values (cv.id, p_id_local, 'saida', case when p_tipo = 'template' then 'texto' else p_tipo end,
          p_texto, p_legenda, 'enviando', auth.uid(), p_responder_a, now())
  returning id into v_id;

  if p_tipo in ('imagem', 'audio', 'video', 'documento') then
    insert into wa_midia (mensagem_id, tipo, mimetype, nome, tamanho, caminho, estado)
    values (v_id, p_tipo, p_arquivo->>'mime', p_arquivo->>'nome', v_tam, p_arquivo->>'caminho', 'guardado');
  end if;

  return jsonb_build_object('ok', true, 'mensagem_id', v_id, 'telefone', cv.contato_telefone,
                            'phone_number_id', nm.identificador);
end $$;

create or replace function public.wa_meta_resultado_envio(
  p_mensagem_id uuid, p_wamid text, p_erro_codigo int default null, p_erro text default null)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_conv uuid; v_prev text; n int;
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
  else
    update wa_mensagem set status = 'falhou', tentativas = tentativas + 1,
                           erro = left(case p_erro_codigo
                                         when 131047 then '131047 fora da janela de 24h: so modelo aprovado'
                                         else concat_ws(' ', p_erro_codigo::text, p_erro) end, 500)
     where id = p_mensagem_id;
    get diagnostics n = row_count;
  end if;
  return n = 1;
end $$;

revoke all on function public.wa_meta_conversa(uuid, uuid, text, text) from public, anon, authenticated;
revoke all on function public.wa_meta_midia_a_baixar(int) from public, anon, authenticated;
revoke all on function public.wa_meta_midia_resultado(uuid, boolean, text, bigint, text, text, text, boolean) from public, anon, authenticated;
revoke all on function public.wa_meta_receber(text) from public, anon, authenticated;
revoke all on function public.wa_meta_resultado_envio(uuid, text, int, text) from public, anon, authenticated;
revoke all on function public.wa_meta_preparar_envio(uuid, text, text, text, text, jsonb, text) from public, anon;
grant execute on function public.wa_meta_midia_a_baixar(int) to service_role;
grant execute on function public.wa_meta_midia_resultado(uuid, boolean, text, bigint, text, text, text, boolean) to service_role;
grant execute on function public.wa_meta_receber(text) to service_role;
grant execute on function public.wa_meta_resultado_envio(uuid, text, int, text) to service_role;
grant execute on function public.wa_meta_preparar_envio(uuid, text, text, text, text, jsonb, text) to authenticated, service_role;
