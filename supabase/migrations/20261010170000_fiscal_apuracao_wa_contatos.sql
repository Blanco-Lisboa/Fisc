create table if not exists public.fiscal_apuracao_wa_favorito (
  usuario_id uuid not null,
  empresa_id uuid not null,
  pessoa_id uuid not null,
  atualizado_em timestamptz not null default now(),
  primary key (usuario_id, empresa_id)
);
alter table public.fiscal_apuracao_wa_favorito enable row level security;
drop policy if exists fiscal_apuracao_wa_favorito_ler on public.fiscal_apuracao_wa_favorito;
create policy fiscal_apuracao_wa_favorito_ler on public.fiscal_apuracao_wa_favorito for select to authenticated using (usuario_id = auth.uid());
revoke insert, update, delete on public.fiscal_apuracao_wa_favorito from anon, authenticated;

create table if not exists public.fiscal_papel_ordem (
  papel text primary key,
  rotulo text not null,
  ordem int not null
);
alter table public.fiscal_papel_ordem enable row level security;
drop policy if exists fiscal_papel_ordem_ler on public.fiscal_papel_ordem;
create policy fiscal_papel_ordem_ler on public.fiscal_papel_ordem for select to authenticated using (fiscal_nivel() is not null);
revoke insert, update, delete on public.fiscal_papel_ordem from anon, authenticated;
insert into public.fiscal_papel_ordem (papel, rotulo, ordem) values
 ('quem_trata', 'Quem trata', 10), ('representante_legal', 'Representante legal', 20), ('titular', 'Titular', 30),
 ('socio', 'Sócio', 40), ('responsavel', 'Responsável', 50), ('familiar', 'Familiar', 60),
 ('funcionario', 'Funcionário', 70), ('terceiro', 'Terceiro', 80)
on conflict (papel) do update set rotulo = excluded.rotulo, ordem = excluded.ordem;

create or replace function public.fiscal_wa_chave_br(p_tel text)
 returns text language sql immutable set search_path to 'public', 'pg_catalog'
as $function$
  select wa_telefone_chave(case when d ~ '^[1-9][0-9]{9,10}$' then '55' || d else d end)
    from (select nullif(regexp_replace(coalesce(p_tel, ''), '\D', '', 'g'), '') d) x
$function$;

create or replace function public.fiscal_apuracao_wa_contatos(p_empresa uuid)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_fav uuid; v_lin jsonb;
begin
  if fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  if not exists (select 1 from fiscal_apuracao_carteira() x where x = p_empresa) then raise exception 'empresa fora da sua carteira'; end if;
  select pessoa_id into v_fav from fiscal_apuracao_wa_favorito where usuario_id = auth.uid() and empresa_id = p_empresa;
  v_lin := fiscal_bl('you_pessoas_para_fiscal?select=*&empresa_id=eq.' || p_empresa);
  return coalesce((
    select jsonb_agg(jsonb_build_object('pessoa_id', p.pessoa_id, 'nome', p.nome, 'papeis', p.papeis, 'rotulo', p.rotulo,
             'telefone', p.chave, 'conversa_id', cv.id, 'favorito', p.pessoa_id = v_fav)
           order by (p.pessoa_id = v_fav) desc, p.ordem, p.nome)
      from (select (r->>'pessoa_id')::uuid pessoa_id, max(r->>'nome') nome,
                   jsonb_agg(distinct r->>'papel') papeis,
                   (array_agg(coalesce(o.rotulo, r->>'papel') order by coalesce(o.ordem, 999)))[1] rotulo,
                   min(coalesce(o.ordem, 999)) ordem,
                   max(fiscal_wa_chave_br(r->>'whatsapp')) chave
              from jsonb_array_elements(v_lin) r left join fiscal_papel_ordem o on o.papel = r->>'papel'
             where r->>'pessoa_id' is not null
             group by 1) p
      left join lateral (select c.id from wa_conversa c join wa_numero n on n.id = c.numero_id and n.provedor = 'meta_cloud' and n.ativo
                          where p.chave is not null and wa_telefone_chave(c.contato_telefone) = p.chave and c.estado <> 'arquivada'
                          order by c.ultima_em desc nulls last limit 1) cv on true), '[]');
end $function$;
revoke all on function public.fiscal_apuracao_wa_contatos(uuid) from public, anon;
grant execute on function public.fiscal_apuracao_wa_contatos(uuid) to authenticated;

create or replace function public.fiscal_apuracao_wa_favoritar(p_empresa uuid, p_pessoa uuid)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  if not exists (select 1 from fiscal_apuracao_carteira() x where x = p_empresa) then raise exception 'empresa fora da sua carteira'; end if;
  if p_pessoa is null then
    delete from fiscal_apuracao_wa_favorito where usuario_id = auth.uid() and empresa_id = p_empresa;
    return true;
  end if;
  if not exists (select 1 from jsonb_array_elements(fiscal_bl('you_pessoas_para_fiscal?select=pessoa_id&empresa_id=eq.' || p_empresa || '&pessoa_id=eq.' || p_pessoa))) then
    raise exception 'pessoa nao ligada a esta empresa';
  end if;
  insert into fiscal_apuracao_wa_favorito (usuario_id, empresa_id, pessoa_id) values (auth.uid(), p_empresa, p_pessoa)
  on conflict (usuario_id, empresa_id) do update set pessoa_id = excluded.pessoa_id, atualizado_em = now();
  return true;
end $function$;
revoke all on function public.fiscal_apuracao_wa_favoritar(uuid, uuid) from public, anon;
grant execute on function public.fiscal_apuracao_wa_favoritar(uuid, uuid) to authenticated;

do $$
declare d text := pg_get_functiondef('public.fiscal_apuracao_wa_contatos(uuid)'::regprocedure);
begin
  d := replace(d, $a$'favorito', p.pessoa_id = v_fav)$a$, $b$'favorito', coalesce(p.pessoa_id = v_fav, false))$b$);
  d := replace(d, $a$order by (p.pessoa_id = v_fav) desc,$a$, $b$order by coalesce(p.pessoa_id = v_fav, false) desc,$b$);
  execute d;
end $$;
