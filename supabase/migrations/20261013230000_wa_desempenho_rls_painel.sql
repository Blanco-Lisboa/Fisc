create or replace function public.fiscal_acesso_wa()
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$ select fiscal_e_servidor() or fiscal_nivel() is not null $function$;
revoke all on function public.fiscal_acesso_wa() from public, anon;
grant execute on function public.fiscal_acesso_wa() to authenticated, service_role;

alter policy wa_conversa_ler on public.wa_conversa using (contato_id is not null and (select fiscal_acesso_wa()));
alter policy wa_contato_ler on public.wa_contato using ((select fiscal_acesso_wa()));
alter policy wa_mensagem_ler on public.wa_mensagem using ((select fiscal_acesso_wa()) and exists (
  select 1 from wa_conversa c where c.id = wa_mensagem.conversa_id and c.contato_id is not null));
alter policy wa_midia_ler on public.wa_midia using ((select fiscal_acesso_wa()) and exists (
  select 1 from wa_mensagem m join wa_conversa c on c.id = m.conversa_id where m.id = wa_midia.mensagem_id and c.contato_id is not null));
alter policy wa_conversa_etiqueta_ler on public.wa_conversa_etiqueta using ((select fiscal_acesso_wa()) and exists (
  select 1 from wa_conversa c where c.id = wa_conversa_etiqueta.conversa_id and c.contato_id is not null));
alter policy wa_conversa_evento_ler on public.wa_conversa_evento using ((select fiscal_acesso_wa()) and exists (
  select 1 from wa_conversa c where c.id = wa_conversa_evento.conversa_id and c.contato_id is not null));
alter policy wa_grupo_membro_historico_ler on public.wa_grupo_membro_historico using ((select fiscal_acesso_wa()) and exists (
  select 1 from wa_conversa c where c.id = wa_grupo_membro_historico.conversa_id and c.contato_id is not null));
alter policy wa_pessoa_vinculo_ler on public.wa_pessoa_vinculo using ((select fiscal_acesso_wa()));
alter policy wa_vinculo_evento_ler on public.wa_vinculo_evento using ((select fiscal_acesso_wa()));
alter policy wa_contato_preferencia_ler on public.wa_contato_preferencia using ((select fiscal_nivel()) is not null);
alter policy wa_chamada_permissao_ler on public.wa_chamada_permissao using ((select fiscal_nivel()) is not null);
alter policy wa_modelo_ler on public.wa_modelo using ((select fiscal_nivel()) is not null);
alter policy wa_rota_carteira_ler on public.wa_rota_carteira using ((select fiscal_nivel()) is not null);
alter policy wa_rota_numero_ler on public.wa_rota_numero using ((select fiscal_nivel()) is not null);

create or replace function public.wa_painel_conversas()
 returns table(conversa_id uuid, ultima_entrada timestamp with time zone, empresas uuid[], natureza text, principal boolean, responsavel_nome text, ultima_direcao text, ultima_status text, dono_id uuid, nome_provisorio text, arquivada boolean)
 language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  with acesso as (select fiscal_acesso_wa() ok, auth.uid() eu),
       base as (
    select c.id, c.e_grupo, c.grupo_meta_id, k.telefone_chave
      from wa_conversa c
      join wa_numero n on n.id = c.numero_id and n.provedor = 'meta_cloud'
      left join wa_contato k on k.id = c.contato_id
     where c.estado <> 'arquivada' and (select ok from acesso)
       and (c.grupo_meta_id is not null or c.contato_id is not null)),
       dono as (
    select b.*, case when b.e_grupo and b.grupo_meta_id is null then zz_grupo_dono(b.telefone_chave) else wa_rota_dono(b.telefone_chave) end d
      from base b)
  select b.id,
         (select max(m.ocorrido_em) from wa_mensagem m where m.conversa_id = b.id and m.direcao = 'entrada'),
         coalesce((select array_agg(distinct (x->>'empresa_id')::uuid) from wa_rota_numero r, jsonb_array_elements(r.empresas) x
                    where r.telefone_chave = b.telefone_chave), '{}'),
         (select x->>'papel' from wa_rota_numero r, jsonb_array_elements(r.empresas) x where r.telefone_chave = b.telefone_chave limit 1),
         false,
         case when b.e_grupo and b.grupo_meta_id is null
              then (select string_agg(u.nome, ', ' order by z.mensagens desc) from zz_grupo_provisorio_wa z
                      join fiscal_usuario u on u.id = z.usuario_id and u.ativo where z.grupo_chave = b.telefone_chave)
              else (select u.nome from fiscal_usuario u where u.id = b.d) end,
         u.direcao, u.status,
         b.d,
         case when not b.e_grupo and b.grupo_meta_id is null then zz_rota_provisoria_nome(b.telefone_chave) end,
         exists (select 1 from wa_conversa_arquivo_usuario a where a.conversa_id = b.id and a.usuario_id = (select eu from acesso))
    from dono b
    left join lateral (select m.direcao, m.status from wa_mensagem m where m.conversa_id = b.id and m.apagada_em is null
                        order by m.ocorrido_em desc limit 1) u on true;
$function$;
