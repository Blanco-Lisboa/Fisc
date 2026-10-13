CREATE OR REPLACE FUNCTION public.wa_conversa_empresas(p_conversa uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare v_chave text; v_contato uuid; v_ids uuid[]; v_lista text;
begin
  if not wa_pode_ver_conversa(p_conversa) then return '[]'::jsonb; end if;
  select k.telefone_chave, k.id into v_chave, v_contato
    from wa_conversa c join wa_contato k on k.id = c.contato_id where c.id = p_conversa;
  if v_chave is null then return '[]'::jsonb; end if;
  select array_agg(distinct x) into v_ids from (
    select z.empresa_id x from zz_rota_provisoria_vinculo z where z.numero_chave = v_chave and z.origem not like 'oculto%'
    union select r.empresa_id from wa_rota_numero r where r.telefone_chave = v_chave and r.empresa_id is not null
    union select (e->>'empresa_id')::uuid from wa_rota_numero r, jsonb_array_elements(r.empresas) e where r.telefone_chave = v_chave
    union select a.empresa_id from wa_pessoa_vinculo v join wa_vinculo_alcance a on a.vinculo_id = v.id
     where v.contato_id = v_contato and v.ativo and a.ativo and a.escopo = 'empresa' and a.empresa_id is not null) q
   where x is not null
     and not exists (select 1 from zz_rota_provisoria_vinculo o where o.numero_chave = v_chave and o.empresa_id = x and o.origem like 'oculto%');
  if coalesce(array_length(v_ids, 1), 0) = 0 then return '[]'::jsonb; end if;
  select string_agg(x::text, ',') into v_lista from unnest(v_ids) x;
  return fiscal_bl('you_clientes_para_fiscal?select=empresa_id,razao_social,nome_fantasia,cnpj&order=razao_social&empresa_id=in.(' || v_lista || ')');
end $function$;

CREATE OR REPLACE FUNCTION public.wa_rota_dono(p_telefone_chave text)
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  with comp as (
         select u.id from zz_numero_compartilhado_wa s
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
