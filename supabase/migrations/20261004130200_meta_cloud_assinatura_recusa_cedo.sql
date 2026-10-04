create or replace function public.fiscal_meta_assinatura_ok(p_corpo text, p_assinatura text)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor confere assinatura'; end if;
  if p_assinatura is null or p_assinatura !~ '^sha256=[0-9a-fA-F]{64}$' then return false; end if;
  return fiscal_hmac_confere(p_corpo, p_assinatura, fiscal_meta_segredo('app_secret'));
end $$;
revoke all on function public.fiscal_meta_assinatura_ok(text, text) from public, anon, authenticated;
grant execute on function public.fiscal_meta_assinatura_ok(text, text) to service_role;
