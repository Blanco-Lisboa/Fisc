alter table public.wa_conversa
  add column if not exists arquivada boolean not null default false,
  add column if not exists fixada_em timestamptz,
  add column if not exists silenciada boolean not null default false,
  add column if not exists marcada_nao_lida boolean not null default false,
  add column if not exists grupo_meta_id text,
  add column if not exists grupo_link text,
  add column if not exists grupo_descricao text;
create unique index if not exists wa_conversa_grupo_uq on public.wa_conversa (grupo_meta_id) where grupo_meta_id is not null;

alter table public.wa_mensagem
  add column if not exists reacao_nossa text,
  add column if not exists encaminhada boolean not null default false,
  add column if not exists favorita boolean not null default false,
  add column if not exists apagada_por uuid,
  add column if not exists dados jsonb;

create or replace function public.wa_pode_agir_conversa(p_conversa uuid)
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select fiscal_e_servidor() or exists (
    select 1 from wa_conversa c
     where c.id = p_conversa and c.contato_id is not null and fiscal_pode_enviar_contato(c.contato_id));
$$;
revoke all on function public.wa_pode_agir_conversa(uuid) from public, anon;
grant execute on function public.wa_pode_agir_conversa(uuid) to authenticated, service_role;

create or replace function public.wa_pode_ver_conversa(p_conversa uuid)
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select fiscal_e_servidor() or exists (
    select 1 from wa_conversa c
     where c.id = p_conversa and c.contato_id is not null and fiscal_pode_ver_contato(c.contato_id));
$$;
revoke all on function public.wa_pode_ver_conversa(uuid) from public, anon;
grant execute on function public.wa_pode_ver_conversa(uuid) to authenticated, service_role;

create or replace function public.wa_conversa_marcar(p_conversa uuid, p_campo text, p_valor boolean)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare n int;
begin
  if not wa_pode_agir_conversa(p_conversa) then raise exception 'sem permissao nesta conversa'; end if;
  if p_campo = 'arquivada' then
    update wa_conversa set arquivada = p_valor, atualizado_em = now() where id = p_conversa;
  elsif p_campo = 'fixada' then
    if p_valor and (select count(*) from wa_conversa where fixada_em is not null and id <> p_conversa) >= 3 then
      raise exception 'no maximo 3 conversas fixadas';
    end if;
    update wa_conversa set fixada_em = case when p_valor then now() end, atualizado_em = now() where id = p_conversa;
  elsif p_campo = 'silenciada' then
    update wa_conversa set silenciada = p_valor, atualizado_em = now() where id = p_conversa;
  elsif p_campo = 'nao_lida' then
    update wa_conversa set marcada_nao_lida = p_valor, nao_lidas = case when p_valor then nao_lidas else 0 end,
                           atualizado_em = now() where id = p_conversa;
  else
    raise exception 'campo invalido';
  end if;
  get diagnostics n = row_count;
  return n = 1;
end $$;
revoke all on function public.wa_conversa_marcar(uuid, text, boolean) from public, anon;
grant execute on function public.wa_conversa_marcar(uuid, text, boolean) to authenticated, service_role;

create or replace function public.wa_mensagem_marcar(p_mensagem uuid, p_campo text, p_valor boolean)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_conv uuid; n int;
begin
  select conversa_id into v_conv from wa_mensagem where id = p_mensagem;
  if v_conv is null or not wa_pode_agir_conversa(v_conv) then raise exception 'sem permissao nesta conversa'; end if;
  if p_campo = 'favorita' then
    update wa_mensagem set favorita = p_valor where id = p_mensagem;
  elsif p_campo = 'apagada' then
    update wa_mensagem set apagada_em = case when p_valor then now() end,
                           apagada_por = case when p_valor then auth.uid() end
     where id = p_mensagem;
  else
    raise exception 'campo invalido';
  end if;
  get diagnostics n = row_count;
  return n = 1;
end $$;
revoke all on function public.wa_mensagem_marcar(uuid, text, boolean) from public, anon;
grant execute on function public.wa_mensagem_marcar(uuid, text, boolean) to authenticated, service_role;

create or replace function public.wa_meta_acao_preparar(p_acao text, p_conversa uuid, p_mensagem uuid default null)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare cv wa_conversa%rowtype; nm wa_numero%rowtype; v_wamid text; v_ult text;
begin
  if p_acao not in ('lida', 'digitando', 'reagir', 'bloquear', 'desbloquear', 'grupo_link', 'grupo_link_novo',
                    'grupo_pedidos', 'grupo_aprovar', 'grupo_recusar', 'grupo_remover', 'grupo_editar',
                    'grupo_apagar', 'grupo_info') then
    return jsonb_build_object('ok', false, 'erro', 'Acao invalida.');
  end if;
  select * into cv from wa_conversa where id = p_conversa;
  if cv.id is null or not wa_pode_agir_conversa(cv.id) then
    return jsonb_build_object('ok', false, 'erro', 'Sem permissao nesta conversa.');
  end if;
  if p_acao like 'grupo%' and (cv.grupo_meta_id is null or coalesce(fiscal_nivel(), '') not in ('assistente', 'gerente')) and not fiscal_e_servidor() then
    return jsonb_build_object('ok', false, 'erro', 'So gestor administra grupo.');
  end if;
  select * into nm from wa_numero where id = cv.numero_id;
  if nm.provedor <> 'meta_cloud' or not nm.ativo then
    return jsonb_build_object('ok', false, 'erro', 'Esta conversa nao e do numero oficial.');
  end if;
  if p_mensagem is not null then
    select id_whatsapp into v_wamid from wa_mensagem where id = p_mensagem and conversa_id = cv.id;
    if v_wamid is null then return jsonb_build_object('ok', false, 'erro', 'Mensagem sem id do WhatsApp.'); end if;
  end if;
  select id_whatsapp into v_ult from wa_mensagem
   where conversa_id = cv.id and direcao = 'entrada' and id_whatsapp is not null
   order by ocorrido_em desc limit 1;
  return jsonb_build_object('ok', true, 'phone_number_id', nm.identificador, 'telefone', cv.contato_telefone,
                            'grupo_id', cv.grupo_meta_id, 'wamid', v_wamid, 'ultima_recebida', v_ult,
                            'contato_id', cv.contato_id);
end $$;
revoke all on function public.wa_meta_acao_preparar(text, uuid, uuid) from public, anon;
grant execute on function public.wa_meta_acao_preparar(text, uuid, uuid) to authenticated, service_role;

create or replace function public.wa_meta_acao_resultado(p_acao text, p_conversa uuid, p_mensagem uuid, p_dados jsonb)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if p_acao = 'lida' then
    update wa_conversa set nao_lidas = 0, marcada_nao_lida = false where id = p_conversa;
  elsif p_acao = 'reagir' then
    update wa_mensagem set reacao_nossa = nullif(p_dados->>'emoji', '') where id = p_mensagem and conversa_id = p_conversa;
  elsif p_acao in ('bloquear', 'desbloquear') then
    update wa_contato set bloqueado = (p_acao = 'bloquear'), atualizado_em = now()
     where id = (select contato_id from wa_conversa where id = p_conversa);
  elsif p_acao in ('grupo_link', 'grupo_link_novo') then
    update wa_conversa set grupo_link = p_dados->>'invite_link' where id = p_conversa;
  elsif p_acao = 'grupo_editar' then
    update wa_conversa set contato_nome = coalesce(nullif(p_dados->>'subject', ''), contato_nome),
                           grupo_descricao = coalesce(p_dados->>'description', grupo_descricao) where id = p_conversa;
  elsif p_acao = 'grupo_apagar' then
    update wa_conversa set arquivada = true, estado = 'resolvida' where id = p_conversa;
  end if;
  return true;
end $$;
revoke all on function public.wa_meta_acao_resultado(text, uuid, uuid, jsonb) from public, anon, authenticated;
grant execute on function public.wa_meta_acao_resultado(text, uuid, uuid, jsonb) to service_role;

create or replace function public.wa_grupo_registrar(p_numero_identificador text, p_grupo_id text, p_nome text, p_descricao text, p_link text, p_por uuid)
returns uuid
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_num uuid; v_cont uuid; v_conv uuid;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  select id into v_num from wa_numero where provedor = 'meta_cloud' and identificador = p_numero_identificador and ativo;
  if v_num is null then raise exception 'numero nao cadastrado'; end if;
  insert into wa_contato (bsuid, nome_whatsapp, e_grupo)
  values ('grupo:' || p_grupo_id, p_nome, true)
  on conflict (bsuid) where bsuid is not null do update set nome_whatsapp = coalesce(excluded.nome_whatsapp, wa_contato.nome_whatsapp)
  returning id into v_cont;
  insert into wa_conversa (numero_id, contato_id, contato_bsuid, contato_nome, e_grupo, estado, primeiro_em,
                           grupo_meta_id, grupo_link, grupo_descricao, responsavel_id)
  values (v_num, v_cont, 'grupo:' || p_grupo_id, p_nome, true, 'nova', now(), p_grupo_id, p_link, p_descricao, p_por)
  on conflict (grupo_meta_id) where grupo_meta_id is not null do update
    set grupo_link = coalesce(excluded.grupo_link, wa_conversa.grupo_link),
        contato_nome = coalesce(excluded.contato_nome, wa_conversa.contato_nome)
  returning id into v_conv;
  return v_conv;
end $$;
revoke all on function public.wa_grupo_registrar(text, text, text, text, text, uuid) from public, anon, authenticated;
grant execute on function public.wa_grupo_registrar(text, text, text, text, text, uuid) to service_role;

create or replace function public.wa_encaminhar_preparar(p_mensagem uuid, p_destino uuid)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare m wa_mensagem%rowtype; md wa_midia%rowtype;
begin
  select * into m from wa_mensagem where id = p_mensagem and apagada_em is null;
  if m.id is null or not wa_pode_ver_conversa(m.conversa_id) then
    return jsonb_build_object('ok', false, 'erro', 'Mensagem nao encontrada.');
  end if;
  if not wa_pode_agir_conversa(p_destino) then
    return jsonb_build_object('ok', false, 'erro', 'Sem permissao na conversa de destino.');
  end if;
  select * into md from wa_midia where mensagem_id = m.id limit 1;
  if m.tipo in ('imagem', 'audio', 'video', 'documento') and (md.id is null or md.estado <> 'guardado' or md.caminho is null or md.caminho ~ '^https?://') then
    return jsonb_build_object('ok', false, 'erro', 'Arquivo ainda nao disponivel para encaminhar.');
  end if;
  return jsonb_build_object('ok', true, 'tipo', m.tipo, 'texto', m.texto, 'legenda', m.legenda, 'dados', m.dados,
                            'caminho', md.caminho, 'nome', md.nome, 'mime', md.mimetype);
end $$;
revoke all on function public.wa_encaminhar_preparar(uuid, uuid) from public, anon;
grant execute on function public.wa_encaminhar_preparar(uuid, uuid) to authenticated, service_role;

drop policy if exists wa_midia_enviar on storage.objects;
create policy wa_midia_enviar on storage.objects for insert to authenticated
  with check (bucket_id = 'wa-midia' and (storage.foldername(name))[2] = 'saida'
              and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
              and wa_pode_agir_conversa(((storage.foldername(name))[1])::uuid));
drop policy if exists wa_midia_ver on storage.objects;
create policy wa_midia_ver on storage.objects for select to authenticated
  using (bucket_id = 'wa-midia' and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
         and wa_pode_ver_conversa(((storage.foldername(name))[1])::uuid));

create or replace function public.wa_meta_preparar_envio(p_conversa_id uuid, p_id_local text, p_tipo text, p_texto text DEFAULT NULL::text, p_legenda text DEFAULT NULL::text, p_arquivo jsonb DEFAULT NULL::jsonb, p_responder_a text DEFAULT NULL::text, p_modelo jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'storage', 'pg_temp'
AS $function$
declare cv wa_conversa%rowtype; nm wa_numero%rowtype; v_id uuid; v_ult timestamptz; ex wa_mensagem%rowtype;
        v_mime text; v_tam bigint; v_lim bigint; v_nome text; v_caminho text; v_obj text; v_meta jsonb; md wa_modelo%rowtype;
        v_dados jsonb;
begin
  if not fiscal_e_servidor() and fiscal_nivel() is null then
    return jsonb_build_object('ok', false, 'erro', 'Usuario sem cadastro no Fiscal.');
  end if;
  if coalesce(btrim(p_id_local), '') = '' then
    return jsonb_build_object('ok', false, 'erro', 'Falta o id da mensagem.');
  end if;

  select * into ex from wa_mensagem where id_local = p_id_local;
  if ex.id is not null then
    if ex.conversa_id = p_conversa_id and (fiscal_e_servidor() or ex.autor_id = auth.uid()) then
      return jsonb_build_object('ok', true, 'repetida', true, 'mensagem_id', ex.id, 'status', ex.status);
    end if;
    return jsonb_build_object('ok', false, 'erro', 'Id da mensagem ja usado.');
  end if;

  select * into cv from wa_conversa where id = p_conversa_id;
  if cv.id is null or not (fiscal_e_servidor() or (cv.contato_id is not null and fiscal_pode_ver_contato(cv.contato_id))) then
    return jsonb_build_object('ok', false, 'erro', 'Conversa nao encontrada.');
  end if;
  if not (fiscal_e_servidor() or fiscal_pode_enviar_contato(cv.contato_id)) then
    return jsonb_build_object('ok', false, 'erro', 'Contato nao vinculado a uma empresa da sua carteira.');
  end if;
  if exists (select 1 from wa_contato where id = cv.contato_id and bloqueado) then
    return jsonb_build_object('ok', false, 'erro', 'Contato bloqueado.');
  end if;
  select * into nm from wa_numero where id = cv.numero_id;
  if nm.provedor <> 'meta_cloud' or not nm.ativo then
    return jsonb_build_object('ok', false, 'erro', 'Esta conversa nao e do numero oficial.');
  end if;

  if p_tipo not in ('texto', 'template', 'imagem', 'audio', 'video', 'documento', 'local', 'contato') then
    return jsonb_build_object('ok', false, 'erro', 'Tipo de mensagem invalido.');
  end if;
  if p_tipo = 'texto' and (coalesce(btrim(p_texto), '') = '' or length(p_texto) > 4096) then
    return jsonb_build_object('ok', false, 'erro', 'Texto vazio ou acima de 4096 caracteres.');
  end if;
  if length(coalesce(p_legenda, '')) > 1024 then
    return jsonb_build_object('ok', false, 'erro', 'Legenda acima de 1024 caracteres.');
  end if;
  if p_tipo = 'local' then
    if jsonb_typeof(p_arquivo->'latitude') is distinct from 'number' or jsonb_typeof(p_arquivo->'longitude') is distinct from 'number'
       or abs((p_arquivo->>'latitude')::numeric) > 90 or abs((p_arquivo->>'longitude')::numeric) > 180 then
      return jsonb_build_object('ok', false, 'erro', 'Localizacao invalida.');
    end if;
    v_dados := jsonb_build_object('latitude', p_arquivo->'latitude', 'longitude', p_arquivo->'longitude',
                                  'name', left(p_arquivo->>'name', 200), 'address', left(p_arquivo->>'address', 300));
  elsif p_tipo = 'contato' then
    if coalesce(btrim(p_arquivo->>'nome'), '') = '' or regexp_replace(coalesce(p_arquivo->>'telefone', ''), '\D', '', 'g') !~ '^[0-9]{10,15}$' then
      return jsonb_build_object('ok', false, 'erro', 'Contato precisa de nome e telefone.');
    end if;
    v_dados := jsonb_build_object('nome', left(p_arquivo->>'nome', 200),
                                  'telefone', regexp_replace(p_arquivo->>'telefone', '\D', '', 'g'));
  end if;

  if p_tipo = 'template' then
    select * into md from wa_modelo
     where nome = p_modelo->>'nome' and idioma = coalesce(p_modelo->>'idioma', 'pt_BR') and estado = 'APPROVED'
     limit 1;
    if md.id is null then
      return jsonb_build_object('ok', false, 'erro', 'Modelo nao aprovado pela Meta.');
    end if;
  end if;

  if p_tipo in ('imagem', 'audio', 'video', 'documento') then
    v_caminho := coalesce(p_arquivo->>'caminho', '');
    if v_caminho not like cv.id::text || '/saida/%' or v_caminho like '%..%' then
      return jsonb_build_object('ok', false, 'erro', 'Arquivo fora da pasta da conversa.');
    end if;
    select o.name, o.metadata into v_obj, v_meta from storage.objects o where o.bucket_id = 'wa-midia' and o.name = v_caminho;
    if v_obj is null then
      return jsonb_build_object('ok', false, 'erro', 'Arquivo nao encontrado.');
    end if;
    v_mime := lower(coalesce(v_meta->>'mimetype', ''));
    v_tam := coalesce((v_meta->>'size')::bigint, 0);
    v_nome := lower(coalesce(p_arquivo->>'nome', v_caminho));
    if v_tam <= 0 then
      return jsonb_build_object('ok', false, 'erro', 'Arquivo vazio.');
    end if;
    if v_mime in ('application/xml', 'text/xml', 'application/zip', 'application/x-zip-compressed')
       or v_nome like '%.xml' or v_nome like '%.zip' or v_caminho like '%.xml' or v_caminho like '%.zip' then
      return jsonb_build_object('ok', false, 'erro', 'A Meta nao aceita XML nem ZIP.');
    end if;
    if p_tipo = 'audio' and split_part(v_mime, ';', 1) not in ('audio/ogg', 'audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/amr') then
      return jsonb_build_object('ok', false, 'erro', 'Formato de audio nao aceito pela Meta.');
    end if;
    v_lim := case p_tipo when 'imagem' then 5242880 when 'audio' then 16777216
                         when 'video' then 16777216 else 104857600 end;
    if v_tam > v_lim then
      return jsonb_build_object('ok', false, 'erro', 'Arquivo acima do limite da Meta para ' || p_tipo || '.');
    end if;
  end if;

  if p_tipo <> 'template' and cv.grupo_meta_id is null then
    select max(ocorrido_em) into v_ult from wa_mensagem where conversa_id = cv.id and direcao = 'entrada';
    if v_ult is null or v_ult < now() - interval '24 hours' then
      return jsonb_build_object('ok', false, 'erro', 'Fora da janela de 24h: so modelo aprovado.', 'codigo', 131047);
    end if;
  end if;

  insert into wa_mensagem (conversa_id, id_local, direcao, tipo, texto, legenda, status, autor_id,
                           responder_a, ocorrido_em, dados)
  values (cv.id, p_id_local, 'saida', case when p_tipo = 'template' then 'texto' else p_tipo end,
          case when p_tipo = 'template' then coalesce(p_texto, '[modelo ' || md.nome || ']')
               when p_tipo = 'local' then coalesce(v_dados->>'name', 'Localização')
               when p_tipo = 'contato' then v_dados->>'nome'
               else p_texto end,
          p_legenda, 'enviando', auth.uid(), p_responder_a, now(), v_dados)
  returning id into v_id;

  if p_tipo in ('imagem', 'audio', 'video', 'documento') then
    insert into wa_midia (mensagem_id, tipo, mimetype, nome, tamanho, caminho, estado)
    values (v_id, p_tipo, v_mime, p_arquivo->>'nome', v_tam, v_caminho, 'guardado');
  end if;

  return jsonb_build_object('ok', true, 'mensagem_id', v_id, 'telefone', cv.contato_telefone,
                            'bsuid', case when cv.grupo_meta_id is null then cv.contato_bsuid end,
                            'grupo_id', cv.grupo_meta_id, 'phone_number_id', nm.identificador,
                            'modelo_nome', md.nome, 'modelo_idioma', md.idioma, 'dados', v_dados,
                            'arquivo_caminho', v_caminho, 'arquivo_mime', v_mime);
end $function$;

create or replace function public.wa_meta_receber(p_corpo text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions', 'pg_temp'
AS $function$
declare
  j jsonb; v_hash text; v_ev bigint; v_ja boolean;
  e jsonb; ch jsonb; v jsonb; m jsonb; s jsonb; d jsonb; ct jsonb; g jsonb;
  v_num uuid; v_tel text; v_bsuid text; v_nome text; v_usuario text; v_cont uuid; v_conv uuid; v_msg uuid;
  v_tipo text; v_texto text; v_leg text; v_ts timestamptz; v_ord int; v_gid text; v_autor text;
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
            when 'location' then coalesce(m->'location'->>'name', m->'location'->>'address', 'Localização')
            when 'contacts' then (select string_agg(x->'name'->>'formatted_name', ', ')
                                    from jsonb_array_elements(m->'contacts') x)
            when 'document' then m->'document'->>'filename'
            when 'unsupported' then 'mensagem nao suportada'
            when 'system' then m->'system'->>'body'
            else null end;
          v_leg := null;
          if jsonb_typeof(m->(m->>'type')) = 'object' then v_leg := m->(m->>'type')->>'caption'; end if;
          d := case m->>'type'
            when 'location' then m->'location'
            when 'contacts' then jsonb_build_object('nome', m->'contacts'->0->'name'->>'formatted_name',
                                                    'telefone', regexp_replace(coalesce(m->'contacts'->0->'phones'->0->>'phone', ''), '\D', '', 'g'))
            else null end;

          insert into wa_mensagem (conversa_id, id_whatsapp, direcao, tipo, texto, legenda, status,
                                   responder_a, ocorrido_em, autor_grupo, dados, encaminhada)
          values (v_conv, m->>'id', 'entrada', v_tipo, v_texto, v_leg, 'recebida',
                  m->'context'->>'id', v_ts, v_autor, d, coalesce((m->'context'->>'forwarded')::boolean, false))
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

    update wa_webhook_evento set processado_ok = true, processado_em = now(), erro = null, corpo = null,
                                 tinha_midia = v_tinha_midia
     where id = v_ev;
  exception when others then
    update wa_webhook_evento set processado_ok = false, processado_em = now(), erro = left(sqlerrm, 500)
     where id = v_ev;
    return jsonb_build_object('ok', false, 'erro', sqlerrm);
  end;

  return jsonb_build_object('ok', true, 'novas', v_novas, 'status', v_status, 'outros', v_outros,
                            'ignoradas', v_ign, 'baixar', wa_meta_midia_a_baixar(10));
end $function$;
