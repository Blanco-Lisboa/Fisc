create table if not exists public.zz_numero_compartilhado_wa (
  numero_chave text primary key,
  nome text not null,
  criado_em timestamptz not null default now()
);
alter table public.zz_numero_compartilhado_wa enable row level security;
revoke all on public.zz_numero_compartilhado_wa from anon, authenticated;

insert into public.zz_numero_compartilhado_wa (numero_chave, nome) values
 ('5511958463911', 'Financeiro YOU'),
 ('5511947507951', 'ADM YOU'),
 ('5511986688508', 'Suporte YOU'),
 ('5511965670720', 'Legal YOU'),
 ('5511967761101', 'Societário YOU')
on conflict (numero_chave) do update set nome = excluded.nome;

create or replace function public.wa_rota_dono(p_telefone_chave text)
 returns uuid language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  with comp as (
         select u.id from zz_numero_compartilhado_wa s
          join fiscal_usuario u on u.id = auth.uid() and u.ativo
          where s.numero_chave = p_telefone_chave),
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
          where r.empresa_id is null and e.dono_id is not null)
  select coalesce((select id from comp),
                  (select usuario_id from prov),
                  case when not exists (select 1 from zz_numero_compartilhado_wa s where s.numero_chave = p_telefone_chave)
                        and (select count(distinct dono_id) from donos) = 1 then (select dono_id from donos limit 1) end);
$function$;

create or replace function public.zz_rota_provisoria_nome(p_telefone_chave text)
 returns text language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select coalesce((select nome from zz_numero_compartilhado_wa where numero_chave = p_telefone_chave),
                  (select nome from zz_rota_provisoria_wa where numero_chave = p_telefone_chave));
$function$;
revoke all on function public.zz_rota_provisoria_nome(text) from public, anon;
