-- importacao do historico do celular (backup do WhatsApp Business)
create or replace function public.wa_importar_lote(p_telefone_numero text, p_lote jsonb)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_num uuid; c jsonb; m jsonb; v_tel text; v_conv uuid; v_msg uuid; v_midia uuid;
  v_novas int := 0; v_repetidas int := 0; v_midias jsonb := '[]'::jsonb; v_ultima timestamptz; v_prev text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  select id into v_num from wa_numero
   where provedor = 'meta_cloud' and ativo and telefone = regexp_replace(coalesce(p_telefone_numero, ''), '\D', '', 'g');
  if v_num is null then raise exception 'numero do Fiscal ainda nao ligado na Meta'; end if;

  for c in select * from jsonb_array_elements(coalesce(p_lote, '[]')) loop
    v_tel := nullif(regexp_replace(coalesce(c->>'telefone', ''), '\D', '', 'g'), '');
    if v_tel is null or length(v_tel) < 10 or length(v_tel) > 15 then continue; end if;
    v_conv := wa_meta_conversa(v_num, wa_meta_contato(v_tel, null, nullif(c->>'nome', ''), null), v_tel, null, nullif(c->>'nome', ''));

    for m in select * from jsonb_array_elements(coalesce(c->'mensagens', '[]')) loop
      insert into wa_mensagem (conversa_id, id_whatsapp, direcao, tipo, texto, legenda, status, responder_a, ocorrido_em)
      values (v_conv, 'imp:' || (m->>'id'), case when (m->>'de_mim')::boolean then 'saida' else 'entrada' end,
              coalesce(m->>'tipo', 'texto'), m->>'texto', m->>'legenda',
              case when (m->>'de_mim')::boolean then 'enviada' else 'recebida' end,
              case when m->>'responde' is not null then 'imp:' || (m->>'responde') end,
              to_timestamp((m->>'ts_ms')::bigint / 1000.0))
      on conflict (conversa_id, id_whatsapp) where id_whatsapp is not null do nothing
      returning id into v_msg;
      if v_msg is null then v_repetidas := v_repetidas + 1; continue; end if;
      v_novas := v_novas + 1;

      if m ? 'midia' then
        insert into wa_midia (mensagem_id, tipo, mimetype, nome, tamanho, estado)
        values (v_msg, coalesce(m->>'tipo', 'documento'), m->'midia'->>'mime', m->'midia'->>'nome',
                nullif(m->'midia'->>'tamanho', '')::bigint, 'pendente')
        returning id into v_midia;
        v_midias := v_midias || jsonb_build_object('chave', m->'midia'->>'chave', 'midia_id', v_midia,
                      'caminho', v_conv || '/historico/' || v_midia || coalesce('.' || nullif(m->'midia'->>'ext', ''), ''));
      end if;
    end loop;

    select max(ocorrido_em) into v_ultima from wa_mensagem where conversa_id = v_conv;
    select left(coalesce(legenda, texto, '[' || tipo || ']'), 200) into v_prev
      from wa_mensagem where conversa_id = v_conv order by ocorrido_em desc limit 1;
    update wa_conversa set ultima_em = greatest(coalesce(ultima_em, v_ultima), v_ultima),
                           ultima_previa = coalesce(ultima_previa, v_prev), atualizado_em = now()
     where id = v_conv;
  end loop;

  return jsonb_build_object('ok', true, 'novas', v_novas, 'repetidas', v_repetidas, 'midias', v_midias);
end $$;

create or replace function public.wa_importar_midia_ok(p_midia_id uuid, p_caminho text, p_tamanho bigint)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare n int;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  update wa_midia set estado = 'guardado', caminho = p_caminho, tamanho = coalesce(p_tamanho, tamanho), baixado_em = now()
   where id = p_midia_id and estado = 'pendente' and id_externo is null;
  get diagnostics n = row_count;
  return n = 1;
end $$;

revoke all on function public.wa_importar_lote(text, jsonb) from public, anon, authenticated;
revoke all on function public.wa_importar_midia_ok(uuid, text, bigint) from public, anon, authenticated;
grant execute on function public.wa_importar_lote(text, jsonb) to service_role;
grant execute on function public.wa_importar_midia_ok(uuid, text, bigint) to service_role;
