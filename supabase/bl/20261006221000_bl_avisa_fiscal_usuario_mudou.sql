create or replace function public.avisar_fiscal_usuario_mudou()
returns trigger
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_id uuid;
begin
  begin
    if tg_table_name = 'usuarios_internos' then
      v_id := new.id;
    elsif tg_op = 'DELETE' then
      v_id := old.usuario_id;
    else
      v_id := new.usuario_id;
    end if;
    perform net.http_post(
      url := 'https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/fiscal-usuario-mudou',
      body := jsonb_build_object('usuario_id', v_id),
      headers := '{"Content-Type":"application/json"}'::jsonb);
  exception when others then
    raise warning 'aviso ao Fiscal falhou: %', sqlerrm;
  end;
  return null;
end $$;
revoke all on function public.avisar_fiscal_usuario_mudou() from public, anon, authenticated;

drop trigger if exists trg_avisar_fiscal_usuario on public.usuarios_internos;
create trigger trg_avisar_fiscal_usuario
  after update of nivel, ativo, nome, email on public.usuarios_internos
  for each row when ((old.nivel, old.ativo, old.nome, old.email) is distinct from (new.nivel, new.ativo, new.nome, new.email))
  execute function public.avisar_fiscal_usuario_mudou();

drop trigger if exists trg_avisar_fiscal_setor on public.usuario_setores;
create trigger trg_avisar_fiscal_setor
  after insert or delete or update of setor_id on public.usuario_setores
  for each row execute function public.avisar_fiscal_usuario_mudou();
