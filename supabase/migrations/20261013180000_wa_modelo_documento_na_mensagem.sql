do $do$
declare d text; v_marca text := $m$p_tipo = 'template' and coalesce(p_arquivo->>'caminho', '')$m$;
begin
  d := pg_get_functiondef('public.wa_meta_preparar_envio(uuid,text,text,text,text,jsonb,text,jsonb)'::regprocedure);
  if position(v_marca in d) = 0 then
    d := replace(d, $a$  return jsonb_build_object('ok', true, 'mensagem_id', v_id, 'telefone', cv.contato_telefone,$a$,
                 $b$  if p_tipo = 'template' and coalesce(p_arquivo->>'caminho', '') like cv.id::text || '/saida/%'
     and p_arquivo->>'caminho' not like '%..%' then
    select o.metadata into v_meta from storage.objects o where o.bucket_id = 'wa-midia' and o.name = p_arquivo->>'caminho';
    if v_meta is not null then
      insert into wa_midia (mensagem_id, tipo, mimetype, nome, tamanho, caminho, estado)
      values (v_id, 'documento', lower(coalesce(v_meta->>'mimetype', 'application/pdf')),
              coalesce(nullif(btrim(p_arquivo->>'nome'), ''), 'documento.pdf'), coalesce((v_meta->>'size')::bigint, 0),
              p_arquivo->>'caminho', 'guardado');
    end if;
  end if;
  return jsonb_build_object('ok', true, 'mensagem_id', v_id, 'telefone', cv.contato_telefone,$b$);
    if position(v_marca in d) = 0 then raise exception 'trecho nao aplicado'; end if;
    execute d;
  end if;
end $do$;

insert into public.wa_midia (mensagem_id, tipo, mimetype, nome, tamanho, caminho, estado)
select m.id, 'documento', lower(coalesce(o.metadata->>'mimetype', 'application/pdf')), 'documento.pdf',
       coalesce((o.metadata->>'size')::bigint, 0), o.name, 'guardado'
  from public.wa_mensagem m
  join storage.objects o on o.bucket_id = 'wa-midia' and o.name = m.conversa_id::text || '/saida/' || m.id_local || '.pdf'
 where m.dados ? 'modelo'
   and not exists (select 1 from public.wa_midia x where x.mensagem_id = m.id);
