create table if not exists public.chat_item_visto (
  tipo text not null check (tipo in ('aviso', 'pedido', 'reuniao')),
  item_id uuid not null,
  usuario_id uuid not null,
  visto_em timestamptz not null default now(),
  primary key (tipo, item_id, usuario_id)
);
alter table public.chat_item_visto enable row level security;
revoke all on public.chat_item_visto from anon, authenticated;

create or replace function public.chat_registrar_visto(p_tipo text, p_id uuid)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if not is_interno() or auth.uid() is null then return false; end if;
  if p_tipo not in ('aviso', 'pedido', 'reuniao') then return false; end if;
  insert into chat_item_visto (tipo, item_id, usuario_id) values (p_tipo, p_id, auth.uid())
  on conflict do nothing;
  if p_tipo = 'reuniao' then
    update chat_reuniao_participante set visto_em = coalesce(visto_em, now()) where reuniao_id = p_id and usuario_id = auth.uid();
  end if;
  return true;
end $function$;
revoke all on function public.chat_registrar_visto(text, uuid) from public, anon;
grant execute on function public.chat_registrar_visto(text, uuid) to authenticated;

create or replace function public.chat_quem_viu(p_tipo text, p_id uuid)
 returns jsonb language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_autor uuid;
begin
  if not is_interno() or auth.uid() is null then return '[]'::jsonb; end if;
  v_autor := case p_tipo
    when 'mensagem' then (select autor_id from chat_mensagem where id = p_id)
    when 'aviso' then (select autor_id from chat_aviso where id = p_id)
    when 'pedido' then (select solicitante_id from chat_pedido where id = p_id)
    when 'reuniao' then (select criado_por from chat_reuniao where id = p_id) end;
  if v_autor is distinct from auth.uid() then return '[]'::jsonb; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('usuario_id', u, 'visto_em', em) order by em)
    from (select u, min(em) em from (
            select r.usuario_id u, r.lido_em em from chat_recibo r where p_tipo = 'mensagem' and r.mensagem_id = p_id and r.lido_em is not null
            union all select v.usuario_id, v.visto_em from chat_item_visto v where v.tipo = p_tipo and v.item_id = p_id
            union all select a.usuario_id, a.visto_em from chat_aviso_visto a where p_tipo = 'aviso' and a.aviso_id = p_id
            union all select p.usuario_id, p.visto_em from chat_reuniao_participante p where p_tipo = 'reuniao' and p.reuniao_id = p_id and p.visto_em is not null
          ) x where u <> v_autor group by u) y), '[]'::jsonb);
end $function$;
revoke all on function public.chat_quem_viu(text, uuid) from public, anon;
grant execute on function public.chat_quem_viu(text, uuid) to authenticated;

create or replace function public.chat_presenca_atividade(p_usuario uuid)
 returns void language sql security definer set search_path to 'public', 'pg_temp'
as $function$
  insert into chat_presenca (usuario_id, status, visto_por_ultimo_em, atualizado_em)
  values (p_usuario, 'online', now(), now())
  on conflict (usuario_id) do update set visto_por_ultimo_em = now();
$function$;
revoke all on function public.chat_presenca_atividade(uuid) from public, anon, authenticated;

create or replace function public.chat_presenca_atividade_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if tg_table_name = 'chat_mensagem' then perform chat_presenca_atividade(new.autor_id);
  elsif new.ultima_leitura_em is distinct from old.ultima_leitura_em then perform chat_presenca_atividade(new.usuario_id);
  end if;
  return null;
end $function$;
drop trigger if exists chat_mensagem_atividade on public.chat_mensagem;
create trigger chat_mensagem_atividade after insert on public.chat_mensagem for each row execute function public.chat_presenca_atividade_tg();
drop trigger if exists chat_leitura_atividade on public.chat_canal_membro;
create trigger chat_leitura_atividade after update of ultima_leitura_em on public.chat_canal_membro for each row execute function public.chat_presenca_atividade_tg();
