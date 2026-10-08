create table if not exists public.fiscal_usuario_pref (
  usuario_id uuid not null default auth.uid() references public.fiscal_usuario(id) on delete cascade,
  chave text not null check (chave ~ '^[a-z0-9_]{1,60}$'),
  valor jsonb not null,
  atualizado_em timestamptz not null default now(),
  primary key (usuario_id, chave)
);
alter table public.fiscal_usuario_pref enable row level security;
revoke all on public.fiscal_usuario_pref from anon;
grant select, insert, update, delete on public.fiscal_usuario_pref to authenticated;
create policy fiscal_usuario_pref_ler on public.fiscal_usuario_pref for select to authenticated using (usuario_id = auth.uid());
create policy fiscal_usuario_pref_criar on public.fiscal_usuario_pref for insert to authenticated with check (usuario_id = auth.uid() and fiscal_nivel() is not null);
create policy fiscal_usuario_pref_mudar on public.fiscal_usuario_pref for update to authenticated using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());
create policy fiscal_usuario_pref_apagar on public.fiscal_usuario_pref for delete to authenticated using (usuario_id = auth.uid());
