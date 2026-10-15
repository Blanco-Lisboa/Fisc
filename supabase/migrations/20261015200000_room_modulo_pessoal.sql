-- room
create table if not exists public.room_categoria (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid(),
  nome text not null check (length(btrim(nome)) between 1 and 40),
  cor text not null check (cor ~ '^#[0-9A-Fa-f]{6}$'),
  ordem int not null default 0,
  arquivada boolean not null default false,
  criado_em timestamptz not null default now()
);
create index if not exists room_categoria_usuario on public.room_categoria(usuario_id);

create table if not exists public.room_nota (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid(),
  dia date not null default (now() at time zone 'America/Sao_Paulo')::date,
  texto text check (texto is null or length(texto) <= 8000),
  categoria_id uuid references public.room_categoria(id) on delete set null,
  empresa_id uuid,
  competencia text check (competencia is null or competencia ~ '^\d{2}/\d{4}$'),
  arquivos jsonb not null default '[]'::jsonb check (jsonb_typeof(arquivos) = 'array'),
  audio jsonb,
  topico text check (topico is null or length(topico) <= 120),
  fixada boolean not null default false,
  criado_em timestamptz not null default now(),
  check (coalesce(btrim(texto),'') <> '' or jsonb_array_length(arquivos) > 0 or audio is not null or topico is not null)
);
create index if not exists room_nota_usuario_dia on public.room_nota(usuario_id, dia, criado_em);

create table if not exists public.room_item (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid(),
  titulo text not null check (length(btrim(titulo)) between 1 and 300),
  tipo text not null check (tipo in ('lembrete','alarme','tarefa')),
  dia date not null,
  hora time,
  repetir text not null default 'nao' check (repetir in ('nao','dia','semana','mes')),
  categoria_id uuid references public.room_categoria(id) on delete set null,
  nota_id uuid references public.room_nota(id) on delete set null,
  adiado_ate timestamptz,
  feito_em timestamptz,
  disparado_em timestamptz,
  criado_em timestamptz not null default now()
);
create index if not exists room_item_usuario_dia on public.room_item(usuario_id, dia);

alter table public.room_categoria enable row level security;
alter table public.room_nota enable row level security;
alter table public.room_item enable row level security;
drop policy if exists room_categoria_dono on public.room_categoria;
drop policy if exists room_nota_dono on public.room_nota;
drop policy if exists room_item_dono on public.room_item;
create policy room_categoria_dono on public.room_categoria for all to authenticated using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());
create policy room_nota_dono on public.room_nota for all to authenticated using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());
create policy room_item_dono on public.room_item for all to authenticated using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());
revoke all on public.room_categoria, public.room_nota, public.room_item from anon;
grant select, insert, update, delete on public.room_categoria, public.room_nota, public.room_item to authenticated;

do $$ begin
  begin alter publication supabase_realtime add table public.room_categoria; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.room_nota; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.room_item; exception when duplicate_object then null; end;
end $$;

create or replace function public._room_quem() returns uuid
language plpgsql stable security definer set search_path to 'public','pg_temp' as $f$
begin
  if auth.uid() is null or fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  return auth.uid();
end $f$;
revoke all on function public._room_quem() from public, anon;
grant execute on function public._room_quem() to authenticated;

create or replace function public.room_dados(p_de date, p_ate date)
returns jsonb language plpgsql security definer set search_path to 'public','pg_temp' as $f$
declare u uuid := _room_quem(); hoje date := (now() at time zone 'America/Sao_Paulo')::date;
begin
  if p_ate < p_de or p_ate - p_de > 400 then raise exception 'periodo invalido'; end if;
  if not exists (select 1 from room_categoria where usuario_id = u) then
    insert into room_categoria(usuario_id, nome, cor, ordem) values
      (u,'Prazos fiscais','#C0392B',1),(u,'Retorno a cliente','#3A5A8C',2),(u,'Apuração','#1B7A44',3),(u,'Sistemas','#6D4AA0',4),(u,'Pessoal','#B25E09',5);
  end if;
  return jsonb_build_object(
    'hoje', hoje,
    'categorias', coalesce((select jsonb_agg(to_jsonb(c) order by c.ordem, c.criado_em) from room_categoria c where c.usuario_id = u and not c.arquivada), '[]'),
    'notas', coalesce((select jsonb_agg(to_jsonb(n) order by n.dia, n.criado_em) from room_nota n where n.usuario_id = u and n.dia between p_de and p_ate), '[]'),
    'dias_com_nota', coalesce((select jsonb_agg(distinct n.dia) from room_nota n where n.usuario_id = u), '[]'),
    'itens', coalesce((select jsonb_agg(to_jsonb(i) order by i.dia, i.hora nulls first) from room_item i where i.usuario_id = u and (i.dia between p_de and p_ate or (i.feito_em is null and i.dia < hoje) or i.repetir <> 'nao')), '[]'));
end $f$;

create or replace function public.room_nota_salvar(p jsonb)
returns jsonb language plpgsql security definer set search_path to 'public','pg_temp' as $f$
declare u uuid := _room_quem(); r room_nota;
begin
  if p ? 'categoria_id' and nullif(p->>'categoria_id','') is not null and not exists (select 1 from room_categoria where id = (p->>'categoria_id')::uuid and usuario_id = u) then raise exception 'categoria invalida'; end if;
  if nullif(p->>'id','') is null then
    insert into room_nota(usuario_id, dia, texto, categoria_id, empresa_id, competencia, arquivos, audio, topico)
    values (u, coalesce((p->>'dia')::date, (now() at time zone 'America/Sao_Paulo')::date), nullif(btrim(p->>'texto'),''),
            nullif(p->>'categoria_id','')::uuid, nullif(p->>'empresa_id','')::uuid, nullif(p->>'competencia',''),
            coalesce(p->'arquivos','[]'::jsonb), case when jsonb_typeof(p->'audio') = 'object' then p->'audio' end, nullif(btrim(p->>'topico'),''))
    returning * into r;
  else
    update room_nota set
      texto = case when p ? 'texto' then nullif(btrim(p->>'texto'),'') else texto end,
      categoria_id = case when p ? 'categoria_id' then nullif(p->>'categoria_id','')::uuid else categoria_id end,
      empresa_id = case when p ? 'empresa_id' then nullif(p->>'empresa_id','')::uuid else empresa_id end,
      competencia = case when p ? 'competencia' then nullif(p->>'competencia','') else competencia end,
      fixada = case when p ? 'fixada' then (p->>'fixada')::boolean else fixada end
    where id = (p->>'id')::uuid and usuario_id = u returning * into r;
    if r.id is null then raise exception 'nota nao encontrada'; end if;
  end if;
  return to_jsonb(r);
end $f$;

create or replace function public.room_nota_apagar(p_id uuid)
returns boolean language plpgsql security definer set search_path to 'public','pg_temp' as $f$
declare u uuid := _room_quem();
begin
  delete from room_nota where id = p_id and usuario_id = u;
  if not found then raise exception 'nota nao encontrada'; end if;
  return true;
end $f$;

create or replace function public.room_item_salvar(p jsonb)
returns jsonb language plpgsql security definer set search_path to 'public','pg_temp' as $f$
declare u uuid := _room_quem(); r room_item;
begin
  if nullif(p->>'categoria_id','') is not null and not exists (select 1 from room_categoria where id = (p->>'categoria_id')::uuid and usuario_id = u) then raise exception 'categoria invalida'; end if;
  if nullif(p->>'nota_id','') is not null and not exists (select 1 from room_nota where id = (p->>'nota_id')::uuid and usuario_id = u) then raise exception 'nota invalida'; end if;
  if nullif(p->>'id','') is null then
    insert into room_item(usuario_id, titulo, tipo, dia, hora, repetir, categoria_id, nota_id)
    values (u, btrim(p->>'titulo'), coalesce(p->>'tipo','lembrete'), (p->>'dia')::date, nullif(p->>'hora','')::time,
            coalesce(nullif(p->>'repetir',''),'nao'), nullif(p->>'categoria_id','')::uuid, nullif(p->>'nota_id','')::uuid)
    returning * into r;
  else
    update room_item set titulo = coalesce(nullif(btrim(p->>'titulo'),''), titulo), tipo = coalesce(p->>'tipo', tipo),
      dia = coalesce((p->>'dia')::date, dia), hora = case when p ? 'hora' then nullif(p->>'hora','')::time else hora end,
      repetir = coalesce(nullif(p->>'repetir',''), repetir), categoria_id = case when p ? 'categoria_id' then nullif(p->>'categoria_id','')::uuid else categoria_id end,
      adiado_ate = null, disparado_em = null
    where id = (p->>'id')::uuid and usuario_id = u returning * into r;
    if r.id is null then raise exception 'item nao encontrado'; end if;
  end if;
  if r.tipo <> 'tarefa' and r.hora is null then raise exception 'lembrete e alarme precisam de hora'; end if;
  return to_jsonb(r);
end $f$;

create or replace function public.room_item_concluir(p_id uuid, p_feito boolean default true)
returns jsonb language plpgsql security definer set search_path to 'public','pg_temp' as $f$
declare u uuid := _room_quem(); r room_item; prox date;
begin
  select * into r from room_item where id = p_id and usuario_id = u for update;
  if r.id is null then raise exception 'item nao encontrado'; end if;
  if p_feito and r.feito_em is null then
    update room_item set feito_em = now(), adiado_ate = null where id = p_id returning * into r;
    if r.repetir <> 'nao' then
      prox := case r.repetir when 'dia' then r.dia + 1 when 'semana' then r.dia + 7 else (r.dia + interval '1 month')::date end;
      insert into room_item(usuario_id, titulo, tipo, dia, hora, repetir, categoria_id)
      values (u, r.titulo, r.tipo, prox, r.hora, r.repetir, r.categoria_id);
    end if;
  elsif not p_feito then
    update room_item set feito_em = null where id = p_id returning * into r;
  end if;
  return to_jsonb(r);
end $f$;

create or replace function public.room_item_adiar(p_id uuid, p_minutos int)
returns jsonb language plpgsql security definer set search_path to 'public','pg_temp' as $f$
declare u uuid := _room_quem(); r room_item;
begin
  if p_minutos not between 1 and 1440 then raise exception 'adiamento invalido'; end if;
  update room_item set adiado_ate = now() + make_interval(mins => p_minutos), disparado_em = null
   where id = p_id and usuario_id = u and feito_em is null returning * into r;
  if r.id is null then raise exception 'item nao encontrado'; end if;
  return to_jsonb(r);
end $f$;

create or replace function public.room_item_disparado(p_id uuid)
returns boolean language plpgsql security definer set search_path to 'public','pg_temp' as $f$
declare u uuid := _room_quem();
begin
  update room_item set disparado_em = now() where id = p_id and usuario_id = u and feito_em is null;
  return found;
end $f$;

create or replace function public.room_item_apagar(p_id uuid)
returns boolean language plpgsql security definer set search_path to 'public','pg_temp' as $f$
declare u uuid := _room_quem();
begin
  delete from room_item where id = p_id and usuario_id = u;
  if not found then raise exception 'item nao encontrado'; end if;
  return true;
end $f$;

create or replace function public.room_categoria_salvar(p jsonb)
returns jsonb language plpgsql security definer set search_path to 'public','pg_temp' as $f$
declare u uuid := _room_quem(); r room_categoria;
begin
  if nullif(p->>'id','') is null then
    insert into room_categoria(usuario_id, nome, cor, ordem)
    values (u, btrim(p->>'nome'), p->>'cor', coalesce((select max(ordem)+1 from room_categoria where usuario_id = u), 1)) returning * into r;
  else
    update room_categoria set nome = coalesce(nullif(btrim(p->>'nome'),''), nome), cor = coalesce(p->>'cor', cor),
      arquivada = coalesce((p->>'arquivada')::boolean, arquivada)
    where id = (p->>'id')::uuid and usuario_id = u returning * into r;
    if r.id is null then raise exception 'categoria nao encontrada'; end if;
  end if;
  return to_jsonb(r);
end $f$;

do $$ declare f text; begin
  foreach f in array array['room_dados(date,date)','room_nota_salvar(jsonb)','room_nota_apagar(uuid)','room_item_salvar(jsonb)','room_item_concluir(uuid,boolean)',
    'room_item_adiar(uuid,integer)','room_item_disparado(uuid)','room_item_apagar(uuid)','room_categoria_salvar(jsonb)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

insert into storage.buckets (id, name, public, file_size_limit)
values ('room','room', false, 52428800) on conflict (id) do nothing;
drop policy if exists room_arquivo_dono_ler on storage.objects;
drop policy if exists room_arquivo_dono_gravar on storage.objects;
drop policy if exists room_arquivo_dono_apagar on storage.objects;
create policy room_arquivo_dono_ler on storage.objects for select to authenticated using (bucket_id = 'room' and (storage.foldername(name))[1] = auth.uid()::text);
create policy room_arquivo_dono_gravar on storage.objects for insert to authenticated with check (bucket_id = 'room' and (storage.foldername(name))[1] = auth.uid()::text);
create policy room_arquivo_dono_apagar on storage.objects for delete to authenticated using (bucket_id = 'room' and (storage.foldername(name))[1] = auth.uid()::text);
