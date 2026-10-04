-- identidade sem telefone (BSUID)
alter table wa_contato alter column telefone drop not null;
alter table wa_contato add column if not exists bsuid text;
alter table wa_contato add column if not exists usuario_whatsapp text;
create unique index if not exists wa_contato_bsuid_uq on wa_contato (bsuid) where bsuid is not null;
alter table wa_contato drop constraint if exists wa_contato_identidade_ck;
alter table wa_contato add constraint wa_contato_identidade_ck check (telefone is not null or bsuid is not null);

alter table wa_conversa alter column contato_telefone drop not null;
alter table wa_conversa add column if not exists contato_bsuid text;
create unique index if not exists wa_conversa_aberta_bsuid_uq on wa_conversa (numero_id, contato_bsuid)
  where estado <> 'arquivada' and contato_bsuid is not null;
alter table wa_conversa drop constraint if exists wa_conversa_identidade_ck;
alter table wa_conversa add constraint wa_conversa_identidade_ck check (contato_telefone is not null or contato_bsuid is not null);

-- custo por mensagem
alter table wa_mensagem add column if not exists preco_categoria text;
alter table wa_mensagem add column if not exists preco_cobrada boolean;

-- saude do numero
alter table wa_saude add column if not exists limite_diario text;
alter table wa_saude add column if not exists ultimo_evento text;

-- modelos da Meta
create table if not exists wa_modelo (
  id uuid primary key default gen_random_uuid(),
  meta_id text not null unique,
  nome text not null,
  idioma text not null,
  categoria text,
  estado text not null default 'PENDING',
  motivo text,
  componentes jsonb,
  detalhe jsonb,
  atualizado_em timestamptz not null default now(),
  criado_em timestamptz not null default now()
);
create index if not exists wa_modelo_nome_ix on wa_modelo (nome, idioma);
alter table wa_modelo enable row level security;
drop policy if exists wa_modelo_ler on wa_modelo;
create policy wa_modelo_ler on wa_modelo for select to authenticated using (fiscal_nivel() is not null);
revoke insert, update, delete on wa_modelo from anon, authenticated;

-- contato por BSUID ou telefone
create or replace function public.wa_meta_contato(p_tel text, p_bsuid text, p_nome text, p_usuario text)
returns uuid
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_por_bsuid uuid; v_por_tel uuid; v_id uuid;
begin
  if p_bsuid is not null then select id into v_por_bsuid from wa_contato where bsuid = p_bsuid; end if;
  if p_tel is not null then select id into v_por_tel from wa_contato where telefone = p_tel; end if;

  if v_por_bsuid is not null and v_por_tel is not null and v_por_bsuid <> v_por_tel then
    v_id := v_por_tel;
  else
    v_id := coalesce(v_por_bsuid, v_por_tel);
  end if;

  if v_id is null then
    insert into wa_contato (telefone, bsuid, nome_whatsapp, usuario_whatsapp)
    values (p_tel, p_bsuid, p_nome, p_usuario)
    returning id into v_id;
  else
    update wa_contato
       set telefone = coalesce(telefone, p_tel),
           bsuid = case when bsuid is null and not exists (select 1 from wa_contato o where o.bsuid = p_bsuid)
                        then p_bsuid else bsuid end,
           nome_whatsapp = coalesce(p_nome, nome_whatsapp),
           usuario_whatsapp = coalesce(p_usuario, usuario_whatsapp),
           atualizado_em = now()
     where id = v_id;
  end if;
  return v_id;
end $$;

drop function if exists public.wa_meta_conversa(uuid, uuid, text, text);
create or replace function public.wa_meta_conversa(p_numero uuid, p_contato uuid, p_tel text, p_bsuid text, p_nome text)
returns uuid
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_conv uuid;
begin
  select id into v_conv from wa_conversa
   where numero_id = p_numero and estado <> 'arquivada'
     and ((p_tel is not null and contato_telefone = p_tel)
       or (p_bsuid is not null and contato_bsuid = p_bsuid)
       or (contato_id = p_contato))
   order by (contato_telefone = p_tel) desc nulls last
   limit 1;
  if v_conv is null then
    begin
      insert into wa_conversa (numero_id, contato_id, contato_telefone, contato_bsuid, contato_nome, estado, primeiro_em)
      values (p_numero, p_contato, p_tel, p_bsuid, p_nome, 'nova', now())
      returning id into v_conv;
    exception when unique_violation then
      select id into v_conv from wa_conversa
       where numero_id = p_numero and estado <> 'arquivada'
         and (contato_telefone = p_tel or contato_bsuid = p_bsuid)
       limit 1;
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
end $$;

-- recebimento (mensagens, status, modelos, saude)
create or replace function public.wa_meta_receber(p_corpo text)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $$
declare
  j jsonb; v_hash text; v_ev bigint; v_ja boolean;
  e jsonb; ch jsonb; v jsonb; m jsonb; s jsonb; d jsonb; ct jsonb;
  v_num uuid; v_tel text; v_bsuid text; v_nome text; v_usuario text; v_cont uuid; v_conv uuid; v_msg uuid;
  v_tipo text; v_texto text; v_leg text; v_ts timestamptz; v_ord int;
  v_novas int := 0; v_status int := 0; v_ign int := 0; v_outros int := 0; v_tinha_midia boolean := false;
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
        v := ch->'value';

        if ch->>'field' in ('message_template_status_update', 'template_category_update') then
          insert into wa_modelo (meta_id, nome, idioma, categoria, estado, motivo, detalhe)
          values (v->>'message_template_id', coalesce(v->>'message_template_name', '?'),
                  coalesce(v->>'message_template_language', '?'),
                  coalesce(v->>'message_template_category', v->>'new_category'),
                  coalesce(v->>'event', 'PENDING'), nullif(v->>'reason', 'NONE'), v)
          on conflict (meta_id) do update
            set estado = case when ch->>'field' = 'message_template_status_update'
                              then coalesce(excluded.estado, wa_modelo.estado) else wa_modelo.estado end,
                categoria = coalesce(v->>'new_category', v->>'message_template_category', wa_modelo.categoria),
                motivo = case when ch->>'field' = 'message_template_status_update' then excluded.motivo else wa_modelo.motivo end,
                nome = case when excluded.nome = '?' then wa_modelo.nome else excluded.nome end,
                idioma = case when excluded.idioma = '?' then wa_modelo.idioma else excluded.idioma end,
                detalhe = v, atualizado_em = now();
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

        if ch->>'field' is distinct from 'messages' then v_ign := v_ign + 1; continue; end if;

        select id into v_num from wa_numero
         where provedor = 'meta_cloud' and identificador = v->'metadata'->>'phone_number_id' and ativo;
        if v_num is null then
          raise exception 'numero da Meta % nao cadastrado no Fiscal', v->'metadata'->>'phone_number_id';
        end if;
        update wa_numero set visto_em = now(), conectado = true where id = v_num;

        for m in select * from jsonb_array_elements(coalesce(v->'messages', '[]')) loop
          if exists (select 1 from wa_mensagem where id_whatsapp = m->>'id') then continue; end if;

          v_tel := nullif(regexp_replace(coalesce(m->>'from', ''), '\D', '', 'g'), '');
          if v_tel is not null and (length(v_tel) < 10 or length(v_tel) > 15) then v_tel := null; end if;
          v_bsuid := nullif(m->>'from_user_id', '');
          select c into ct from jsonb_array_elements(coalesce(v->'contacts', '[]')) c
           where (m->>'from' is not null and c->>'wa_id' = m->>'from')
              or (v_bsuid is not null and c->>'user_id' = v_bsuid)
           limit 1;
          v_bsuid := coalesce(v_bsuid, nullif(ct->>'user_id', ''));
          v_nome := nullif(ct->'profile'->>'name', '');
          v_usuario := nullif(ct->'profile'->>'username', '');
          if v_tel is null and v_bsuid is null then v_ign := v_ign + 1; continue; end if;

          v_cont := wa_meta_contato(v_tel, v_bsuid, v_nome, v_usuario);
          v_conv := wa_meta_conversa(v_num, v_cont, v_tel, v_bsuid, v_nome);
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
          v_leg := null;
          if jsonb_typeof(m->(m->>'type')) = 'object' then v_leg := m->(m->>'type')->>'caption'; end if;

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
                        else w.erro end,
            preco_categoria = coalesce(s->'pricing'->>'category', w.preco_categoria),
            preco_cobrada = coalesce((s->'pricing'->>'billable')::boolean, w.preco_cobrada)
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

  return jsonb_build_object('ok', true, 'novas', v_novas, 'status', v_status, 'outros', v_outros,
                            'ignoradas', v_ign, 'baixar', wa_meta_midia_a_baixar(10));
end $$;

-- envio devolve telefone e BSUID
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
                            'bsuid', cv.contato_bsuid, 'phone_number_id', nm.identificador);
end $$;

revoke all on function public.wa_meta_contato(text, text, text, text) from public, anon, authenticated;
revoke all on function public.wa_meta_conversa(uuid, uuid, text, text, text) from public, anon, authenticated;
revoke all on function public.wa_meta_receber(text) from public, anon, authenticated;
revoke all on function public.wa_meta_preparar_envio(uuid, text, text, text, text, jsonb, text) from public, anon;
grant execute on function public.wa_meta_receber(text) to service_role;
grant execute on function public.wa_meta_preparar_envio(uuid, text, text, text, text, jsonb, text) to authenticated, service_role;
