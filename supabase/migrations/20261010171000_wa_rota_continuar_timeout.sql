create or replace function public.wa_rota_continuar()
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_chave text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if not exists (select 1 from wa_rota_numero where resolvido_em is null) then return false; end if;
  select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'bl_aviso_chave_interna';
  perform net.http_post(url := 'https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/bl-aviso',
    body := jsonb_build_object('acao', 'resolver'),
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-chave-interna', v_chave),
    timeout_milliseconds := 120000);
  return true;
end $function$;
