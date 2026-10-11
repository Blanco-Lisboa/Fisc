create table if not exists public.zz_rota_provisoria_wa (
  numero_chave text primary key,
  usuario_id uuid not null,
  nome text,
  origem text not null default 'legado',
  criado_em timestamptz not null default now()
);
alter table public.zz_rota_provisoria_wa enable row level security;
revoke all on public.zz_rota_provisoria_wa from anon, authenticated;

create or replace function public.wa_rota_dono(p_telefone_chave text)
 returns uuid language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  with prov as (
         select z.usuario_id from zz_rota_provisoria_wa z
          join fiscal_usuario u on u.id = z.usuario_id and u.ativo
          where z.numero_chave = p_telefone_chave),
       r as (select * from wa_rota_numero where telefone_chave = p_telefone_chave and resolvido_em is not null and not ambiguo),
       donos as (
         select e.dono_id from r join wa_rota_carteira e on e.empresa_id = r.empresa_id where e.dono_id is not null
         union
         select e.dono_id from r, jsonb_array_elements(r.empresas) x join wa_rota_carteira e on e.empresa_id = (x->>'empresa_id')::uuid
          where r.empresa_id is null and e.dono_id is not null)
  select coalesce((select usuario_id from prov),
                  case when (select count(distinct dono_id) from donos) = 1 then (select dono_id from donos limit 1) end);
$function$;

create or replace function public.zz_rota_provisoria_nome(p_telefone_chave text)
 returns text language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select nome from zz_rota_provisoria_wa where numero_chave = p_telefone_chave;
$function$;
revoke all on function public.zz_rota_provisoria_nome(text) from public, anon;

drop function if exists public.wa_painel_conversas();
create function public.wa_painel_conversas()
 returns table(conversa_id uuid, ultima_entrada timestamp with time zone, empresas uuid[], natureza text, principal boolean, responsavel_nome text, ultima_direcao text, ultima_status text, dono_id uuid, nome_provisorio text)
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
         wa_rota_dono(k.telefone_chave),
         case when c.grupo_meta_id is null then zz_rota_provisoria_nome(k.telefone_chave) end
    from wa_conversa c
    join wa_numero n on n.id = c.numero_id and n.provedor = 'meta_cloud'
    left join wa_contato k on k.id = c.contato_id
    left join lateral (select m.direcao, m.status from wa_mensagem m where m.conversa_id = c.id and m.apagada_em is null
                        order by m.ocorrido_em desc limit 1) u on true
   where c.estado <> 'arquivada' and (fiscal_e_servidor() or fiscal_nivel() is not null)
     and (c.grupo_meta_id is not null or wa_pode_ver_conversa(c.id));
$function$;
revoke all on function public.wa_painel_conversas() from public, anon;
grant execute on function public.wa_painel_conversas() to authenticated, service_role;
