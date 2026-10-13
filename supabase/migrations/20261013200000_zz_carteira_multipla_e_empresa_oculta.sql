create table if not exists public.zz_rota_provisoria_carteira (
  empresa_id uuid not null,
  usuario_id uuid not null,
  origem text not null default 'legado',
  criado_em timestamptz not null default now(),
  primary key (empresa_id, usuario_id)
);
alter table public.zz_rota_provisoria_carteira enable row level security;
revoke all on public.zz_rota_provisoria_carteira from anon, authenticated;

create temp table t_cli(id uuid, doc text);
create temp table t_csr(cliente_id uuid, usuario_id uuid);
create temp table t_bl(empresa_id uuid, doc text);
do $carga$
declare v_de int; v_lote jsonb;
begin
  v_de := 0;
  loop
    v_lote := fiscal_legado('cliente_setor_responsavel?select=cliente_id,colaborador_id&setor_id=eq.85aa9f03-b91d-4d25-9f6d-366c6fe2d813&colaborador_id=not.is.null&order=cliente_id&limit=1000&offset=' || v_de);
    exit when jsonb_array_length(v_lote) = 0;
    insert into t_csr select (r->>'cliente_id')::uuid, (r->>'colaborador_id')::uuid from jsonb_array_elements(v_lote) r;
    v_de := v_de + 1000;
  end loop;
  v_de := 0;
  loop
    v_lote := fiscal_legado('clientes?select=id,cnpj&order=id&limit=1000&offset=' || v_de);
    exit when jsonb_array_length(v_lote) = 0;
    insert into t_cli select (r->>'id')::uuid, regexp_replace(coalesce(r->>'cnpj',''),'\D','','g') from jsonb_array_elements(v_lote) r;
    v_de := v_de + 1000;
  end loop;
  v_de := 0;
  loop
    v_lote := fiscal_bl('you_clientes_para_fiscal?select=empresa_id,cnpj&order=empresa_id&limit=1000&offset=' || v_de);
    exit when jsonb_array_length(v_lote) = 0;
    insert into t_bl select (r->>'empresa_id')::uuid, regexp_replace(coalesce(r->>'cnpj',''),'\D','','g') from jsonb_array_elements(v_lote) r;
    v_de := v_de + 1000;
  end loop;
  insert into zz_rota_provisoria_carteira (empresa_id, usuario_id, origem)
  select distinct b.empresa_id, s.usuario_id, 'legado'
    from t_csr s join t_cli c on c.id = s.cliente_id and length(c.doc) >= 11
    join t_bl b on b.doc = c.doc
    join fiscal_usuario u on u.id = s.usuario_id
  on conflict do nothing;
end $carga$;
drop table t_cli; drop table t_csr; drop table t_bl;
delete from public.zz_rota_provisoria_carteira where usuario_id = 'dc7d203e-cba3-48f6-99b5-87a1eada0bd8';

insert into public.zz_rota_provisoria_vinculo (numero_chave, empresa_id, origem)
values ('5511978896683', '24c28aef-370b-40d5-ac82-8a03af6ea3e5', 'oculto:everaldo-nao-responsavel-2026-10-13')
on conflict (numero_chave, empresa_id) do update set origem = excluded.origem;
