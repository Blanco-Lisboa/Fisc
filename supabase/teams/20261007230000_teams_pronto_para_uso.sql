create or replace function public.is_interno()
returns boolean
language sql stable
set search_path to 'public', 'pg_temp'
as $$
  select coalesce((auth.jwt() ->> 'interno')::boolean, (auth.jwt() -> 'app_metadata' ->> 'interno')::boolean, false);
$$;

create or replace function public.chat_pode_ver_canal(p_canal uuid)
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select is_interno() and exists (
    select 1 from chat_canal c
     where c.id = p_canal
       and (c.tipo in ('setor', 'central')
            or exists (select 1 from chat_canal_membro m where m.canal_id = c.id and m.usuario_id = auth.uid())));
$$;
revoke all on function public.chat_pode_ver_canal(uuid) from public, anon;
grant execute on function public.chat_pode_ver_canal(uuid) to authenticated, service_role;

drop policy if exists chat_canal_sel on public.chat_canal;
drop policy if exists chat_canal_ins on public.chat_canal;
drop policy if exists chat_canal_upd on public.chat_canal;
create policy chat_canal_sel on public.chat_canal for select to authenticated using (chat_pode_ver_canal(id));
create policy chat_canal_ins on public.chat_canal for insert to authenticated with check (is_interno() and criado_por = auth.uid() and tipo in ('grupo', 'setor'));
create policy chat_canal_upd on public.chat_canal for update to authenticated
  using (is_interno() and exists (select 1 from chat_canal_membro m where m.canal_id = id and m.usuario_id = auth.uid() and m.papel in ('admin', 'dono')))
  with check (is_interno());

drop policy if exists chat_canal_membro_sel on public.chat_canal_membro;
drop policy if exists chat_canal_membro_ins on public.chat_canal_membro;
drop policy if exists chat_canal_membro_upd on public.chat_canal_membro;
create policy chat_canal_membro_sel on public.chat_canal_membro for select to authenticated using (chat_pode_ver_canal(canal_id));
create policy chat_canal_membro_ins on public.chat_canal_membro for insert to authenticated with check (
  is_interno() and (
    (usuario_id = auth.uid() and exists (select 1 from chat_canal c where c.id = canal_id and c.tipo in ('setor', 'central')))
    or exists (select 1 from chat_canal_membro m where m.canal_id = chat_canal_membro.canal_id and m.usuario_id = auth.uid() and m.papel in ('admin', 'dono'))));
create policy chat_canal_membro_upd on public.chat_canal_membro for update to authenticated
  using (is_interno() and usuario_id = auth.uid()) with check (is_interno() and usuario_id = auth.uid());

drop policy if exists chat_mensagem_sel on public.chat_mensagem;
drop policy if exists chat_mensagem_ins on public.chat_mensagem;
drop policy if exists chat_mensagem_upd on public.chat_mensagem;
create policy chat_mensagem_sel on public.chat_mensagem for select to authenticated using (chat_pode_ver_canal(canal_id));
create policy chat_mensagem_ins on public.chat_mensagem for insert to authenticated with check (chat_pode_ver_canal(canal_id) and autor_id = auth.uid());
create policy chat_mensagem_upd on public.chat_mensagem for update to authenticated using (autor_id = auth.uid() and is_interno()) with check (autor_id = auth.uid());

drop policy if exists chat_topico_sel on public.chat_topico;
drop policy if exists chat_topico_ins on public.chat_topico;
drop policy if exists chat_topico_upd on public.chat_topico;
create policy chat_topico_sel on public.chat_topico for select to authenticated using (chat_pode_ver_canal(canal_id));
create policy chat_topico_ins on public.chat_topico for insert to authenticated with check (chat_pode_ver_canal(canal_id) and criado_por = auth.uid());
create policy chat_topico_upd on public.chat_topico for update to authenticated using (criado_por = auth.uid()) with check (criado_por = auth.uid());

drop policy if exists chat_anexo_sel on public.chat_anexo;
drop policy if exists chat_anexo_ins on public.chat_anexo;
drop policy if exists chat_anexo_upd on public.chat_anexo;
create policy chat_anexo_sel on public.chat_anexo for select to authenticated
  using (exists (select 1 from chat_mensagem m where m.id = mensagem_id and chat_pode_ver_canal(m.canal_id)));
create policy chat_anexo_ins on public.chat_anexo for insert to authenticated
  with check (exists (select 1 from chat_mensagem m where m.id = mensagem_id and m.autor_id = auth.uid() and chat_pode_ver_canal(m.canal_id)));
create policy chat_anexo_upd on public.chat_anexo for update to authenticated
  using (exists (select 1 from chat_mensagem m where m.id = mensagem_id and m.autor_id = auth.uid()));

drop policy if exists chat_mencao_sel on public.chat_mencao;
drop policy if exists chat_mencao_ins on public.chat_mencao;
drop policy if exists chat_mencao_upd on public.chat_mencao;
create policy chat_mencao_sel on public.chat_mencao for select to authenticated
  using (exists (select 1 from chat_mensagem m where m.id = mensagem_id and chat_pode_ver_canal(m.canal_id)));
create policy chat_mencao_ins on public.chat_mencao for insert to authenticated
  with check (exists (select 1 from chat_mensagem m where m.id = mensagem_id and m.autor_id = auth.uid()));

drop policy if exists chat_recibo_sel on public.chat_recibo;
drop policy if exists chat_recibo_ins on public.chat_recibo;
drop policy if exists chat_recibo_upd on public.chat_recibo;
create policy chat_recibo_sel on public.chat_recibo for select to authenticated
  using (exists (select 1 from chat_mensagem m where m.id = mensagem_id and chat_pode_ver_canal(m.canal_id)));
create policy chat_recibo_ins on public.chat_recibo for insert to authenticated with check (usuario_id = auth.uid() and is_interno());
create policy chat_recibo_upd on public.chat_recibo for update to authenticated using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

drop policy if exists chat_presenca_ins on public.chat_presenca;
drop policy if exists chat_presenca_upd on public.chat_presenca;
create policy chat_presenca_ins on public.chat_presenca for insert to authenticated with check (usuario_id = auth.uid() and is_interno());
create policy chat_presenca_upd on public.chat_presenca for update to authenticated using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

drop policy if exists chat_aviso_visto_ins on public.chat_aviso_visto;
drop policy if exists chat_aviso_visto_upd on public.chat_aviso_visto;
create policy chat_aviso_visto_ins on public.chat_aviso_visto for insert to authenticated with check (usuario_id = auth.uid() and is_interno());
create policy chat_aviso_visto_upd on public.chat_aviso_visto for update to authenticated using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

drop policy if exists chat_aviso_ins on public.chat_aviso;
drop policy if exists chat_aviso_upd on public.chat_aviso;
create policy chat_aviso_ins on public.chat_aviso for insert to authenticated with check (autor_id = auth.uid() and is_interno());
create policy chat_aviso_upd on public.chat_aviso for update to authenticated using (autor_id = auth.uid()) with check (autor_id = auth.uid());

drop policy if exists chat_pedido_sel on public.chat_pedido;
drop policy if exists chat_pedido_ins on public.chat_pedido;
drop policy if exists chat_pedido_upd on public.chat_pedido;
create policy chat_pedido_sel on public.chat_pedido for select to authenticated
  using (is_interno() and (canal_id is null or chat_pode_ver_canal(canal_id) or solicitante_id = auth.uid() or responsavel_id = auth.uid()));
create policy chat_pedido_ins on public.chat_pedido for insert to authenticated
  with check (solicitante_id = auth.uid() and is_interno() and (canal_id is null or chat_pode_ver_canal(canal_id)));
create policy chat_pedido_upd on public.chat_pedido for update to authenticated
  using (is_interno() and (solicitante_id = auth.uid() or responsavel_id = auth.uid())) with check (is_interno());

drop policy if exists chat_reuniao_sel on public.chat_reuniao;
drop policy if exists chat_reuniao_ins on public.chat_reuniao;
drop policy if exists chat_reuniao_upd on public.chat_reuniao;
create or replace function public.chat_ve_reuniao(p_reuniao uuid)
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $f$
  select is_interno() and (exists (select 1 from chat_reuniao r where r.id = p_reuniao and r.criado_por = auth.uid())
                           or exists (select 1 from chat_reuniao_participante p where p.reuniao_id = p_reuniao and p.usuario_id = auth.uid()));
$f$;
revoke all on function public.chat_ve_reuniao(uuid) from public, anon;
grant execute on function public.chat_ve_reuniao(uuid) to authenticated;
create policy chat_reuniao_sel on public.chat_reuniao for select to authenticated using (chat_ve_reuniao(id));
create policy chat_reuniao_ins on public.chat_reuniao for insert to authenticated with check (criado_por = auth.uid() and is_interno());
create policy chat_reuniao_upd on public.chat_reuniao for update to authenticated using (criado_por = auth.uid()) with check (criado_por = auth.uid());

drop policy if exists chat_reuniao_participante_sel on public.chat_reuniao_participante;
drop policy if exists chat_reuniao_participante_ins on public.chat_reuniao_participante;
drop policy if exists chat_reuniao_participante_upd on public.chat_reuniao_participante;
create policy chat_reuniao_participante_sel on public.chat_reuniao_participante for select to authenticated
  using (chat_ve_reuniao(reuniao_id));
create policy chat_reuniao_participante_ins on public.chat_reuniao_participante for insert to authenticated
  with check (is_interno() and exists (select 1 from chat_reuniao r where r.id = chat_reuniao_participante.reuniao_id and r.criado_por = auth.uid()));
create policy chat_reuniao_participante_upd on public.chat_reuniao_participante for update to authenticated
  using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

drop policy if exists chat_decisao_ceo_ins on public.chat_decisao_ceo;
drop policy if exists chat_decisao_ceo_upd on public.chat_decisao_ceo;
create policy chat_decisao_ceo_ins on public.chat_decisao_ceo for insert to authenticated
  with check (autor_id = auth.uid() and is_interno() and (canal_id is null or chat_pode_ver_canal(canal_id)));
create policy chat_decisao_ceo_upd on public.chat_decisao_ceo for update to authenticated using (autor_id = auth.uid()) with check (autor_id = auth.uid());

drop policy if exists chat_chamada_sel on public.chat_chamada;
drop policy if exists chat_chamada_ins on public.chat_chamada;
drop policy if exists chat_chamada_upd on public.chat_chamada;
create policy chat_chamada_sel on public.chat_chamada for select to authenticated using (canal_id is not null and chat_pode_ver_canal(canal_id));
create policy chat_chamada_ins on public.chat_chamada for insert to authenticated with check (iniciada_por = auth.uid() and chat_pode_ver_canal(canal_id));
create policy chat_chamada_upd on public.chat_chamada for update to authenticated using (chat_pode_ver_canal(canal_id)) with check (chat_pode_ver_canal(canal_id));

drop policy if exists chat_evento_sel on public.chat_evento;
drop policy if exists chat_evento_ins on public.chat_evento;
drop policy if exists chat_evento_upd on public.chat_evento;
create policy chat_evento_ins on public.chat_evento for insert to authenticated with check (is_interno() and (canal_id is null or chat_pode_ver_canal(canal_id)));

create or replace function public.chat_abrir_direta(p_outro uuid)
returns uuid
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_eu uuid := auth.uid(); v_nome text; v_id uuid;
begin
  if not is_interno() or v_eu is null then raise exception 'so usuario interno'; end if;
  if p_outro is null or p_outro = v_eu then raise exception 'escolha outra pessoa'; end if;
  v_nome := 'dm:' || least(v_eu, p_outro)::text || ':' || greatest(v_eu, p_outro)::text;
  perform pg_advisory_xact_lock(hashtext(v_nome));
  select id into v_id from chat_canal where tipo = 'direta' and nome = v_nome;
  if v_id is null then
    insert into chat_canal (tipo, nome, criado_por) values ('direta', v_nome, v_eu) returning id into v_id;
    insert into chat_canal_membro (canal_id, usuario_id, papel) values (v_id, v_eu, 'membro'), (v_id, p_outro, 'membro');
  end if;
  return v_id;
end $$;
revoke all on function public.chat_abrir_direta(uuid) from public, anon;
grant execute on function public.chat_abrir_direta(uuid) to authenticated;

create or replace function public.chat_abrir_setor(p_setor uuid, p_nome text)
returns uuid
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_id uuid;
begin
  if not is_interno() then raise exception 'so usuario interno'; end if;
  perform pg_advisory_xact_lock(hashtext('setor:' || p_setor::text));
  select id into v_id from chat_canal where tipo = 'setor' and setor_id = p_setor and not arquivado limit 1;
  if v_id is null then
    insert into chat_canal (tipo, setor_id, nome, criado_por) values ('setor', p_setor, left(p_nome, 120), auth.uid()) returning id into v_id;
  end if;
  return v_id;
end $$;
revoke all on function public.chat_abrir_setor(uuid, text) from public, anon;
grant execute on function public.chat_abrir_setor(uuid, text) to authenticated;

create or replace function public.chat_criar_grupo(p_nome text, p_membros uuid[], p_descricao text default null)
returns uuid
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_id uuid; v_eu uuid := auth.uid();
begin
  if not is_interno() or v_eu is null then raise exception 'so usuario interno'; end if;
  if coalesce(btrim(p_nome), '') = '' then raise exception 'nome do grupo obrigatorio'; end if;
  insert into chat_canal (tipo, nome, descricao, criado_por) values ('grupo', left(btrim(p_nome), 120), left(p_descricao, 500), v_eu) returning id into v_id;
  insert into chat_canal_membro (canal_id, usuario_id, papel) values (v_id, v_eu, 'dono');
  insert into chat_canal_membro (canal_id, usuario_id, papel)
  select v_id, x, 'membro' from (select distinct unnest(coalesce(p_membros, '{}')) x) s where x <> v_eu;
  return v_id;
end $$;
revoke all on function public.chat_criar_grupo(text, uuid[], text) from public, anon;
grant execute on function public.chat_criar_grupo(text, uuid[], text) to authenticated;

create or replace function public.chat_marcar_lido(p_canal uuid)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  if not chat_pode_ver_canal(p_canal) then raise exception 'sem acesso a este canal'; end if;
  insert into chat_canal_membro (canal_id, usuario_id, papel, ultima_leitura_em)
  values (p_canal, auth.uid(), 'membro', now())
  on conflict (canal_id, usuario_id) do update set ultima_leitura_em = now();
  insert into chat_recibo (mensagem_id, usuario_id, entregue_em, lido_em)
  select m.id, auth.uid(), now(), now() from chat_mensagem m
   where m.canal_id = p_canal and m.autor_id <> auth.uid() and m.excluida_em is null
     and m.criada_em > now() - interval '30 days'
  on conflict (mensagem_id, usuario_id) do update set lido_em = coalesce(chat_recibo.lido_em, now());
  return true;
end $$;
revoke all on function public.chat_marcar_lido(uuid) from public, anon;
grant execute on function public.chat_marcar_lido(uuid) to authenticated;

create or replace function public.chat_resumo()
returns jsonb
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', c.id, 'tipo', c.tipo, 'nome', c.nome, 'descricao', c.descricao, 'setor_id', c.setor_id,
           'membros', (select jsonb_agg(m2.usuario_id) from chat_canal_membro m2 where m2.canal_id = c.id and c.tipo <> 'setor'),
           'silenciado', coalesce(me.silenciado, false),
           'ultima', (select jsonb_build_object('autor_id', u.autor_id, 'corpo', left(u.corpo, 160), 'tipo', u.tipo, 'em', u.criada_em)
                        from chat_mensagem u where u.canal_id = c.id and u.excluida_em is null order by u.criada_em desc limit 1),
           'nao_lidas', (select count(*) from chat_mensagem u where u.canal_id = c.id and u.excluida_em is null and u.autor_id <> auth.uid()
                           and u.criada_em > coalesce(me.ultima_leitura_em, me.entrou_em, now() - interval '7 days'))
         )), '[]'::jsonb)
    from chat_canal c
    left join chat_canal_membro me on me.canal_id = c.id and me.usuario_id = auth.uid()
   where not c.arquivado and chat_pode_ver_canal(c.id);
$$;
revoke all on function public.chat_resumo() from public, anon;
grant execute on function public.chat_resumo() to authenticated;

insert into storage.buckets (id, name, public, file_size_limit)
values ('chat-anexo', 'chat-anexo', false, 104857600)
on conflict (id) do nothing;
drop policy if exists chat_anexo_subir on storage.objects;
create policy chat_anexo_subir on storage.objects for insert to authenticated
  with check (bucket_id = 'chat-anexo' and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
              and chat_pode_ver_canal(((storage.foldername(name))[1])::uuid));
drop policy if exists chat_anexo_ler on storage.objects;
create policy chat_anexo_ler on storage.objects for select to authenticated
  using (bucket_id = 'chat-anexo' and (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
         and chat_pode_ver_canal(((storage.foldername(name))[1])::uuid));

do $$
declare t text;
begin
  foreach t in array array['chat_mensagem', 'chat_presenca', 'chat_canal', 'chat_canal_membro', 'chat_pedido', 'chat_aviso', 'chat_recibo', 'chat_anexo'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
