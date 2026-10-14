create or replace function public.wa_ligacoes(p_limite int default 300)
returns table (id uuid, conversa_id uuid, direcao text, estado text, midia text, criado_em timestamptz, inicio_em timestamptz,
               fim_em timestamptz, duracao_s int, atendente_nome text, contato_nome text, telefone text, erro text)
language sql stable security definer set search_path = public, pg_temp as $$
  select ch.id, ch.conversa_id, ch.direcao, ch.estado, ch.midia, ch.criado_em, ch.inicio_em, ch.fim_em,
         coalesce(ch.duracao_s, case when ch.inicio_em is not null and ch.fim_em is not null then extract(epoch from ch.fim_em - ch.inicio_em)::int end),
         u.nome,
         coalesce((select d.nome from wa_canal_diretoria d where d.numero_chave = wa_telefone_chave(c.contato_telefone)),
                  zz_rota_provisoria_nome(wa_telefone_chave(c.contato_telefone)), c.contato_nome),
         c.contato_telefone, ch.erro
    from wa_chamada ch
    join wa_conversa c on c.id = ch.conversa_id
    left join fiscal_usuario u on u.id = ch.atendente_id
   where fiscal_nivel() is not null and wa_pode_ver_conversa(ch.conversa_id)
   order by ch.criado_em desc
   limit least(greatest(coalesce(p_limite, 300), 1), 1000);
$$;
revoke execute on function public.wa_ligacoes(int) from public, anon;
grant execute on function public.wa_ligacoes(int) to authenticated;
