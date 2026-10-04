-- correcoes da auditoria (Prumo F2, F7, F11, F14)
drop function if exists public.wa_meta_preparar_envio(uuid, text, text, text, text, jsonb, text);

create or replace function public.wa_meta_preparar_envio(
  p_conversa_id uuid, p_id_local text, p_tipo text, p_texto text default null,
  p_legenda text default null, p_arquivo jsonb default null, p_responder_a text default null,
  p_modelo jsonb default null)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'storage', 'pg_temp'
as $$
declare cv wa_conversa%rowtype; nm wa_numero%rowtype; v_id uuid; v_ult timestamptz; ex wa_mensagem%rowtype;
        v_mime text; v_tam bigint; v_lim bigint; v_nome text; v_caminho text; v_obj text; v_meta jsonb; md wa_modelo%rowtype;
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
          case when p_tipo = 'template' then coalesce(p_texto, '[modelo ' || md.nome || ']') else p_texto end,
          p_legenda, 'enviando', auth.uid(), p_responder_a, now())
  returning id into v_id;

  if p_tipo in ('imagem', 'audio', 'video', 'documento') then
    insert into wa_midia (mensagem_id, tipo, mimetype, nome, tamanho, caminho, estado)
    values (v_id, p_tipo, v_mime, p_arquivo->>'nome', v_tam, v_caminho, 'guardado');
  end if;

  return jsonb_build_object('ok', true, 'mensagem_id', v_id, 'telefone', cv.contato_telefone,
                            'bsuid', cv.contato_bsuid, 'phone_number_id', nm.identificador,
                            'modelo_nome', md.nome, 'modelo_idioma', md.idioma,
                            'arquivo_caminho', v_caminho, 'arquivo_mime', v_mime);
end $$;
revoke all on function public.wa_meta_preparar_envio(uuid, text, text, text, text, jsonb, text, jsonb) from public, anon;
grant execute on function public.wa_meta_preparar_envio(uuid, text, text, text, text, jsonb, text, jsonb) to authenticated, service_role;

-- corpo do aviso so fica enquanto nao foi processado
do $do$
declare d text;
begin
  d := pg_get_functiondef('public.wa_meta_receber(text)'::regprocedure);
  d := replace(d, 'update wa_webhook_evento set processado_ok = true, processado_em = now(), erro = null,',
                  'update wa_webhook_evento set processado_ok = true, processado_em = now(), erro = null, corpo = null,');
  if d !~ 'erro = null, corpo = null' then raise exception 'wa_meta_receber nao foi ajustada'; end if;
  execute d;
end $do$;
