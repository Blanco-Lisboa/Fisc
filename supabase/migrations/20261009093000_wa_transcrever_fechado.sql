do $$
begin
  if not exists (select 1 from vault.secrets where name = 'wa_transcrever_chave') then
    perform vault.create_secret(encode(extensions.gen_random_bytes(32), 'hex'), 'wa_transcrever_chave', 'chamada interna banco -> wa-transcrever');
  end if;
end $$;

create or replace function public.wa_transcrever_chave_ok(p_chave text)
 returns boolean language plpgsql stable security definer set search_path to 'public', 'extensions', 'pg_temp'
as $function$
declare v text;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  select decrypted_secret into v from vault.decrypted_secrets where name = 'wa_transcrever_chave';
  if v is null or p_chave is null or length(p_chave) <> length(v) then return false; end if;
  return extensions.digest(p_chave, 'sha256') = extensions.digest(v, 'sha256');
end $function$;
revoke all on function public.wa_transcrever_chave_ok(text) from public, anon, authenticated;

create or replace function public.wa_midia_avisar_transcricao()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_chave text;
begin
  begin
    if new.tipo = 'audio' and new.estado = 'guardado' and new.transcricao is null
       and exists (select 1 from wa_mensagem w where w.id = new.mensagem_id and w.direcao = 'entrada') then
      select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'wa_transcrever_chave';
      perform net.http_post(
        url := 'https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/wa-transcrever',
        body := jsonb_build_object('midia_id', new.id),
        headers := jsonb_build_object('Content-Type', 'application/json', 'x-chave-interna', v_chave));
    end if;
  exception when others then
    raise warning 'aviso de transcricao falhou: %', sqlerrm;
  end;
  return null;
end $function$;
