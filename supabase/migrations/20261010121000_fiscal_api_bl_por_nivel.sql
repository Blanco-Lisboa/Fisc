create table if not exists public.fiscal_api_bl_nivel (
  nivel text primary key
);
alter table public.fiscal_api_bl_nivel enable row level security;
revoke all on public.fiscal_api_bl_nivel from anon, authenticated;
insert into public.fiscal_api_bl_nivel (nivel) values ('ceo') on conflict do nothing;

drop function if exists public.fiscal_api_bl_pode(uuid);
create or replace function public.fiscal_api_bl_pode(p_usuario uuid, p_nivel text, p_ativo boolean)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select fiscal_e_servidor() and p_usuario is not null and coalesce(p_ativo, false)
     and (exists (select 1 from fiscal_api_bl_nivel where nivel = lower(p_nivel))
          or exists (select 1 from fiscal_api_bl_acesso where usuario_bl_id = p_usuario and ativo))
$function$;
revoke all on function public.fiscal_api_bl_pode(uuid, text, boolean) from public, anon, authenticated;
