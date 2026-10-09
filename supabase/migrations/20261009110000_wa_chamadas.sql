create table if not exists public.wa_chamada (
  id uuid primary key default gen_random_uuid(),
  wacid text unique,
  numero_id uuid not null references public.wa_numero(id) on delete restrict,
  contato_id uuid references public.wa_contato(id) on delete restrict,
  conversa_id uuid references public.wa_conversa(id) on delete restrict,
  bsuid text,
  direcao text not null check (direcao in ('cliente', 'empresa')),
  midia text not null default 'audio' check (midia in ('audio', 'video')),
  estado text not null check (estado in ('tocando', 'chamando', 'pre_aceita', 'em_curso', 'encerrada', 'nao_atendida', 'rejeitada', 'falhou')),
  atendente_id uuid references public.fiscal_usuario(id) on delete restrict,
  oferta_sdp text,
  resposta_sdp text,
  status_meta text,
  inicio_em timestamptz,
  fim_em timestamptz,
  duracao_s integer,
  erro text,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
create index if not exists wa_chamada_conversa_ix on public.wa_chamada (conversa_id, criado_em desc);
create index if not exists wa_chamada_contato_ix on public.wa_chamada (contato_id);
create index if not exists wa_chamada_atendente_ix on public.wa_chamada (atendente_id);
create index if not exists wa_chamada_numero_ix on public.wa_chamada (numero_id);
create index if not exists wa_chamada_ativa_ix on public.wa_chamada (estado) where estado in ('tocando', 'chamando', 'pre_aceita', 'em_curso');

create table if not exists public.wa_chamada_evento (
  id bigint generated always as identity primary key,
  chamada_id uuid references public.wa_chamada(id) on delete restrict,
  wacid text,
  tipo text not null,
  dados jsonb,
  ocorrido_em timestamptz,
  recebido_em timestamptz not null default now()
);
create index if not exists wa_chamada_evento_chamada_ix on public.wa_chamada_evento (chamada_id);

create table if not exists public.wa_chamada_permissao (
  contato_id uuid primary key references public.wa_contato(id) on delete restrict,
  situacao text not null check (situacao in ('sem', 'temporaria', 'permanente', 'recusada')),
  expira_em timestamptz,
  origem text,
  pedido_wamid text,
  resposta_wamid text,
  nao_atendidas_seguidas integer not null default 0,
  atualizado_em timestamptz not null default now()
);

alter table public.wa_chamada enable row level security;
alter table public.wa_chamada_evento enable row level security;
alter table public.wa_chamada_permissao enable row level security;
revoke all on public.wa_chamada, public.wa_chamada_evento, public.wa_chamada_permissao from anon, authenticated;
grant select on public.wa_chamada, public.wa_chamada_permissao to authenticated;
create policy wa_chamada_ler on public.wa_chamada for select to authenticated
  using (fiscal_nivel() is not null and conversa_id is not null and wa_pode_ver_conversa(conversa_id));
create policy wa_chamada_permissao_ler on public.wa_chamada_permissao for select to authenticated
  using (fiscal_nivel() is not null and fiscal_pode_ver_contato(contato_id));

insert into public.fiscal_permissao (codigo, titulo, descricao, ordem) values
 ('wa_ligacao_atender', 'Atender ligação do WhatsApp', 'Atender ligação de voz que o cliente faz pelo WhatsApp oficial.', 11),
 ('wa_ligacao_fazer', 'Ligar para o cliente pelo WhatsApp', 'Fazer ligação de voz para o cliente e pedir permissão para ligar.', 12)
on conflict (codigo) do update set titulo = excluded.titulo, descricao = excluded.descricao, ordem = excluded.ordem;
insert into public.fiscal_nivel_permissao (nivel, permissao)
select n, 'wa_ligacao_atender' from unnest(array['colaborador', 'assistente', 'gerente']) n
union all select n, 'wa_ligacao_fazer' from unnest(array['assistente', 'gerente']) n
on conflict do nothing;

create or replace function public.wa_meta_chamada_evento(v jsonb, p_numero uuid, c jsonb)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_ch wa_chamada%rowtype; v_tel text; v_bsuid text; v_cont uuid; v_conv uuid; v_ev text; v_st text; v_ts timestamptz;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  v_ev := lower(coalesce(c->>'event', ''));
  v_ts := to_timestamp(nullif(c->>'timestamp', '')::bigint);
  select * into v_ch from wa_chamada where wacid = c->>'id';

  if v_ev = 'connect' and v_ch.id is null and upper(coalesce(c->>'direction', '')) <> 'BUSINESS_INITIATED' then
    v_tel := nullif(regexp_replace(coalesce(c->>'from', ''), '\D', '', 'g'), '');
    v_bsuid := nullif(c->>'from_user_id', '');
    if v_tel is null and v_bsuid is null then raise exception 'ligacao sem numero e sem bsuid'; end if;
    v_cont := wa_meta_contato(v_tel, v_bsuid, null, null);
    v_conv := wa_meta_conversa(p_numero, v_cont, v_tel, v_bsuid, null);
    insert into wa_chamada (wacid, numero_id, contato_id, conversa_id, bsuid, direcao, estado, oferta_sdp, inicio_em)
    values (c->>'id', p_numero, v_cont, v_conv, v_bsuid, 'cliente', 'tocando', c->'session'->>'sdp', v_ts)
    returning * into v_ch;
  elsif v_ev = 'connect' and v_ch.id is not null then
    update wa_chamada set resposta_sdp = coalesce(c->'session'->>'sdp', resposta_sdp), atualizado_em = now() where id = v_ch.id;
  elsif v_ev = 'terminate' and v_ch.id is not null then
    v_st := upper(coalesce(c->>'status', ''));
    update wa_chamada set
      estado = case when v_st = 'COMPLETED' and (estado in ('em_curso', 'pre_aceita') or coalesce((c->>'duration')::int, 0) > 0) then 'encerrada'
                    when estado in ('tocando', 'chamando') then 'nao_atendida'
                    when estado = 'rejeitada' then 'rejeitada'
                    when v_st = 'FAILED' then 'falhou'
                    else 'encerrada' end,
      status_meta = v_st,
      inicio_em = coalesce(to_timestamp(nullif(c->>'start_time', '')::bigint), inicio_em),
      fim_em = coalesce(to_timestamp(nullif(c->>'end_time', '')::bigint), v_ts, now()),
      duracao_s = coalesce(nullif(c->>'duration', '')::int, duracao_s),
      oferta_sdp = null, resposta_sdp = null, atualizado_em = now()
     where id = v_ch.id
     returning * into v_ch;
    if v_ch.direcao = 'empresa' and v_ch.contato_id is not null then
      insert into wa_chamada_permissao (contato_id, situacao, nao_atendidas_seguidas)
      values (v_ch.contato_id, 'sem', case when v_ch.estado = 'nao_atendida' then 1 else 0 end)
      on conflict (contato_id) do update
        set nao_atendidas_seguidas = case when v_ch.estado = 'nao_atendida' then wa_chamada_permissao.nao_atendidas_seguidas + 1 else 0 end,
            situacao = case when v_ch.estado = 'nao_atendida' and wa_chamada_permissao.nao_atendidas_seguidas + 1 >= 4 then 'sem' else wa_chamada_permissao.situacao end,
            atualizado_em = now();
    end if;
  end if;

  insert into wa_chamada_evento (chamada_id, wacid, tipo, dados, ocorrido_em)
  values (v_ch.id, c->>'id', coalesce(nullif(v_ev, ''), 'desconhecido'), c - 'session', v_ts);
end $function$;
revoke all on function public.wa_meta_chamada_evento(jsonb, uuid, jsonb) from public, anon, authenticated;

create or replace function public.wa_meta_chamada_status(s jsonb)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_st text := upper(coalesce(s->>'status', ''));
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  update wa_chamada set estado = case v_st when 'ACCEPTED' then 'em_curso' when 'REJECTED' then 'rejeitada' else estado end,
                        atualizado_em = now()
   where wacid = s->>'id' and estado in ('chamando', 'pre_aceita', 'tocando');
  insert into wa_chamada_evento (chamada_id, wacid, tipo, dados, ocorrido_em)
  values ((select id from wa_chamada where wacid = s->>'id'), s->>'id', 'status_' || lower(v_st), s,
          to_timestamp(nullif(s->>'timestamp', '')::bigint));
end $function$;
revoke all on function public.wa_meta_chamada_status(jsonb) from public, anon, authenticated;

create or replace function public.wa_meta_permissao_resposta(p_contato uuid, p_msg jsonb)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare r jsonb := p_msg->'interactive'->'call_permission_reply';
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if r is null or p_contato is null then return; end if;
  insert into wa_chamada_permissao (contato_id, situacao, expira_em, origem, pedido_wamid, resposta_wamid)
  values (p_contato,
          case when r->>'response' = 'accept' then case when (r->>'is_permanent')::boolean then 'permanente' else 'temporaria' end else 'recusada' end,
          to_timestamp(nullif(r->>'expiration_timestamp', '')::bigint), r->>'response_source',
          p_msg->'context'->>'id', p_msg->>'id')
  on conflict (contato_id) do update
    set situacao = excluded.situacao, expira_em = excluded.expira_em, origem = excluded.origem,
        pedido_wamid = coalesce(excluded.pedido_wamid, wa_chamada_permissao.pedido_wamid),
        resposta_wamid = excluded.resposta_wamid, nao_atendidas_seguidas = 0, atualizado_em = now();
end $function$;
revoke all on function public.wa_meta_permissao_resposta(uuid, jsonb) from public, anon, authenticated;

create or replace function public.wa_chamada_assumir(p_chamada uuid)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v wa_chamada%rowtype;
begin
  if not fiscal_pode('wa_ligacao_atender') then return jsonb_build_object('ok', false, 'erro', 'Sem permissao para atender ligacao.'); end if;
  select * into v from wa_chamada where id = p_chamada for update;
  if v.id is null or v.conversa_id is null or not wa_pode_agir_conversa(v.conversa_id) then
    return jsonb_build_object('ok', false, 'erro', 'Ligacao nao encontrada.');
  end if;
  if v.estado <> 'tocando' then return jsonb_build_object('ok', false, 'erro', 'A ligacao nao esta mais tocando.'); end if;
  if v.atendente_id is not null and v.atendente_id <> auth.uid() then
    return jsonb_build_object('ok', false, 'erro', 'Outra pessoa ja atendeu.');
  end if;
  update wa_chamada set atendente_id = auth.uid(), atualizado_em = now() where id = v.id;
  return jsonb_build_object('ok', true, 'chamada_id', v.id, 'oferta_sdp', v.oferta_sdp);
end $function$;
revoke all on function public.wa_chamada_assumir(uuid) from public, anon;
grant execute on function public.wa_chamada_assumir(uuid) to authenticated;

create or replace function public.wa_chamada_preparar(p_acao text, p_chamada uuid, p_conversa uuid default null)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v wa_chamada%rowtype; cv wa_conversa%rowtype; nm wa_numero%rowtype; k wa_contato%rowtype; pm wa_chamada_permissao%rowtype; v_id uuid;
begin
  if fiscal_nivel() is null then return jsonb_build_object('ok', false, 'erro', 'Usuario sem cadastro no Fiscal.'); end if;
  if p_acao = 'connect' then
    if not fiscal_pode('wa_ligacao_fazer') then return jsonb_build_object('ok', false, 'erro', 'Sem permissao para ligar.'); end if;
    select * into cv from wa_conversa where id = p_conversa;
    if cv.id is null or cv.grupo_meta_id is not null or not wa_pode_agir_conversa(cv.id) then
      return jsonb_build_object('ok', false, 'erro', 'Conversa nao encontrada.');
    end if;
    select * into k from wa_contato where id = cv.contato_id;
    select * into pm from wa_chamada_permissao where contato_id = cv.contato_id;
    if pm.contato_id is null or pm.situacao not in ('temporaria', 'permanente')
       or (pm.situacao = 'temporaria' and pm.expira_em is not null and pm.expira_em < now()) then
      return jsonb_build_object('ok', false, 'erro', 'O cliente ainda nao deu permissao para ligacao.');
    end if;
    if exists (select 1 from wa_chamada where conversa_id = cv.id and estado in ('tocando', 'chamando', 'pre_aceita', 'em_curso')) then
      return jsonb_build_object('ok', false, 'erro', 'Ja existe uma ligacao em andamento com este cliente.');
    end if;
    select * into nm from wa_numero where id = cv.numero_id;
    insert into wa_chamada (numero_id, contato_id, conversa_id, bsuid, direcao, estado, atendente_id)
    values (cv.numero_id, cv.contato_id, cv.id, k.bsuid, 'empresa', 'chamando', auth.uid())
    returning id into v_id;
    return jsonb_build_object('ok', true, 'chamada_id', v_id, 'phone_number_id', nm.identificador,
                              'telefone', k.telefone, 'bsuid', k.bsuid);
  end if;

  if p_acao not in ('pre_accept', 'accept', 'reject', 'terminate') then
    return jsonb_build_object('ok', false, 'erro', 'Acao invalida.');
  end if;
  select * into v from wa_chamada where id = p_chamada;
  if v.id is null or v.wacid is null then return jsonb_build_object('ok', false, 'erro', 'Ligacao nao encontrada.'); end if;
  if v.atendente_id is distinct from auth.uid() and not (p_acao = 'reject' and wa_pode_agir_conversa(v.conversa_id)) then
    return jsonb_build_object('ok', false, 'erro', 'Esta ligacao esta com outra pessoa.');
  end if;
  if p_acao in ('pre_accept', 'accept') and v.estado not in ('tocando', 'pre_aceita') then
    return jsonb_build_object('ok', false, 'erro', 'A ligacao nao esta mais tocando.');
  end if;
  if v.estado in ('encerrada', 'nao_atendida', 'rejeitada', 'falhou') then
    return jsonb_build_object('ok', false, 'erro', 'A ligacao ja terminou.');
  end if;
  select * into nm from wa_numero where id = v.numero_id;
  return jsonb_build_object('ok', true, 'chamada_id', v.id, 'wacid', v.wacid, 'phone_number_id', nm.identificador);
end $function$;
revoke all on function public.wa_chamada_preparar(text, uuid, uuid) from public, anon;
grant execute on function public.wa_chamada_preparar(text, uuid, uuid) to authenticated;

create or replace function public.wa_chamada_resultado(p_chamada uuid, p_acao text, p_ok boolean, p_wacid text default null, p_erro text default null)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare n int;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  update wa_chamada set
    wacid = coalesce(wacid, p_wacid),
    estado = case
      when not p_ok and p_acao = 'connect' then 'falhou'
      when not p_ok then estado
      when p_acao = 'pre_accept' then 'pre_aceita'
      when p_acao = 'accept' then 'em_curso'
      when p_acao = 'reject' then 'rejeitada'
      when p_acao = 'terminate' then 'encerrada'
      else estado end,
    fim_em = case when p_ok and p_acao in ('reject', 'terminate') then coalesce(fim_em, now()) else fim_em end,
    oferta_sdp = case when p_ok and p_acao in ('accept', 'reject', 'terminate') then null else oferta_sdp end,
    erro = case when p_ok then erro else left(p_erro, 500) end,
    atualizado_em = now()
   where id = p_chamada;
  get diagnostics n = row_count;
  insert into wa_chamada_evento (chamada_id, wacid, tipo, dados)
  values (p_chamada, p_wacid, 'api_' || p_acao, jsonb_build_object('ok', p_ok, 'erro', p_erro));
  return n = 1;
end $function$;
revoke all on function public.wa_chamada_resultado(uuid, text, boolean, text, text) from public, anon, authenticated;

do $$ begin
  begin alter publication supabase_realtime add table public.wa_chamada; exception when duplicate_object then null; end;
end $$;

do $$
declare d text;
  a1 text := '        if ch->>''field'' is distinct from ''messages'' then';
  b1 text := '        if ch->>''field'' = ''calls'' then
          v_num := null;
          select id into v_num from wa_numero
           where provedor = ''meta_cloud'' and identificador = v->''metadata''->>''phone_number_id'' and ativo;
          if v_num is null then
            insert into wa_webhook_falha (evento_id, campo, referencia, erro, trecho)
            values (v_ev, ''calls'', v->''metadata''->>''phone_number_id'', ''numero da Meta nao cadastrado no Fiscal'', v - ''calls'');
            v_falhas := v_falhas + 1;
            continue;
          end if;
          for g in select * from jsonb_array_elements(coalesce(v->''calls'', ''[]'')) loop
            begin
              perform wa_meta_chamada_evento(v, v_num, g);
              v_outros := v_outros + 1;
            exception when others then
              insert into wa_webhook_falha (evento_id, campo, referencia, erro, trecho)
              values (v_ev, ''calls'', g->>''id'', left(sqlerrm, 500), g - ''session'');
              v_falhas := v_falhas + 1;
            end;
          end loop;
          for s in select * from jsonb_array_elements(coalesce(v->''statuses'', ''[]'')) loop
            perform wa_meta_chamada_status(s);
          end loop;
          continue;
        end if;

' || a1;
  a2 text := '            if wa_meta_aplicar_status(s) then';
  b2 text := '            if s->>''type'' = ''call'' then
              perform wa_meta_chamada_status(s);
              v_outros := v_outros + 1;
            elsif wa_meta_aplicar_status(s) then';
  a3 text := '            v_tipo := case m->>''type''';
  b3 text := '            if m->''interactive''->>''type'' = ''call_permission_reply'' then
              perform wa_meta_permissao_resposta(v_cont, m);
            end if;

' || a3;
begin
  d := pg_get_functiondef('public.wa_meta_receber'::regproc);
  if position('wa_meta_chamada_evento' in d) = 0 then
    if position(a1 in d) = 0 or position(a2 in d) = 0 or position(a3 in d) = 0 then raise exception 'trechos nao encontrados'; end if;
    d := replace(d, a1, b1);
    d := replace(d, a2, b2);
    d := replace(d, a3, b3);
    d := replace(d, '              else ''['' || coalesce(m->>''type'', ''desconhecido'') || '']'' end;',
                    '              else ''['' || coalesce(m->>''type'', ''desconhecido'') || '']'' end;
            if m->''interactive''->>''type'' = ''call_permission_reply'' then
              v_texto := case when m->''interactive''->''call_permission_reply''->>''response'' = ''accept''
                              then ''Permitiu ligações'' else ''Recusou ligações'' end;
            end if;');
    execute d;
  end if;
end $$;
