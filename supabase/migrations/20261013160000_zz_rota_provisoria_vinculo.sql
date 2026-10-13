create table if not exists public.zz_rota_provisoria_vinculo (
  numero_chave text not null,
  empresa_id uuid not null,
  origem text not null,
  criado_em timestamptz not null default now(),
  primary key (numero_chave, empresa_id)
);
alter table public.zz_rota_provisoria_vinculo enable row level security;
revoke all on public.zz_rota_provisoria_vinculo from anon, authenticated;

create temp table zz_cli(id uuid, doc text, f1 text, f2 text, f3 text, f4 text, f5 text, f6 text, f7 text);
create temp table zz_num(cliente_id uuid, n text);
create temp table zz_bl(empresa_id uuid, doc text);
do $carga$
declare v_de int; v_lote jsonb;
begin
  v_de := 0;
  loop
    v_lote := fiscal_legado('clientes?select=id,cnpj,contato_operacional_whatsapp,responsavel_legal_whatsapp,contato_operacional_ddd,contato_operacional_telefone,responsavel_legal_ddd,responsavel_legal_telefone,contato_2_ddd,contato_2_telefone,contato_financeiro_ddd,contato_financeiro_telefone&order=id&limit=1000&offset=' || v_de);
    exit when jsonb_array_length(v_lote) = 0;
    insert into zz_cli select (r->>'id')::uuid, regexp_replace(coalesce(r->>'cnpj', ''), '\D', '', 'g'),
      r->>'contato_operacional_whatsapp', r->>'responsavel_legal_whatsapp',
      coalesce(r->>'contato_operacional_ddd', '') || coalesce(r->>'contato_operacional_telefone', ''),
      coalesce(r->>'responsavel_legal_ddd', '') || coalesce(r->>'responsavel_legal_telefone', ''),
      coalesce(r->>'contato_2_ddd', '') || coalesce(r->>'contato_2_telefone', ''),
      coalesce(r->>'contato_financeiro_ddd', '') || coalesce(r->>'contato_financeiro_telefone', ''), null
      from jsonb_array_elements(v_lote) r;
    v_de := v_de + 1000;
  end loop;
  insert into zz_num select id, x from zz_cli, unnest(array[f1, f2, f3, f4, f5, f6]) x;
  v_de := 0;
  loop
    v_lote := fiscal_legado('clientes_contatos?select=cliente_id,numero&order=id&limit=1000&offset=' || v_de);
    exit when jsonb_array_length(v_lote) = 0;
    insert into zz_num select (r->>'cliente_id')::uuid, r->>'numero' from jsonb_array_elements(v_lote) r;
    v_de := v_de + 1000;
  end loop;
  v_de := 0;
  loop
    v_lote := fiscal_legado('wa_conversas?select=cliente_id,telefone&cliente_id=not.is.null&order=id&limit=1000&offset=' || v_de);
    exit when jsonb_array_length(v_lote) = 0;
    insert into zz_num select (r->>'cliente_id')::uuid, r->>'telefone' from jsonb_array_elements(v_lote) r;
    v_de := v_de + 1000;
  end loop;
  v_de := 0;
  loop
    v_lote := fiscal_bl('you_clientes_para_fiscal?select=empresa_id,cnpj&order=empresa_id&limit=1000&offset=' || v_de);
    exit when jsonb_array_length(v_lote) = 0;
    insert into zz_bl select (r->>'empresa_id')::uuid, regexp_replace(coalesce(r->>'cnpj', ''), '\D', '', 'g') from jsonb_array_elements(v_lote) r;
    v_de := v_de + 1000;
  end loop;
  insert into zz_rota_provisoria_vinculo (numero_chave, empresa_id, origem)
  select distinct k.chave, b.empresa_id, 'legado'
    from (select cliente_id, case when length(d) = 12 and substr(d, 5, 1) between '6' and '9' then substr(d, 1, 4) || '9' || substr(d, 5) else d end chave
            from (select cliente_id, case when length(x) in (10, 11) then '55' || x when length(x) in (12, 13) and x like '55%' then x end d
                    from (select cliente_id, regexp_replace(coalesce(n, ''), '\D', '', 'g') x from zz_num) a) b
           where d is not null) k
    join zz_cli c on c.id = k.cliente_id and length(c.doc) >= 11
    join zz_bl b on b.doc = c.doc
   where k.chave is not null
  on conflict do nothing;
end $carga$;
drop table zz_cli; drop table zz_num; drop table zz_bl;


create or replace function public.wa_conversa_empresas(p_conversa uuid)
 returns jsonb
 language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_chave text; v_contato uuid; v_ids uuid[]; v_lista text;
begin
  if not wa_pode_ver_conversa(p_conversa) then return '[]'::jsonb; end if;
  select k.telefone_chave, k.id into v_chave, v_contato
    from wa_conversa c join wa_contato k on k.id = c.contato_id where c.id = p_conversa;
  if v_chave is null then return '[]'::jsonb; end if;
  select array_agg(distinct x) into v_ids from (
    select z.empresa_id x from zz_rota_provisoria_vinculo z where z.numero_chave = v_chave
    union select r.empresa_id from wa_rota_numero r where r.telefone_chave = v_chave and r.empresa_id is not null
    union select (e->>'empresa_id')::uuid from wa_rota_numero r, jsonb_array_elements(r.empresas) e where r.telefone_chave = v_chave
    union select a.empresa_id from wa_pessoa_vinculo v join wa_vinculo_alcance a on a.vinculo_id = v.id
     where v.contato_id = v_contato and v.ativo and a.ativo and a.escopo = 'empresa' and a.empresa_id is not null) q
   where x is not null;
  if coalesce(array_length(v_ids, 1), 0) = 0 then return '[]'::jsonb; end if;
  select string_agg(x::text, ',') into v_lista from unnest(v_ids) x;
  return fiscal_bl('you_clientes_para_fiscal?select=empresa_id,razao_social,nome_fantasia,cnpj&order=razao_social&empresa_id=in.(' || v_lista || ')');
end $function$;
revoke all on function public.wa_conversa_empresas(uuid) from public, anon;
grant execute on function public.wa_conversa_empresas(uuid) to authenticated;
