create unique index if not exists fiscal_carteira_um_dono_ativo on public.fiscal_carteira (empresa_id) where ativo;

create or replace function public.fiscal_cnpj_valido(p text)
returns boolean
language plpgsql immutable
set search_path to 'public', 'pg_temp'
as $$
declare d int[]; s int; r int; i int;
  p1 int[] := array[5,4,3,2,9,8,7,6,5,4,3,2];
  p2 int[] := array[6,5,4,3,2,9,8,7,6,5,4,3,2];
begin
  if p is null or p !~ '^\d{14}$' or p ~ '^(\d)\1{13}$' then return false; end if;
  d := array(select substr(p, g, 1)::int from generate_series(1, 14) g);
  s := 0; for i in 1..12 loop s := s + d[i] * p1[i]; end loop;
  r := s % 11; if (case when r < 2 then 0 else 11 - r end) <> d[13] then return false; end if;
  s := 0; for i in 1..13 loop s := s + d[i] * p2[i]; end loop;
  r := s % 11; return (case when r < 2 then 0 else 11 - r end) = d[14];
end $$;

create or replace function public.fiscal_carteira_analisar(p_usuario uuid, p_linhas text[])
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_lin jsonb := '[]'; v_bruto text; v_dig text; v_cnpj text; v_corr boolean; i int;
  v_validos text[] := '{}'; v_lista text; v_you jsonb := '[]'; v_bl jsonb := '[]';
begin
  if not fiscal_e_servidor() and coalesce(fiscal_nivel(), '') not in ('assistente', 'gerente') then
    raise exception 'so gestor do Fiscal';
  end if;
  if not exists (select 1 from fiscal_usuario where id = p_usuario and ativo) then
    raise exception 'usuario do Fiscal nao encontrado';
  end if;
  if coalesce(array_length(p_linhas, 1), 0) > 5000 then raise exception 'planilha acima de 5000 linhas'; end if;

  for i in 1..coalesce(array_length(p_linhas, 1), 0) loop
    v_bruto := btrim(coalesce(p_linhas[i], ''));
    v_dig := regexp_replace(v_bruto, '\D', '', 'g');
    v_corr := false;
    if length(v_dig) between 11 and 13 then v_dig := lpad(v_dig, 14, '0'); v_corr := true; end if;
    v_cnpj := case when fiscal_cnpj_valido(v_dig) then v_dig end;
    v_lin := v_lin || jsonb_build_object('linha', i, 'original', v_bruto, 'cnpj', coalesce(v_cnpj, v_dig), 'valido', v_cnpj is not null,
                                         'zeros_completados', v_corr and v_cnpj is not null, 'vazio', v_bruto = '');
    if v_cnpj is not null and not v_cnpj = any(v_validos) then v_validos := v_validos || v_cnpj; end if;
  end loop;

  i := 1;
  while i <= coalesce(array_length(v_validos, 1), 0) loop
    select string_agg(x, ',') into v_lista from unnest(v_validos[i:i+149]) x;
    v_you := v_you || fiscal_bl('you_clientes_para_fiscal?select=empresa_id,razao_social,nome_fantasia,cnpj,ativa&cnpj=in.(' || v_lista || ')');
    v_bl := v_bl || fiscal_bl('empresa?select=id,razao_social,nome_fantasia,cnpj,ativo&cnpj=in.(' || v_lista || ','
            || (select string_agg('%22'||substr(x,1,2)||'.'||substr(x,3,3)||'.'||substr(x,6,3)||'/'||substr(x,9,4)||'-'||substr(x,13,2)||'%22', ',') from unnest(v_validos[i:i+149]) x) || ')');
    i := i + 150;
  end loop;

  return (
    select coalesce(jsonb_agg(r order by (r->>'linha')::int), '[]')
      from (
        select l || jsonb_build_object(
                 'situacao', s.situacao, 'empresa_id', s.empresa_id, 'empresa', s.empresa, 'dono', s.dono, 'dono_id', s.dono_id) r
          from jsonb_array_elements(v_lin) l
          cross join lateral (
            select
              case
                when (l->>'vazio')::boolean then 'vazio'
                when not (l->>'valido')::boolean then 'invalido'
                when exists (select 1 from jsonb_array_elements(v_lin) a
                              where (a->>'valido')::boolean and a->>'cnpj' = l->>'cnpj' and (a->>'linha')::int < (l->>'linha')::int) then 'repetido'
                when y.e is null and b.e is null then 'nao_encontrado'
                when y.e is null then 'sem_vinculo_you'
                when not coalesce((y.e->>'ativa')::boolean, true) then 'inativo'
                when k.usuario_id = p_usuario then 'ja_na_carteira'
                when k.usuario_id is not null then 'em_outra_carteira'
                else 'ok'
              end situacao,
              coalesce(y.e->>'empresa_id', b.e->>'id') empresa_id,
              coalesce(nullif(coalesce(y.e, b.e)->>'razao_social', ''), coalesce(y.e, b.e)->>'nome_fantasia') empresa,
              u.nome dono, k.usuario_id dono_id
            from (select 1) _
            left join lateral (select e from jsonb_array_elements(v_you) e where e->>'cnpj' = l->>'cnpj' limit 1) y on true
            left join lateral (select e from jsonb_array_elements(v_bl) e where regexp_replace(e->>'cnpj', '\D', '', 'g') = l->>'cnpj' limit 1) b on true
            left join fiscal_carteira k on k.ativo and k.empresa_id = (y.e->>'empresa_id')::uuid
            left join fiscal_usuario u on u.id = k.usuario_id
          ) s
      ) z);
end $$;
revoke all on function public.fiscal_carteira_analisar(uuid, text[]) from public, anon;
grant execute on function public.fiscal_carteira_analisar(uuid, text[]) to authenticated, service_role;

create or replace function public.fiscal_carteira_vincular(p_usuario uuid, p_empresas uuid[], p_transferir uuid[] default '{}')
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare v_you uuid[]; v_ruins uuid[]; v_conf uuid[]; v_novos int := 0; v_transf int := 0; e uuid; i int;
begin
  if not fiscal_e_servidor() and coalesce(fiscal_nivel(), '') not in ('assistente', 'gerente') then
    raise exception 'so gestor do Fiscal';
  end if;
  if not exists (select 1 from fiscal_usuario where id = p_usuario and ativo) then
    raise exception 'usuario do Fiscal nao encontrado';
  end if;
  p_empresas := array(select distinct x from unnest(coalesce(p_empresas, '{}')) x);
  p_transferir := array(select distinct x from unnest(coalesce(p_transferir, '{}')) x where x = any(p_empresas));
  if coalesce(array_length(p_empresas, 1), 0) = 0 then raise exception 'nenhum CNPJ para vincular'; end if;

  v_you := '{}'; i := 1;
  while i <= array_length(p_empresas, 1) loop
    select v_you || coalesce(array_agg((x->>'empresa_id')::uuid), '{}') into v_you
      from jsonb_array_elements(fiscal_bl('you_clientes_para_fiscal?select=empresa_id&ativa=eq.true&empresa_id=in.('
             || (select string_agg(y::text, ',') from unnest(p_empresas[i:i+149]) y) || ')')) x;
    i := i + 150;
  end loop;
  select coalesce(array_agg(x), '{}') into v_ruins from unnest(p_empresas) x where not x = any(v_you);
  if coalesce(array_length(v_ruins, 1), 0) > 0 then
    raise exception 'CNPJ sem vinculo ativo com a YOU ou inativo: %', array_length(v_ruins, 1);
  end if;
  select coalesce(array_agg(k.empresa_id), '{}') into v_conf
    from fiscal_carteira k where k.ativo and k.usuario_id <> p_usuario and k.empresa_id = any(p_empresas) and not k.empresa_id = any(p_transferir);
  if coalesce(array_length(v_conf, 1), 0) > 0 then
    raise exception 'CNPJ em outra carteira sem confirmacao de transferencia: %', array_length(v_conf, 1);
  end if;

  update fiscal_carteira set ativo = false, retirado_em = now()
   where ativo and usuario_id <> p_usuario and empresa_id = any(p_transferir);
  get diagnostics v_transf = row_count;

  foreach e in array p_empresas loop
    insert into fiscal_carteira (usuario_id, empresa_id, principal, atribuido_por, atribuido_em, retirado_em, ativo)
    values (p_usuario, e, true, auth.uid(), now(), null, true)
    on conflict (usuario_id, empresa_id) do update
      set ativo = true, retirado_em = null, atribuido_por = excluded.atribuido_por, atribuido_em = now()
      where not fiscal_carteira.ativo;
    if found then v_novos := v_novos + 1; end if;
  end loop;
  return jsonb_build_object('ok', true, 'vinculados', v_novos, 'transferidos', v_transf);
end $$;
revoke all on function public.fiscal_carteira_vincular(uuid, uuid[], uuid[]) from public, anon;
grant execute on function public.fiscal_carteira_vincular(uuid, uuid[], uuid[]) to authenticated, service_role;
