create or replace function public.wa_aviso_dados(p_mensagem uuid)
 returns jsonb language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
declare m wa_mensagem%rowtype; c wa_conversa%rowtype; k wa_contato%rowtype; md wa_midia%rowtype;
        v_dono uuid; v_txt text; v_dur text; v_nome text;
begin
  if auth.uid() is null or fiscal_nivel() is null then return null; end if;
  select * into m from wa_mensagem where id = p_mensagem;
  if m.id is null or m.direcao <> 'entrada' or m.tipo = 'sistema' or m.apagada_em is not null
     or coalesce(m.dados->>'origem', '') = 'backup' then return null; end if;
  select * into c from wa_conversa where id = m.conversa_id;
  if c.id is null or c.silenciada or c.estado = 'arquivada' then return null; end if;
  if not exists (select 1 from wa_numero n where n.id = c.numero_id and n.provedor = 'meta_cloud') then return null; end if;
  if not (c.grupo_meta_id is not null or wa_pode_ver_conversa(c.id)) then return null; end if;
  select * into k from wa_contato where id = c.contato_id;
  v_dono := case when c.e_grupo and c.grupo_meta_id is null then zz_grupo_dono(k.telefone_chave)
                 else wa_rota_dono(k.telefone_chave) end;
  if v_dono is distinct from auth.uid() and not (v_dono is null and fiscal_pode('wa_entrada_responder')) then
    return null;
  end if;
  select * into md from wa_midia where mensagem_id = m.id limit 1;
  v_dur := case when coalesce(md.duracao_s, 0) > 0
                then (md.duracao_s / 60)::int || ':' || lpad((md.duracao_s % 60)::int::text, 2, '0') end;
  v_txt := case m.tipo
    when 'texto' then m.texto
    when 'imagem' then 'Foto' || coalesce(' · ' || nullif(btrim(m.legenda), ''), '')
    when 'video' then 'Vídeo' || coalesce(' · ' || v_dur, '') || coalesce(' · ' || nullif(btrim(m.legenda), ''), '')
    when 'audio' then 'Áudio' || coalesce(' · ' || v_dur, '')
    when 'documento' then 'Arquivo · ' || coalesce(nullif(btrim(md.nome), ''), nullif(btrim(m.texto), ''), 'documento')
    when 'figurinha' then 'Figurinha'
    when 'local' then 'Localização' || coalesce(' · ' || nullif(btrim(m.texto), ''), '')
    when 'contato' then 'Contato · ' || coalesce(m.texto, '')
    else coalesce(nullif(btrim(m.texto), ''), 'Nova mensagem') end;
  if c.e_grupo and coalesce(btrim(m.autor_grupo), '') <> '' then v_txt := m.autor_grupo || ': ' || v_txt; end if;
  v_nome := coalesce(case when not c.e_grupo then zz_rota_provisoria_nome(k.telefone_chave) end,
                     nullif(btrim(c.contato_nome), ''), '+' || c.contato_telefone);
  return jsonb_build_object(
    'conversa_id', c.id, 'mensagem_id', m.id, 'nome', v_nome, 'texto', left(coalesce(v_txt, ''), 300),
    'em', m.ocorrido_em, 'janela_ate', c.janela_ate, 'grupo', c.e_grupo or c.grupo_meta_id is not null,
    'somente_leitura', c.e_grupo and c.grupo_meta_id is null,
    'pode_responder', not (c.e_grupo and c.grupo_meta_id is null) and fiscal_pode_enviar_contato(c.contato_id)
                      and not coalesce(k.bloqueado, false),
    'foto', k.foto_url);
end $function$;
revoke all on function public.wa_aviso_dados(uuid) from public, anon;
grant execute on function public.wa_aviso_dados(uuid) to authenticated;
