create table if not exists public.fiscal_app_versao (
  aplicativo text primary key,
  versao text not null,
  manifesto jsonb not null,
  publicada_em timestamptz not null default now()
);
alter table public.fiscal_app_versao enable row level security;
drop policy if exists fiscal_app_versao_ler on public.fiscal_app_versao;
create policy fiscal_app_versao_ler on public.fiscal_app_versao for select to anon, authenticated using (true);
revoke insert, update, delete, truncate on public.fiscal_app_versao from anon, authenticated;
grant select on public.fiscal_app_versao to anon, authenticated;

create table if not exists public.fiscal_app_publicador (
  id smallint primary key default 1 check (id = 1),
  token_hash text not null,
  criado_em timestamptz not null default now()
);
alter table public.fiscal_app_publicador enable row level security;
revoke all on public.fiscal_app_publicador from anon, authenticated;

create or replace function public.fiscal_app_publicador_ok(p_token text)
returns boolean language sql security definer set search_path = public, extensions as $$
  select exists(select 1 from fiscal_app_publicador
    where token_hash = encode(extensions.digest(coalesce(p_token,''), 'sha256'), 'hex'));
$$;
revoke all on function public.fiscal_app_publicador_ok(text) from public, anon, authenticated;
grant execute on function public.fiscal_app_publicador_ok(text) to service_role;

create or replace function public.fiscal_app_publicar(p_aplicativo text, p_versao text, p_manifesto jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if coalesce(p_aplicativo,'') = '' or coalesce(p_versao,'') = '' then
    raise exception 'aplicativo e versao obrigatorios';
  end if;
  if jsonb_typeof(p_manifesto->'arquivos') <> 'array' or jsonb_array_length(p_manifesto->'arquivos') = 0
     or coalesce(p_manifesto->>'principal','') = '' then
    raise exception 'manifesto invalido';
  end if;
  insert into fiscal_app_versao(aplicativo, versao, manifesto, publicada_em)
  values (p_aplicativo, p_versao, p_manifesto, now())
  on conflict (aplicativo) do update set versao = excluded.versao, manifesto = excluded.manifesto, publicada_em = now();
  return jsonb_build_object('ok', true, 'versao', p_versao);
end $$;
revoke all on function public.fiscal_app_publicar(text, text, jsonb) from public, anon, authenticated;
grant execute on function public.fiscal_app_publicar(text, text, jsonb) to service_role;

do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and tablename='fiscal_app_versao') then
    alter publication supabase_realtime add table public.fiscal_app_versao;
  end if;
end $$;

insert into storage.buckets (id, name, public, file_size_limit)
values ('fiscal-app', 'fiscal-app', true, 209715200)
on conflict (id) do update set public = true;
