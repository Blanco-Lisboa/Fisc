create or replace function public.wa_rota_dono(p_telefone_chave text)
 returns uuid language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  with comp as (
         select u.id from (select numero_chave from zz_numero_compartilhado_wa union select numero_chave from wa_canal_diretoria) s
          join fiscal_usuario u on u.id = auth.uid() and u.ativo
          where s.numero_chave = p_telefone_chave),
       empresas as (
         select v.empresa_id from zz_rota_provisoria_vinculo v where v.numero_chave = p_telefone_chave and v.origem not like 'oculto%'
         union select r.empresa_id from wa_rota_numero r where r.telefone_chave = p_telefone_chave and r.empresa_id is not null
         union select (e->>'empresa_id')::uuid from wa_rota_numero r, jsonb_array_elements(r.empresas) e where r.telefone_chave = p_telefone_chave),
       multi as (
         select u.id from fiscal_usuario u
          where u.id = auth.uid() and u.ativo
            and exists (select 1 from zz_rota_provisoria_carteira cc join empresas e on e.empresa_id = cc.empresa_id
                         where cc.usuario_id = u.id
                           and not exists (select 1 from zz_rota_provisoria_vinculo o where o.numero_chave = p_telefone_chave
                                             and o.empresa_id = cc.empresa_id and o.origem like 'oculto%'))),
       prov as (
         select z.usuario_id from zz_rota_provisoria_wa z
          join fiscal_usuario u on u.id = z.usuario_id and u.ativo
          where z.numero_chave = p_telefone_chave
            and not exists (select 1 from zz_numero_compartilhado_wa s where s.numero_chave = p_telefone_chave)),
       r as (select * from wa_rota_numero where telefone_chave = p_telefone_chave and resolvido_em is not null and not ambiguo),
       donos as (
         select e.dono_id from r join wa_rota_carteira e on e.empresa_id = r.empresa_id where e.dono_id is not null
         union
         select e.dono_id from r, jsonb_array_elements(r.empresas) x join wa_rota_carteira e on e.empresa_id = (x->>'empresa_id')::uuid
          where r.empresa_id is null and e.dono_id is not null),
       cart as (
         select cc.usuario_id from zz_rota_provisoria_carteira cc join empresas e on e.empresa_id = cc.empresa_id
          join fiscal_usuario u on u.id = cc.usuario_id and u.ativo
          where not exists (select 1 from zz_rota_provisoria_vinculo o where o.numero_chave = p_telefone_chave
                              and o.empresa_id = cc.empresa_id and o.origem like 'oculto%')
          order by cc.usuario_id limit 1)
  select coalesce((select id from comp),
                  (select id from multi),
                  (select usuario_id from prov),
                  case when not exists (select 1 from zz_numero_compartilhado_wa s where s.numero_chave = p_telefone_chave)
                        and (select count(distinct dono_id) from donos) = 1 then (select dono_id from donos limit 1) end,
                  (select usuario_id from cart));
$function$;
