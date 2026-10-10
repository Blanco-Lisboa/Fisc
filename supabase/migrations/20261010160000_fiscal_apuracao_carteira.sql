create or replace function public.fiscal_apuracao_carteira()
 returns setof uuid language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select k.empresa_id from wa_rota_carteira k
   where fiscal_nivel() is not null and k.dono_id = auth.uid()
$function$;
revoke all on function public.fiscal_apuracao_carteira() from public, anon;
grant execute on function public.fiscal_apuracao_carteira() to authenticated;
