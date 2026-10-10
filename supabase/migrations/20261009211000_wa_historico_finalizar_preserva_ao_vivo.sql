create or replace function public.wa_historico_finalizar()
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_num uuid := wa_historico_numero(); v_conv int; v_rotas int := 0; r record; v_chave text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  perform set_config('wa.importando', '1', true);
  update wa_conversa c set ultima_em = u.ultima, primeiro_em = least(coalesce(c.primeiro_em, u.primeira), u.primeira),
         ultima_previa = u.previa,
         estado = case when c.estado = 'nova' and not u.ao_vivo then 'resolvida' else c.estado end,
         nao_lidas = case when u.ao_vivo then c.nao_lidas else 0 end, atualizado_em = now()
    from (select distinct on (m.conversa_id) m.conversa_id, m.ocorrido_em ultima,
                 min(m.ocorrido_em) over (partition by m.conversa_id) primeira,
                 bool_or(coalesce(m.dados->>'origem', '') <> 'backup') over (partition by m.conversa_id) ao_vivo,
                 left(coalesce(m.legenda, m.texto, '[' || m.tipo || ']'), 200) previa
            from wa_mensagem m join wa_conversa cc on cc.id = m.conversa_id
           where cc.numero_id = v_num
           order by m.conversa_id, m.ocorrido_em desc) u
   where c.id = u.conversa_id;
  get diagnostics v_conv = row_count;
  for r in select distinct ct.telefone_chave from wa_contato ct join wa_conversa cv on cv.contato_id = ct.id
            where cv.numero_id = v_num and not ct.e_grupo and ct.telefone_chave is not null
              and not exists (select 1 from wa_rota_numero rn where rn.telefone_chave = ct.telefone_chave) loop
    perform wa_rota_marcar_numero(r.telefone_chave);
    v_rotas := v_rotas + 1;
  end loop;
  if v_rotas > 0 then
    begin
      select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'bl_aviso_chave_interna';
      perform net.http_post(url := 'https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/bl-aviso',
        body := jsonb_build_object('acao', 'resolver'),
        headers := jsonb_build_object('Content-Type', 'application/json', 'x-chave-interna', v_chave));
    exception when others then raise warning 'pedir rota falhou: %', sqlerrm;
    end;
  end if;
  return jsonb_build_object('ok', true, 'conversas', v_conv, 'rotas', v_rotas);
end $function$;
revoke all on function public.wa_historico_finalizar() from public, anon, authenticated;
