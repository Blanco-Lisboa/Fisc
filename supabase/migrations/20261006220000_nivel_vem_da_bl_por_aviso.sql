create or replace function public.fiscal_usuario_sincronizar(p_usuario uuid)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare a jsonb;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if p_usuario is null then raise exception 'falta o usuario'; end if;
  a := fiscal_acesso_bl(p_usuario);
  if coalesce((a->>'pode')::boolean, false) then
    insert into fiscal_usuario (id, nome, email, nivel, ativo)
    values (p_usuario, a->>'nome', a->>'email', a->>'nivel', true)
    on conflict (id) do update
      set nome = excluded.nome, email = excluded.email, nivel = excluded.nivel, ativo = true
      where (fiscal_usuario.nome, fiscal_usuario.email, fiscal_usuario.nivel, fiscal_usuario.ativo)
            is distinct from (excluded.nome, excluded.email, excluded.nivel, true);
  else
    update fiscal_usuario set ativo = false where id = p_usuario and ativo;
  end if;
  return a;
end $$;
revoke all on function public.fiscal_usuario_sincronizar(uuid) from public, anon, authenticated;
grant execute on function public.fiscal_usuario_sincronizar(uuid) to service_role;

create or replace function public.fiscal_nivel()
returns text
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select u.nivel from fiscal_usuario u
   where u.id = auth.uid() and u.ativo and u.nivel in ('colaborador', 'assistente', 'gerente');
$$;

do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'fiscal_usuario') then
    alter publication supabase_realtime add table public.fiscal_usuario;
  end if;
end $$;
