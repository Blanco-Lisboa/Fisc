alter table public.chat_pedido add column if not exists visto_em timestamptz;
alter table public.chat_reuniao_participante add column if not exists visto_em timestamptz;

create or replace function public.chat_pendencias(p_setores uuid[] default '{}')
returns jsonb
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select case when not is_interno() then jsonb_build_object('avisos', 0, 'pedidos', 0, 'reunioes', 0) else jsonb_build_object(
    'avisos', (select count(*) from chat_aviso a
                where (a.escopo = 'central' or (a.escopo = 'setor' and a.setor_id = any(coalesce(p_setores, '{}'))))
                  and coalesce(a.autor_id, '00000000-0000-0000-0000-000000000000'::uuid) <> auth.uid()
                  and a.criado_em > now() - interval '60 days'
                  and not exists (select 1 from chat_aviso_visto v where v.aviso_id = a.id and v.usuario_id = auth.uid())),
    'pedidos', (select count(*) from chat_pedido p
                 where p.responsavel_id = auth.uid() and p.visto_em is null and p.status in ('aberto', 'em_andamento')
                   and coalesce(p.solicitante_id, '00000000-0000-0000-0000-000000000000'::uuid) <> auth.uid()),
    'reunioes', (select count(*) from chat_reuniao_participante rp join chat_reuniao r on r.id = rp.reuniao_id
                  where rp.usuario_id = auth.uid() and rp.visto_em is null and r.criado_por <> auth.uid()
                    and coalesce(r.fim, r.inicio, now()) >= now())) end;
$$;
revoke all on function public.chat_pendencias(uuid[]) from public, anon;
grant execute on function public.chat_pendencias(uuid[]) to authenticated;

create or replace function public.chat_marcar_visto(p_o_que text)
returns integer
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare n int := 0;
begin
  if not is_interno() then raise exception 'so usuario interno'; end if;
  if p_o_que = 'pedidos' then
    update chat_pedido set visto_em = now() where responsavel_id = auth.uid() and visto_em is null;
  elsif p_o_que = 'reunioes' then
    update chat_reuniao_participante set visto_em = now() where usuario_id = auth.uid() and visto_em is null;
  else
    raise exception 'opcao invalida';
  end if;
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public.chat_marcar_visto(text) from public, anon;
grant execute on function public.chat_marcar_visto(text) to authenticated;

drop policy if exists chat_reuniao_sel on public.chat_reuniao;
create policy chat_reuniao_sel on public.chat_reuniao for select to authenticated using ((is_interno() and criado_por = auth.uid()) or chat_ve_reuniao(id));
drop policy if exists chat_reuniao_participante_sel on public.chat_reuniao_participante;
create policy chat_reuniao_participante_sel on public.chat_reuniao_participante for select to authenticated
  using ((is_interno() and usuario_id = auth.uid()) or chat_ve_reuniao(reuniao_id));
