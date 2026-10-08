create table if not exists public.fiscal_nivel_def (
  nivel text primary key check (nivel ~ '^[a-z_]{1,30}$'),
  nome text not null,
  perfil text not null check (perfil in ('colaborador','gestor')),
  tela_inicial text not null,
  ordem int not null
);
create table if not exists public.fiscal_permissao (
  codigo text primary key check (codigo ~ '^[a-z0-9_]{1,40}$'),
  titulo text not null,
  descricao text not null default '',
  ordem int not null
);
create table if not exists public.fiscal_nivel_permissao (
  nivel text not null references public.fiscal_nivel_def(nivel) on delete cascade,
  permissao text not null references public.fiscal_permissao(codigo) on delete cascade,
  primary key (nivel, permissao)
);
alter table public.fiscal_nivel_def enable row level security;
alter table public.fiscal_permissao enable row level security;
alter table public.fiscal_nivel_permissao enable row level security;
revoke all on public.fiscal_nivel_def, public.fiscal_permissao, public.fiscal_nivel_permissao from anon, authenticated;
grant select on public.fiscal_nivel_def, public.fiscal_permissao, public.fiscal_nivel_permissao to authenticated;
create policy fiscal_nivel_def_ler on public.fiscal_nivel_def for select to authenticated using (fiscal_nivel() is not null);
create policy fiscal_permissao_ler on public.fiscal_permissao for select to authenticated using (fiscal_nivel() is not null);
create policy fiscal_nivel_permissao_ler on public.fiscal_nivel_permissao for select to authenticated using (fiscal_nivel() is not null);

insert into public.fiscal_nivel_def (nivel, nome, perfil, tela_inicial, ordem) values
 ('colaborador','Colaborador','colaborador','central',1),
 ('assistente','Assistente','gestor','gestor',2),
 ('gerente','Gerente','gestor','gestor',3)
on conflict (nivel) do update set nome=excluded.nome, perfil=excluded.perfil, tela_inicial=excluded.tela_inicial, ordem=excluded.ordem;

insert into public.fiscal_permissao (codigo, titulo, descricao, ordem) values
 ('central_colaborador','Central do colaborador','Ver o módulo Central.',1),
 ('painel_gestor','Painel do Gestor','Ver o Painel do Gestor: Central, Mapa do Departamento e Clientes.',2),
 ('departamento_ver','Ver o departamento inteiro','Ver todos os clientes, carteiras e pessoas do departamento, não só a própria carteira.',3),
 ('carteira_gerir','Montar carteiras','Colocar e tirar clientes da carteira de cada pessoa.',4),
 ('contato_vincular','Ligar contato a cliente','Dizer de quem é cada número de WhatsApp e de que empresas ele pode falar.',5),
 ('wa_entrada_responder','Responder conversa sem dono','Responder, mandar modelo ou arquivo para conversa nova que ainda não é de ninguém.',6),
 ('wa_conversa_qualquer','Organizar qualquer conversa','Fixar e organizar conversas de outras pessoas.',7),
 ('wa_grupo_criar','Criar grupo de WhatsApp','Montar grupo novo pelo número oficial.',8),
 ('wa_grupo_gerir','Cuidar dos grupos de WhatsApp','Link de convite, pedidos, participantes, editar e apagar grupo.',9)
on conflict (codigo) do update set titulo=excluded.titulo, descricao=excluded.descricao, ordem=excluded.ordem;

insert into public.fiscal_nivel_permissao (nivel, permissao)
select 'colaborador','central_colaborador'
union all select n, p from unnest(array['assistente','gerente']) n,
  unnest(array['painel_gestor','departamento_ver','carteira_gerir','contato_vincular','wa_entrada_responder','wa_conversa_qualquer','wa_grupo_criar','wa_grupo_gerir']) p
on conflict do nothing;

create or replace function public.fiscal_pode(p_permissao text)
 returns boolean language sql stable security definer set search_path to 'public','pg_temp'
as $$
  select exists (select 1 from fiscal_nivel_permissao np where np.nivel = fiscal_nivel() and np.permissao = p_permissao);
$$;
revoke all on function public.fiscal_pode(text) from public, anon;
grant execute on function public.fiscal_pode(text) to authenticated, service_role;

create or replace function public.fiscal_minhas_permissoes()
 returns jsonb language sql stable security definer set search_path to 'public','pg_temp'
as $$
  select jsonb_build_object(
    'nivel', d.nivel, 'nome', d.nome, 'perfil', d.perfil, 'tela_inicial', d.tela_inicial,
    'permissoes', coalesce((select jsonb_agg(np.permissao order by np.permissao) from fiscal_nivel_permissao np where np.nivel = d.nivel), '[]'::jsonb))
  from fiscal_nivel_def d where d.nivel = fiscal_nivel();
$$;
revoke all on function public.fiscal_minhas_permissoes() from public, anon;
grant execute on function public.fiscal_minhas_permissoes() to authenticated;

do $$
declare
  f record; d text; novo text;
  mapa constant jsonb := '{
    "fiscal_bl_tudo":"painel_gestor","fiscal_central_gestor":"painel_gestor","fiscal_clientes_painel":"painel_gestor","fiscal_mapa_departamento":"painel_gestor",
    "fiscal_carteira_analisar":"carteira_gerir","fiscal_carteira_detalhe":"carteira_gerir","fiscal_carteira_vincular":"carteira_gerir",
    "fiscal_exigir_acesso_vinculo":"contato_vincular","wa_contato_marcar":"contato_vincular","wa_contato_desmarcar":"contato_vincular","wa_ficha_conversa":"contato_vincular",
    "fiscal_minhas_empresas":"departamento_ver","fiscal_pode_ver_empresa":"departamento_ver","fiscal_pode_enviar_contato":"departamento_ver","fiscal_pessoas_da_empresa":"departamento_ver",
    "wa_meta_acao_preparar":"wa_grupo_gerir"}';
begin
  for f in select p.oid, p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and mapa ? p.proname loop
    d := pg_get_functiondef(f.oid);
    novo := d;
    novo := replace(novo, 'coalesce(fiscal_nivel(), '''') not in (''assistente'', ''gerente'')', 'not fiscal_pode(''' || (mapa->>f.proname) || ''')');
    novo := replace(novo, 'coalesce(fiscal_nivel(), '''') in (''assistente'', ''gerente'')', 'fiscal_pode(''' || (mapa->>f.proname) || ''')');
    novo := replace(novo, 'fiscal_nivel() not in (''assistente'', ''gerente'')', 'not fiscal_pode(''' || (mapa->>f.proname) || ''')');
    novo := replace(novo, 'fiscal_nivel() in (''assistente'', ''gerente'')', 'fiscal_pode(''' || (mapa->>f.proname) || ''')');
    novo := replace(novo, 'fiscal_nivel() in (''assistente'',''gerente'')', 'fiscal_pode(''' || (mapa->>f.proname) || ''')');
    if novo like '%''assistente''%' then raise exception 'sobrou nivel fixo em %', f.proname; end if;
    if novo = d then raise exception 'nada trocado em %', f.proname; end if;
    execute novo;
  end loop;
end $$;

alter policy fiscal_carteira_ler on public.fiscal_carteira using ((usuario_id = auth.uid()) or fiscal_pode('departamento_ver'));
alter policy fiscal_usuario_ler on public.fiscal_usuario using ((id = auth.uid()) or fiscal_pode('departamento_ver'));
alter policy fiscal_copia_legado_ler on public.fiscal_copia_legado using (fiscal_pode('departamento_ver'));

do $$ begin
  begin alter publication supabase_realtime add table public.fiscal_nivel_permissao; exception when duplicate_object then null; end;
end $$;
