alter table public.wa_conversa add column if not exists janela_ate timestamptz;

create or replace function public.wa_conversa_abrir_janela(p_conversa uuid, p_quando timestamptz)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if p_conversa is null or p_quando is null then return; end if;
  update wa_conversa set janela_ate = least(p_quando, now()) + interval '24 hours', atualizado_em = now()
   where id = p_conversa and (janela_ate is null or janela_ate < least(p_quando, now()) + interval '24 hours');
end $function$;
revoke all on function public.wa_conversa_abrir_janela(uuid, timestamptz) from public, anon, authenticated;

create or replace function public.wa_mensagem_janela_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if new.direcao = 'entrada' and new.tipo <> 'sistema' then
    perform wa_conversa_abrir_janela(new.conversa_id, coalesce(new.ocorrido_em, now()));
  end if;
  return null;
end $function$;
revoke all on function public.wa_mensagem_janela_tg() from public, anon, authenticated;
drop trigger if exists wa_mensagem_janela on public.wa_mensagem;
create trigger wa_mensagem_janela after insert on public.wa_mensagem for each row execute function public.wa_mensagem_janela_tg();

create or replace function public.wa_chamada_janela_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if new.direcao = 'cliente' and tg_op = 'INSERT' then
    perform wa_conversa_abrir_janela(new.conversa_id, coalesce(new.inicio_em, now()));
  elsif new.direcao = 'empresa' and new.estado = 'em_curso' and (tg_op = 'INSERT' or old.estado is distinct from 'em_curso') then
    perform wa_conversa_abrir_janela(new.conversa_id, now());
  elsif new.direcao = 'empresa' and tg_op = 'UPDATE' and new.estado = 'encerrada' and old.estado in ('chamando', 'tocando')
        and coalesce(new.duracao_s, 0) > 0 then
    perform wa_conversa_abrir_janela(new.conversa_id, coalesce(new.inicio_em, now()));
  end if;
  return null;
end $function$;
revoke all on function public.wa_chamada_janela_tg() from public, anon, authenticated;
drop trigger if exists wa_chamada_janela on public.wa_chamada;
create trigger wa_chamada_janela after insert or update of estado on public.wa_chamada for each row execute function public.wa_chamada_janela_tg();

update wa_conversa c set janela_ate = x.ate
  from (select conversa_id, max(t) + interval '24 hours' ate from (
          select conversa_id, ocorrido_em t from wa_mensagem where direcao = 'entrada' and tipo <> 'sistema'
          union all select conversa_id, inicio_em from wa_chamada where direcao = 'cliente'
          union all select conversa_id, inicio_em from wa_chamada where direcao = 'empresa' and coalesce(duracao_s, 0) > 0) u
        where t is not null group by conversa_id) x
 where x.conversa_id = c.id and c.janela_ate is distinct from x.ate;

do $$
declare d text; n text;
begin
  d := pg_get_functiondef('public.wa_meta_preparar_envio(uuid,text,text,text,text,jsonb,text,jsonb)'::regprocedure);
  n := replace(d, $a$    select max(ocorrido_em) into v_ult from wa_mensagem where conversa_id = cv.id and direcao = 'entrada';
    if v_ult is null or v_ult < now() - interval '24 hours' then$a$,
                  $a$    if cv.janela_ate is null or cv.janela_ate <= now() then$a$);
  if n = d then raise exception 'wa_meta_preparar_envio: trecho da janela nao encontrado'; end if;
  execute n;

  d := pg_get_functiondef('public.wa_chamada_pedir_preparar(uuid)'::regprocedure);
  n := replace(d, $a$  if not exists (select 1 from wa_mensagem where conversa_id = cv.id and direcao = 'entrada' and ocorrido_em > now() - interval '24 hours') then$a$,
                  $a$  if cv.janela_ate is null or cv.janela_ate <= now() then$a$);
  if n = d then raise exception 'wa_chamada_pedir_preparar: trecho da janela nao encontrado'; end if;
  execute n;
end $$;

create or replace function public.fiscal_agora()
 returns timestamptz language sql stable set search_path to 'public', 'pg_temp'
as $function$ select now() $function$;
revoke all on function public.fiscal_agora() from public, anon;
grant execute on function public.fiscal_agora() to authenticated;
