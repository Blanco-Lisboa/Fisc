alter table public.chat_aviso add column if not exists nivel text not null default 'info';
alter table public.chat_aviso drop constraint if exists chat_aviso_nivel_ck;
alter table public.chat_aviso add constraint chat_aviso_nivel_ck check (nivel in ('info', 'visto', 'urgente'));

drop policy if exists teams_ligacao_receber on realtime.messages;
create policy teams_ligacao_receber on realtime.messages for select to authenticated
  using (public.is_interno() and realtime.topic() = 'tm-u-' || auth.uid()::text);
drop policy if exists teams_ligacao_enviar on realtime.messages;
create policy teams_ligacao_enviar on realtime.messages for insert to authenticated
  with check (public.is_interno() and realtime.topic() like 'tm-u-%' and realtime.messages.extension = 'broadcast');

drop policy if exists chat_chamada_participante_sel on public.chat_chamada_participante;
drop policy if exists chat_chamada_participante_ins on public.chat_chamada_participante;
drop policy if exists chat_chamada_participante_upd on public.chat_chamada_participante;
create policy chat_chamada_participante_sel on public.chat_chamada_participante for select to authenticated
  using (exists (select 1 from chat_chamada c where c.id = chamada_id and c.canal_id is not null and chat_pode_ver_canal(c.canal_id)));
create policy chat_chamada_participante_ins on public.chat_chamada_participante for insert to authenticated
  with check (exists (select 1 from chat_chamada c where c.id = chamada_id and c.canal_id is not null and chat_pode_ver_canal(c.canal_id)));
create policy chat_chamada_participante_upd on public.chat_chamada_participante for update to authenticated
  using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());
