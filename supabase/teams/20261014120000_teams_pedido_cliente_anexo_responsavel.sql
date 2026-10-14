alter table chat_pedido add column if not exists empresa_ids uuid[] not null default '{}',
                        add column if not exists todas_empresas boolean not null default false;

alter table chat_anexo alter column mensagem_id drop not null;
alter table chat_anexo add column if not exists pedido_id uuid references chat_pedido(id) on delete cascade;
alter table chat_anexo drop constraint if exists chat_anexo_dono_ck;
alter table chat_anexo add constraint chat_anexo_dono_ck check ((mensagem_id is null) <> (pedido_id is null));
create index if not exists chat_anexo_pedido_ix on chat_anexo(pedido_id) where pedido_id is not null;

create or replace function chat_usuario_interno(p_usuario uuid) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from auth.users u where u.id = p_usuario and coalesce((u.raw_app_meta_data->>'interno')::boolean, false));
$$;

create or replace function chat_pode_ser_responsavel(p_canal uuid, p_usuario uuid) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select chat_usuario_interno(p_usuario) and (
    p_canal is null
    or exists (
      select 1 from chat_canal c
       where c.id = p_canal
         and case c.tipo
               when 'direta' then p_usuario <> auth.uid()
                                  and exists (select 1 from chat_canal_membro m where m.canal_id = c.id and m.usuario_id = p_usuario)
               when 'setor' then exists (select 1 from auth.users u where u.id = p_usuario
                                          and coalesce(u.raw_app_meta_data->'setores', '[]'::jsonb) ? c.setor_id::text)
               when 'central' then true
               else exists (select 1 from chat_canal_membro m where m.canal_id = c.id and m.usuario_id = p_usuario)
             end));
$$;

create or replace function chat_pedido_responsaveis(p_canal uuid) returns setof uuid
language sql stable security definer set search_path = public, pg_temp as $$
  select u.id from auth.users u
   where is_interno() and (p_canal is null or chat_pode_ver_canal(p_canal))
     and chat_pode_ser_responsavel(p_canal, u.id);
$$;

create or replace function chat_pedido_regras_tg() returns trigger
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if new.responsavel_id is null then raise exception 'escolha o responsável'; end if;
  if tg_op = 'INSERT' or new.responsavel_id is distinct from old.responsavel_id or new.canal_id is distinct from old.canal_id then
    if not chat_pode_ser_responsavel(new.canal_id, new.responsavel_id) then
      raise exception 'responsável não pode receber pedido nesta conversa';
    end if;
  end if;
  new.empresa_ids := coalesce((select array_agg(distinct x) from unnest(new.empresa_ids) x where x is not null), '{}');
  if new.cliente_id is null and (new.todas_empresas or cardinality(new.empresa_ids) > 0) then
    raise exception 'escolha o cliente antes das empresas';
  end if;
  if new.todas_empresas then new.empresa_ids := '{}'; end if;
  return new;
end $$;

drop trigger if exists chat_pedido_regras on chat_pedido;
create trigger chat_pedido_regras before insert or update on chat_pedido
  for each row execute function chat_pedido_regras_tg();

create or replace function chat_pode_ver_pedido(p_pedido uuid) returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select is_interno() and exists (
    select 1 from chat_pedido p
     where p.id = p_pedido
       and (p.canal_id is null or chat_pode_ver_canal(p.canal_id)
            or p.solicitante_id = auth.uid() or p.responsavel_id = auth.uid()));
$$;

drop policy if exists chat_anexo_sel on chat_anexo;
create policy chat_anexo_sel on chat_anexo for select using (
  (mensagem_id is not null and exists (select 1 from chat_mensagem m where m.id = chat_anexo.mensagem_id and chat_pode_ver_canal(m.canal_id)))
  or (pedido_id is not null and chat_pode_ver_pedido(pedido_id)));
drop policy if exists chat_anexo_ins on chat_anexo;
create policy chat_anexo_ins on chat_anexo for insert with check (
  (mensagem_id is not null and exists (select 1 from chat_mensagem m where m.id = chat_anexo.mensagem_id and m.autor_id = auth.uid() and chat_pode_ver_canal(m.canal_id)))
  or (pedido_id is not null and exists (select 1 from chat_pedido p where p.id = chat_anexo.pedido_id and p.solicitante_id = auth.uid())));

drop policy if exists chat_anexo_pedido_subir on storage.objects;
create policy chat_anexo_pedido_subir on storage.objects for insert with check (
  bucket_id = 'chat-anexo' and (storage.foldername(name))[1] = 'pedido'
  and (storage.foldername(name))[2] ~ '^[0-9a-f-]{36}$'
  and exists (select 1 from public.chat_pedido p where p.id = ((storage.foldername(name))[2])::uuid and p.solicitante_id = auth.uid()));
drop policy if exists chat_anexo_pedido_ler on storage.objects;
create policy chat_anexo_pedido_ler on storage.objects for select using (
  bucket_id = 'chat-anexo' and (storage.foldername(name))[1] = 'pedido'
  and (storage.foldername(name))[2] ~ '^[0-9a-f-]{36}$'
  and public.chat_pode_ver_pedido(((storage.foldername(name))[2])::uuid));

revoke execute on function chat_usuario_interno(uuid), chat_pode_ser_responsavel(uuid, uuid), chat_pedido_regras_tg() from public, anon;
revoke execute on function chat_pedido_responsaveis(uuid), chat_pode_ver_pedido(uuid) from public, anon;
grant execute on function chat_pedido_responsaveis(uuid), chat_pode_ver_pedido(uuid), chat_pode_ser_responsavel(uuid, uuid), chat_usuario_interno(uuid) to authenticated;
