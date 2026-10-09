alter table public.wa_mensagem drop constraint if exists wa_mensagem_status_check;
do $$
declare c text;
begin
  for c in select conname from pg_constraint where conrelid = 'public.wa_mensagem'::regclass and contype = 'c'
            and pg_get_constraintdef(oid) ilike '%status%' loop
    execute format('alter table public.wa_mensagem drop constraint %I', c);
  end loop;
end $$;
alter table public.wa_mensagem add constraint wa_mensagem_status_check check (status = any (array[
  'rascunho','na_fila','enviando','aguardando','enviada','entregue','lida','falhou','incerto','nao_e_whatsapp','recebida']));

create or replace function public.wa_meta_envio_incerto(p_mensagem_id uuid, p_erro text)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare n int;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  update wa_mensagem set status = 'incerto', tentativas = tentativas + 1,
                         erro = left('sem confirmacao da Meta: pode ter sido enviada. ' || coalesce(p_erro, ''), 500)
   where id = p_mensagem_id and id_whatsapp is null and status in ('enviando', 'na_fila');
  get diagnostics n = row_count;
  return n = 1;
end $function$;
revoke all on function public.wa_meta_envio_incerto(uuid, text) from public, anon, authenticated;

do $$
declare d text;
  a text := '    if ex.conversa_id = p_conversa_id and (fiscal_e_servidor() or ex.autor_id = auth.uid()) then
      return jsonb_build_object(''ok'', true, ''repetida'', true, ''mensagem_id'', ex.id, ''status'', ex.status);';
  b text := '    if ex.conversa_id = p_conversa_id and (fiscal_e_servidor() or ex.autor_id = auth.uid()) then
      if ex.status = ''enviando'' and ex.id_whatsapp is null and ex.criado_em < now() - interval ''2 minutes'' then
        update wa_mensagem set status = ''incerto'', erro = ''sem confirmacao da Meta: pode ter sido enviada.'' where id = ex.id;
        ex.status := ''incerto'';
      end if;
      return jsonb_build_object(''ok'', true, ''repetida'', true, ''mensagem_id'', ex.id, ''status'', ex.status);';
begin
  d := pg_get_functiondef('public.wa_meta_preparar_envio'::regproc);
  if position('incerto' in d) = 0 then
    if position(a in d) = 0 then raise exception 'trecho de repetida nao encontrado'; end if;
    execute replace(d, a, b);
  end if;
end $$;

create or replace function public.wa_meta_resultado_envio(p_mensagem_id uuid, p_wamid text, p_erro_codigo integer default null, p_erro text default null)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_conv uuid; v_prev text; n int; p record; v_num uuid;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if coalesce(p_wamid, '') <> '' then
    update wa_mensagem set id_whatsapp = p_wamid, id_provedor = p_wamid,
                           status = case when status in ('enviando', 'incerto') then 'aguardando' else status end,
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
                           erro = left(case
                                         when p_erro_codigo = 131047 then '131047 fora da janela de 24h: so modelo aprovado'
                                         when p_erro_codigo in (130429, 131048) then p_erro_codigo || ' limite de envio da Meta: tente de novo em alguns minutos'
                                         when p_erro_codigo = 131056 then '131056 muitas mensagens seguidas para este cliente: aguarde um pouco'
                                         when p_erro_codigo in (190, 401) then p_erro_codigo || ' acesso a Meta recusado (token): avisar o gestor'
                                         else concat_ws(' ', p_erro_codigo::text, p_erro) end, 500)
     where id = p_mensagem_id
    returning conversa_id into v_conv;
    get diagnostics n = row_count;
    if p_erro_codigo in (190, 401) then
      select numero_id into v_num from wa_conversa where id = v_conv;
      if v_num is not null then
        insert into wa_saude (numero_id, ultimo_evento, motivo) values (v_num, 'token_recusado', left(coalesce(p_erro, ''), 500))
        on conflict (numero_id) do update set ultimo_evento = 'token_recusado', motivo = excluded.motivo, atualizado_em = now();
      end if;
    end if;
  end if;
  return n = 1;
end $function$;
