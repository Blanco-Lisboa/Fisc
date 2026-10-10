create table if not exists public.fiscal_api_bl_acesso (
  usuario_bl_id uuid primary key,
  nome text not null,
  ativo boolean not null default true,
  criado_em timestamptz not null default now()
);
alter table public.fiscal_api_bl_acesso enable row level security;
revoke all on public.fiscal_api_bl_acesso from anon, authenticated;

create table if not exists public.fiscal_api_bl_log (
  id bigint generated always as identity primary key,
  usuario_bl_id uuid,
  operacao text not null,
  alvo text,
  ok boolean not null,
  erro text,
  linhas int,
  em timestamptz not null default now()
);
create index if not exists fiscal_api_bl_log_em_ix on public.fiscal_api_bl_log (em desc);
alter table public.fiscal_api_bl_log enable row level security;
revoke all on public.fiscal_api_bl_log from anon, authenticated;

create or replace function public.fiscal_api_bl_pode(p_usuario uuid)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select fiscal_e_servidor() and exists (select 1 from fiscal_api_bl_acesso where usuario_bl_id = p_usuario and ativo)
$function$;
revoke all on function public.fiscal_api_bl_pode(uuid) from public, anon, authenticated;

create or replace function public.fiscal_api_bl_bloqueado(p_nome text)
 returns boolean language sql immutable set search_path to 'pg_catalog'
as $function$
  select p_nome is null or p_nome !~ '^[a-z_][a-z0-9_]*$'
      or p_nome ~ '(segredo|chave|senha|token|secret|hmac|vault)'
      or p_nome in ('fiscal_bl', 'fiscal_meta_config', 'fiscal_api_bl_pode', 'fiscal_api_bl_bloqueado')
      or p_nome like 'fiscal_api_bl_acesso%'
$function$;
revoke all on function public.fiscal_api_bl_bloqueado(text) from public, anon, authenticated;

create or replace function public.fiscal_api_bl_tabelas()
 returns jsonb language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select coalesce(jsonb_agg(jsonb_build_object('tabela', c.relname,
           'colunas', (select jsonb_agg(jsonb_build_object('nome', a.attname, 'tipo', format_type(a.atttypid, a.atttypmod)) order by a.attnum)
                         from pg_attribute a where a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped))
           order by c.relname), '[]')
    from pg_class c
   where c.relnamespace = 'public'::regnamespace and c.relkind in ('r', 'v', 'p')
     and not fiscal_api_bl_bloqueado(c.relname)
$function$;
revoke all on function public.fiscal_api_bl_tabelas() from public, anon, authenticated;

create or replace function public.fiscal_api_bl_funcoes()
 returns jsonb language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select coalesce(jsonb_agg(jsonb_build_object('funcao', p.proname, 'argumentos', pg_get_function_arguments(p.oid),
           'retorna', pg_get_function_result(p.oid)) order by p.proname), '[]')
    from pg_proc p
   where p.pronamespace = 'public'::regnamespace and p.prokind = 'f'
     and pg_get_function_result(p.oid) not in ('trigger', 'event_trigger')
     and not fiscal_api_bl_bloqueado(p.proname)
$function$;
revoke all on function public.fiscal_api_bl_funcoes() from public, anon, authenticated;
