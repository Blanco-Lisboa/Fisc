create or replace function public.fiscal_pode_enviar_contato(p_contato_id uuid)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select fiscal_e_servidor()
      or fiscal_pode('departamento_ver')
      or (fiscal_nivel() is not null and exists (
            select 1 from wa_contato k
             where k.id = p_contato_id and k.telefone_chave is not null
               and wa_rota_dono(k.telefone_chave) = auth.uid()));
$function$;

create or replace function public.fiscal_minhas_empresas()
 returns setof uuid language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select x from unnest(fiscal_empresas_da_you()) x
   where fiscal_pode('departamento_ver')
      or exists (select 1 from wa_rota_carteira k where k.dono_id = auth.uid() and k.empresa_id = x);
$function$;

create or replace function public.fiscal_pode_ver_empresa(p_empresa_id uuid)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select p_empresa_id = any(fiscal_empresas_da_you())
     and (fiscal_pode('departamento_ver')
          or exists (select 1 from wa_rota_carteira k where k.dono_id = auth.uid() and k.empresa_id = p_empresa_id));
$function$;

drop function if exists public.wa_painel_conversas();
create function public.wa_painel_conversas()
 returns table(conversa_id uuid, ultima_entrada timestamptz, empresas uuid[], natureza text, principal boolean,
               responsavel_nome text, ultima_direcao text, ultima_status text, dono_id uuid)
 language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select c.id,
         (select max(m.ocorrido_em) from wa_mensagem m where m.conversa_id = c.id and m.direcao = 'entrada'),
         coalesce((select array_agg(distinct (x->>'empresa_id')::uuid) from wa_rota_numero r, jsonb_array_elements(r.empresas) x
                    where r.telefone_chave = k.telefone_chave), '{}'),
         (select x->>'papel' from wa_rota_numero r, jsonb_array_elements(r.empresas) x where r.telefone_chave = k.telefone_chave limit 1),
         false,
         (select u.nome from fiscal_usuario u where u.id = wa_rota_dono(k.telefone_chave)),
         u.direcao, u.status,
         wa_rota_dono(k.telefone_chave)
    from wa_conversa c
    join wa_numero n on n.id = c.numero_id and n.provedor = 'meta_cloud'
    left join wa_contato k on k.id = c.contato_id
    left join lateral (select m.direcao, m.status from wa_mensagem m where m.conversa_id = c.id and m.apagada_em is null
                        order by m.ocorrido_em desc limit 1) u on true
   where c.estado <> 'arquivada' and (fiscal_e_servidor() or fiscal_nivel() is not null)
     and (c.grupo_meta_id is not null or wa_pode_ver_conversa(c.id));
$function$;
revoke all on function public.wa_painel_conversas() from public, anon;
grant execute on function public.wa_painel_conversas() to authenticated;
