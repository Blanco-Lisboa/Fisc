create table if not exists public.fiscal_cadastro_campo (
  chave text primary key check (chave ~ '^[a-z0-9_]+$'),
  categoria text not null check (categoria in ('identificacao', 'fiscal', 'acessos', 'certificados')),
  rotulo text not null,
  ordem int not null default 100,
  padrao boolean not null default false,
  fonte text,
  ativo boolean not null default true
);
alter table public.fiscal_cadastro_campo enable row level security;
drop policy if exists fiscal_cadastro_campo_ler on public.fiscal_cadastro_campo;
create policy fiscal_cadastro_campo_ler on public.fiscal_cadastro_campo for select to authenticated using (fiscal_nivel() is not null);
revoke insert, update, delete on public.fiscal_cadastro_campo from anon, authenticated;

insert into public.fiscal_cadastro_campo (chave, categoria, rotulo, ordem, padrao, fonte) values
 ('cnpj', 'identificacao', 'CNPJ', 10, true, 'empresa.cnpj'),
 ('municipio', 'identificacao', 'Município', 20, true, null),
 ('inscricao_municipal', 'identificacao', 'Inscrição municipal', 30, true, 'empresa.inscricao_municipal'),
 ('inscricao_estadual', 'identificacao', 'Inscrição estadual', 40, true, 'empresa.inscricao_estadual'),
 ('razao_social', 'identificacao', 'Razão social', 50, false, 'empresa.razao_social'),
 ('nome_fantasia', 'identificacao', 'Nome fantasia', 60, false, 'empresa.nome_fantasia'),
 ('natureza_juridica', 'identificacao', 'Natureza jurídica', 70, false, 'empresa.natureza_juridica'),
 ('atividade_principal', 'identificacao', 'Atividade principal', 80, false, 'empresa.atividade_principal'),
 ('situacao', 'identificacao', 'Situação', 90, false, 'empresa.situacao'),
 ('inicio', 'identificacao', 'Início das atividades', 100, false, 'empresa.inicio'),
 ('email_empresarial', 'identificacao', 'E-mail da empresa', 110, false, 'empresa.email_empresarial'),
 ('telefone', 'identificacao', 'Telefone da empresa', 120, false, 'empresa.telefone'),
 ('representante_legal', 'identificacao', 'Representante legal', 130, false, 'empresa.representante_legal'),
 ('rba', 'fiscal', 'RBA', 10, true, null),
 ('regime_tributario', 'fiscal', 'Regime tributário', 20, false, 'empresa.regime_tributario'),
 ('porte', 'fiscal', 'Porte', 30, false, 'empresa.porte'),
 ('segmento', 'fiscal', 'Segmento', 40, false, 'empresa.segmento'),
 ('cod_dominio', 'fiscal', 'Código no Domínio', 50, false, 'empresa.cod_dominio'),
 ('logins', 'acessos', 'Login''s', 10, true, null)
on conflict (chave) do update set categoria = excluded.categoria, rotulo = excluded.rotulo, ordem = excluded.ordem,
  padrao = excluded.padrao, fonte = excluded.fonte;

create or replace function public.fiscal_cadastro_campos()
 returns jsonb language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_meus jsonb;
begin
  if fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  select coalesce(valor, '[]') into v_meus from fiscal_usuario_pref where usuario_id = auth.uid() and chave = 'apu_cadastro_campos';
  v_meus := coalesce(v_meus, '[]');
  return coalesce((select jsonb_agg(jsonb_build_object('chave', c.chave, 'categoria', c.categoria, 'rotulo', c.rotulo,
           'padrao', c.padrao, 'meu', c.padrao or v_meus ? c.chave) order by c.categoria, c.ordem)
      from fiscal_cadastro_campo c where c.ativo), '[]');
end $function$;
revoke all on function public.fiscal_cadastro_campos() from public, anon;
grant execute on function public.fiscal_cadastro_campos() to authenticated;

create or replace function public.fiscal_cadastro_marcar(p_chave text, p_mostrar boolean)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v jsonb;
begin
  if fiscal_nivel() is null then raise exception 'sem acesso'; end if;
  if not exists (select 1 from fiscal_cadastro_campo where chave = p_chave and ativo and not padrao) then raise exception 'campo nao pode ser escolhido'; end if;
  select coalesce(valor, '[]') into v from fiscal_usuario_pref where usuario_id = auth.uid() and chave = 'apu_cadastro_campos';
  v := coalesce(v, '[]');
  v := case when p_mostrar then (case when v ? p_chave then v else v || to_jsonb(p_chave) end)
            else coalesce((select jsonb_agg(x) from jsonb_array_elements_text(v) x where x <> p_chave), '[]') end;
  insert into fiscal_usuario_pref (usuario_id, chave, valor, atualizado_em) values (auth.uid(), 'apu_cadastro_campos', v, now())
  on conflict (usuario_id, chave) do update set valor = excluded.valor, atualizado_em = now();
  return true;
end $function$;
revoke all on function public.fiscal_cadastro_marcar(text, boolean) from public, anon;
grant execute on function public.fiscal_cadastro_marcar(text, boolean) to authenticated;
