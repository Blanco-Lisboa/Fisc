create or replace function public.fiscal_setor_bl()
 returns uuid language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$ select case when fiscal_nivel() is not null then (select bl_setor_fiscal from fiscal_config limit 1) end $function$;
revoke all on function public.fiscal_setor_bl() from public, anon;
grant execute on function public.fiscal_setor_bl() to authenticated;
