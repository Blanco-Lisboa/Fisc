create table if not exists public.wa_grupo_membro_historico (
  conversa_id uuid not null references public.wa_conversa(id) on delete cascade,
  telefone text not null,
  admin boolean not null default false,
  entrou_em timestamptz,
  primary key (conversa_id, telefone)
);
alter table public.wa_grupo_membro_historico enable row level security;
drop policy if exists wa_grupo_membro_historico_ler on public.wa_grupo_membro_historico;
create policy wa_grupo_membro_historico_ler on public.wa_grupo_membro_historico for select to authenticated
  using (exists (select 1 from wa_conversa c where c.id = conversa_id and c.contato_id is not null and fiscal_pode_ver_contato(c.contato_id)));
revoke insert, update, delete on public.wa_grupo_membro_historico from anon, authenticated;

create or replace function public.wa_importando()
 returns boolean language sql stable set search_path to 'pg_catalog'
as $function$ select coalesce(current_setting('wa.importando', true), '') = '1' $function$;

create or replace function public.wa_contato_rota_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_chave text;
begin
  if new.telefone_chave is null or new.e_grupo or wa_importando() then return null; end if;
  if exists (select 1 from wa_rota_numero where telefone_chave = new.telefone_chave) then return null; end if;
  perform wa_rota_marcar_numero(new.telefone_chave);
  begin
    select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'bl_aviso_chave_interna';
    perform net.http_post(url := 'https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/bl-aviso',
      body := jsonb_build_object('acao', 'resolver'),
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-chave-interna', v_chave));
  exception when others then raise warning 'pedir rota falhou: %', sqlerrm;
  end;
  return null;
end $function$;

create or replace function public.wa_mensagem_janela_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if wa_importando() then return null; end if;
  if new.direcao = 'entrada' and new.tipo <> 'sistema' then
    perform wa_conversa_abrir_janela(new.conversa_id, coalesce(new.ocorrido_em, now()));
  end if;
  return null;
end $function$;

create or replace function public.wa_midia_avisar_transcricao()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_chave text;
begin
  if wa_importando() then return null; end if;
  begin
    if new.tipo = 'audio' and new.estado = 'guardado' and new.transcricao is null
       and exists (select 1 from wa_mensagem w where w.id = new.mensagem_id and w.direcao = 'entrada') then
      select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'wa_transcrever_chave';
      perform net.http_post(
        url := 'https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/wa-transcrever',
        body := jsonb_build_object('midia_id', new.id),
        headers := jsonb_build_object('Content-Type', 'application/json', 'x-chave-interna', v_chave));
    end if;
  exception when others then
    raise warning 'aviso de transcricao falhou: %', sqlerrm;
  end;
  return null;
end $function$;

create or replace function public.wa_historico_chave_ok(p_chave text)
 returns boolean language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
declare v text;
begin
  if not fiscal_e_servidor() then return false; end if;
  select decrypted_secret into v from vault.decrypted_secrets where name = 'wa_historico_chave_hash';
  return v is not null and p_chave is not null and length(p_chave) >= 32
     and encode(extensions.digest(p_chave, 'sha256'), 'hex') = v;
end $function$;
revoke all on function public.wa_historico_chave_ok(text) from public, anon, authenticated;

create or replace function public.wa_historico_numero()
 returns uuid language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$ select id from wa_numero where telefone = '5511966587101' $function$;
revoke all on function public.wa_historico_numero() from public, anon, authenticated;

create or replace function public.wa_historico_lote(p_lote jsonb)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare
  v_num uuid := wa_historico_numero(); c jsonb; m jsonb; v_tel text; v_contato uuid; v_conv uuid; v_msg uuid; v_midia uuid;
  v_novas int := 0; v_repetidas int := 0; v_midias jsonb := '[]'; v_grupo boolean; v_mid jsonb;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if v_num is null then raise exception 'numero do Fiscal ausente'; end if;
  perform set_config('wa.importando', '1', true);

  for c in select * from jsonb_array_elements(coalesce(p_lote, '[]')) loop
    v_grupo := coalesce((c->>'e_grupo')::boolean, false);
    v_tel := nullif(regexp_replace(coalesce(c->>'telefone', ''), '\D', '', 'g'), '');
    if v_tel is null then continue; end if;
    if v_grupo then
      select id into v_contato from wa_contato where telefone = v_tel;
      if v_contato is null then
        insert into wa_contato (telefone, nome_whatsapp, e_grupo) values (v_tel, nullif(c->>'nome', ''), true) returning id into v_contato;
      end if;
      select id into v_conv from wa_conversa where numero_id = v_num and contato_id = v_contato and estado <> 'arquivada' limit 1;
      if v_conv is null then
        insert into wa_conversa (numero_id, contato_id, contato_telefone, contato_nome, e_grupo, estado, primeiro_em)
        values (v_num, v_contato, v_tel, nullif(c->>'nome', ''), true, 'resolvida', to_timestamp(nullif(c->>'criado_ms', '')::bigint / 1000.0))
        returning id into v_conv;
      end if;
      insert into wa_grupo_membro_historico (conversa_id, telefone, admin, entrou_em)
      select v_conv, x->>'telefone', coalesce((x->>'admin')::boolean, false), to_timestamp(nullif(x->>'entrou_ms', '')::bigint / 1000.0)
        from jsonb_array_elements(coalesce(c->'membros', '[]')) x where nullif(x->>'telefone', '') is not null
      on conflict (conversa_id, telefone) do update set admin = excluded.admin, entrou_em = coalesce(excluded.entrou_em, wa_grupo_membro_historico.entrou_em);
    else
      if length(v_tel) < 10 or length(v_tel) > 15 then continue; end if;
      v_contato := wa_meta_contato(v_tel, null, nullif(c->>'nome', ''), null);
      v_conv := wa_meta_conversa(v_num, v_contato, v_tel, null, nullif(c->>'nome', ''));
    end if;

    for m in select * from jsonb_array_elements(coalesce(c->'mensagens', '[]')) loop
      insert into wa_mensagem (conversa_id, id_whatsapp, direcao, tipo, texto, legenda, status, responder_a, autor_grupo,
                               reacao, reacao_nossa, apagada_em, editada_em, encaminhada, favorita, ocorrido_em, enviado_em, dados)
      values (v_conv, 'imp:' || (m->>'id'), case when (m->>'de_mim')::boolean then 'saida' else 'entrada' end,
              coalesce(m->>'tipo', 'texto'), m->>'texto', m->>'legenda',
              coalesce(m->>'status', case when (m->>'de_mim')::boolean then 'enviada' else 'recebida' end),
              case when nullif(m->>'responde', '') is not null then 'imp:' || (m->>'responde') end,
              nullif(m->>'autor', ''), nullif(m->>'reacao', ''), nullif(m->>'reacao_nossa', ''),
              to_timestamp(nullif(m->>'apagada_ms', '')::bigint / 1000.0), to_timestamp(nullif(m->>'editada_ms', '')::bigint / 1000.0),
              coalesce((m->>'encaminhada')::boolean, false), coalesce((m->>'favorita')::boolean, false),
              to_timestamp((m->>'ts_ms')::bigint / 1000.0),
              case when (m->>'de_mim')::boolean then to_timestamp((m->>'ts_ms')::bigint / 1000.0) end,
              jsonb_strip_nulls(coalesce(m->'dados', '{}') || jsonb_build_object('origem', 'backup')))
      on conflict (conversa_id, id_whatsapp) where id_whatsapp is not null do nothing
      returning id into v_msg;
      if v_msg is null then v_repetidas := v_repetidas + 1; continue; end if;
      v_novas := v_novas + 1;

      v_mid := m->'midia';
      if v_mid is not null then
        insert into wa_midia (mensagem_id, tipo, mimetype, nome, tamanho, sha256, duracao_s, estado, ultimo_erro)
        values (v_msg, coalesce(m->>'tipo', 'documento'), v_mid->>'mime', v_mid->>'nome', nullif(v_mid->>'tamanho', '')::bigint,
                v_mid->>'sha256', nullif(v_mid->>'duracao', '')::int,
                case when coalesce((v_mid->>'tem_arquivo')::boolean, false) then 'pendente' else 'sem_arquivo' end,
                case when coalesce((v_mid->>'tem_arquivo')::boolean, false) then null else 'arquivo ausente no backup' end)
        returning id into v_midia;
        if coalesce((v_mid->>'tem_arquivo')::boolean, false) then
          v_midias := v_midias || jsonb_build_object('chave', v_mid->>'chave', 'midia_id', v_midia,
                        'caminho', v_conv || '/historico/' || v_midia || coalesce('.' || nullif(v_mid->>'ext', ''), ''));
        end if;
      end if;
    end loop;
  end loop;

  return jsonb_build_object('ok', true, 'novas', v_novas, 'repetidas', v_repetidas, 'midias', v_midias);
end $function$;
revoke all on function public.wa_historico_lote(jsonb) from public, anon, authenticated;

create or replace function public.wa_historico_midia_ok(p_itens jsonb)
 returns int language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare n int;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  perform set_config('wa.importando', '1', true);
  update wa_midia w set estado = 'guardado', caminho = x->>'caminho', tamanho = coalesce(nullif(x->>'tamanho', '')::bigint, w.tamanho), baixado_em = now()
    from jsonb_array_elements(coalesce(p_itens, '[]')) x
   where w.id = (x->>'midia_id')::uuid and w.estado = 'pendente' and w.id_externo is null and nullif(x->>'caminho', '') is not null;
  get diagnostics n = row_count;
  return n;
end $function$;
revoke all on function public.wa_historico_midia_ok(jsonb) from public, anon, authenticated;

create or replace function public.wa_historico_midia_falhou(p_midia_id uuid, p_erro text)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare n int;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  perform set_config('wa.importando', '1', true);
  update wa_midia set estado = 'falhou', ultimo_erro = left(p_erro, 500) where id = p_midia_id and estado = 'pendente';
  get diagnostics n = row_count;
  return n = 1;
end $function$;
revoke all on function public.wa_historico_midia_falhou(uuid, text) from public, anon, authenticated;

create or replace function public.wa_historico_finalizar()
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_num uuid := wa_historico_numero(); v_conv int; v_rotas int := 0; r record; v_chave text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  perform set_config('wa.importando', '1', true);
  update wa_conversa c set ultima_em = u.ultima, primeiro_em = least(coalesce(c.primeiro_em, u.primeira), u.primeira),
         ultima_previa = u.previa, estado = case when c.estado = 'nova' then 'resolvida' else c.estado end, nao_lidas = 0, atualizado_em = now()
    from (select distinct on (m.conversa_id) m.conversa_id, m.ocorrido_em ultima,
                 min(m.ocorrido_em) over (partition by m.conversa_id) primeira,
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
