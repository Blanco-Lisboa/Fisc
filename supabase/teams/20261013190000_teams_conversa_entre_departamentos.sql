alter table public.chat_canal add column if not exists setor_b_id uuid;
alter table public.chat_canal drop constraint if exists chat_canal_tipo_check;
alter table public.chat_canal add constraint chat_canal_tipo_check check (tipo = any (array['direta', 'setor', 'grupo', 'central', 'departamentos']));
create unique index if not exists chat_canal_departamentos_par on public.chat_canal (setor_id, setor_b_id) where tipo = 'departamentos';

create or replace function public.chat_abrir_departamentos(p_a uuid, p_b uuid, p_nome text, p_membros uuid[])
 returns uuid language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_x uuid; v_y uuid; v_id uuid;
begin
  if not is_interno() or auth.uid() is null then raise exception 'sem acesso'; end if;
  if p_b is null or not (auth.uid() = any(coalesce(p_membros, '{}'))) then raise exception 'sem acesso'; end if;
  v_x := least(coalesce(p_a, p_b), p_b);
  v_y := greatest(coalesce(p_a, p_b), p_b);
  select id into v_id from chat_canal where tipo = 'departamentos' and setor_id = v_x and setor_b_id = v_y;
  if v_id is null then
    insert into chat_canal (tipo, setor_id, setor_b_id, nome, criado_por)
    values ('departamentos', v_x, v_y, left(coalesce(nullif(btrim(p_nome), ''), 'Departamentos'), 120), auth.uid())
    on conflict do nothing returning id into v_id;
    if v_id is null then
      select id into v_id from chat_canal where tipo = 'departamentos' and setor_id = v_x and setor_b_id = v_y;
    end if;
  end if;
  insert into chat_canal_membro (canal_id, usuario_id, papel, entrou_em)
  select v_id, u, 'membro', now() from unnest(p_membros) u where u is not null
  on conflict (canal_id, usuario_id) do nothing;
  return v_id;
end $function$;
revoke all on function public.chat_abrir_departamentos(uuid, uuid, text, uuid[]) from public, anon;
grant execute on function public.chat_abrir_departamentos(uuid, uuid, text, uuid[]) to authenticated;

create or replace function public.chat_resumo()
 returns jsonb language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', c.id, 'tipo', c.tipo, 'nome', c.nome, 'descricao', c.descricao, 'setor_id', c.setor_id, 'setor_b_id', c.setor_b_id,
           'membros', (select jsonb_agg(m2.usuario_id) from chat_canal_membro m2 where m2.canal_id = c.id and c.tipo <> 'setor'),
           'silenciado', coalesce(me.silenciado, false),
           'ultima', (select jsonb_build_object('autor_id', u.autor_id, 'corpo', left(u.corpo, 160), 'tipo', u.tipo, 'em', u.criada_em)
                        from chat_mensagem u where u.canal_id = c.id and u.excluida_em is null order by u.criada_em desc limit 1),
           'nao_lidas', (select count(*) from chat_mensagem u where u.canal_id = c.id and u.excluida_em is null and u.autor_id <> auth.uid()
                           and u.criada_em > coalesce(me.ultima_leitura_em, me.entrou_em - interval '1 second', now() - interval '7 days'))
         )), '[]'::jsonb)
    from chat_canal c
    left join chat_canal_membro me on me.canal_id = c.id and me.usuario_id = auth.uid()
   where not c.arquivado and chat_pode_ver_canal(c.id);
$function$;
