create extension if not exists pg_net;

alter table public.wa_midia
  add column if not exists transcricao text,
  add column if not exists transcrito_em timestamptz,
  add column if not exists transcricao_erro text;

create or replace function public.wa_midia_transcricao_salvar(p_midia_id uuid, p_texto text, p_erro text default null)
returns boolean
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare n int;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  update wa_midia
     set transcricao = case when p_erro is null then p_texto else transcricao end,
         transcrito_em = case when p_erro is null then now() else transcrito_em end,
         transcricao_erro = left(p_erro, 500)
   where id = p_midia_id and tipo = 'audio';
  get diagnostics n = row_count;
  return n = 1;
end $$;
revoke all on function public.wa_midia_transcricao_salvar(uuid, text, text) from public, anon, authenticated;
grant execute on function public.wa_midia_transcricao_salvar(uuid, text, text) to service_role;

create or replace function public.wa_midia_avisar_transcricao()
returns trigger
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  begin
    if new.tipo = 'audio' and new.estado = 'guardado' and new.transcricao is null
       and exists (select 1 from wa_mensagem w where w.id = new.mensagem_id and w.direcao = 'entrada') then
      perform net.http_post(
        url := 'https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/wa-transcrever',
        body := jsonb_build_object('midia_id', new.id),
        headers := '{"Content-Type":"application/json"}'::jsonb);
    end if;
  exception when others then
    raise warning 'aviso de transcricao falhou: %', sqlerrm;
  end;
  return null;
end $$;
revoke all on function public.wa_midia_avisar_transcricao() from public, anon, authenticated;

drop trigger if exists trg_wa_midia_transcrever on public.wa_midia;
create trigger trg_wa_midia_transcrever
  after insert or update of estado on public.wa_midia
  for each row when (new.tipo = 'audio' and new.estado = 'guardado')
  execute function public.wa_midia_avisar_transcricao();
