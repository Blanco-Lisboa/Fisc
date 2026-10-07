create or replace function public.chat_resumo()
returns jsonb
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', c.id, 'tipo', c.tipo, 'nome', c.nome, 'descricao', c.descricao, 'setor_id', c.setor_id,
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
$$;
revoke all on function public.chat_resumo() from public, anon;
grant execute on function public.chat_resumo() to authenticated;
