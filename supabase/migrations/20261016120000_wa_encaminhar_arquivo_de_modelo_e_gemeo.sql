create or replace function public.wa_encaminhar_preparar(p_mensagem uuid, p_destino uuid)
 returns jsonb language plpgsql security definer set search_path to 'public','pg_temp'
as $function$
declare m wa_mensagem%rowtype; md wa_midia%rowtype; v_tipo text; v_cam text;
begin
  select * into m from wa_mensagem where id = p_mensagem and apagada_em is null;
  if m.id is null or not wa_pode_ver_conversa(m.conversa_id) then
    return jsonb_build_object('ok', false, 'erro', 'Mensagem nao encontrada.');
  end if;
  if not wa_pode_agir_conversa(p_destino) then
    return jsonb_build_object('ok', false, 'erro', 'Sem permissao na conversa de destino.');
  end if;
  select * into md from wa_midia where mensagem_id = m.id limit 1;
  v_tipo := m.tipo;
  if v_tipo not in ('imagem', 'audio', 'video', 'documento') and md.tipo in ('imagem', 'audio', 'video', 'documento') then
    v_tipo := md.tipo;
  end if;
  if v_tipo in ('imagem', 'audio', 'video', 'documento') then
    v_cam := case when md.estado = 'guardado' and md.caminho is not null and md.caminho !~ '^https?://' then md.caminho end;
    if v_cam is null and md.sha256 is not null then
      select g.caminho into v_cam from wa_midia g
       where g.sha256 = md.sha256 and g.estado = 'guardado' and g.caminho is not null and g.caminho !~ '^https?://'
       order by g.criado_em desc limit 1;
    end if;
    if v_cam is null then
      return jsonb_build_object('ok', false, 'erro', 'Este arquivo nao foi recuperado do WhatsApp antigo e nao pode ser encaminhado.');
    end if;
  end if;
  return jsonb_build_object('ok', true, 'tipo', v_tipo, 'texto', case when v_tipo <> m.tipo then null else m.texto end,
                            'legenda', case when v_tipo <> m.tipo then null else m.legenda end,
                            'dados', m.dados, 'caminho', v_cam, 'nome', md.nome, 'mime', md.mimetype);
end $function$;
