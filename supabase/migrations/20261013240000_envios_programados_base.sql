insert into fiscal_permissao (codigo, titulo, descricao, ordem)
values ('wa_lote_gerir', 'Envios programados', 'Criar listas e envios em lote de modelos do WhatsApp, acompanhar, pausar e cancelar.', 90)
on conflict (codigo) do nothing;
insert into fiscal_nivel_permissao (nivel, permissao)
select n, 'wa_lote_gerir' from unnest(array['assistente', 'gerente']) n
on conflict do nothing;

alter table public.wa_numero
  add column if not exists lote_inicio time not null default '09:00',
  add column if not exists lote_fim time not null default '17:00',
  add column if not exists lote_dias smallint[] not null default '{1,2,3,4,5}',
  add column if not exists lote_teto_24h int not null default 1000,
  add column if not exists lote_onda_inicial int not null default 50,
  add column if not exists lote_onda int not null default 150,
  add column if not exists lote_margem_pct smallint not null default 80,
  add column if not exists lote_falha_max_pct smallint not null default 5;

create table if not exists public.wa_lista (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (length(btrim(nome)) between 3 and 80),
  criada_por uuid not null references public.fiscal_usuario(id),
  criada_em timestamptz not null default now(),
  alterada_em timestamptz not null default now(),
  arquivada_em timestamptz
);
create unique index if not exists wa_lista_nome_ativa on public.wa_lista (lower(btrim(nome))) where arquivada_em is null;

create table if not exists public.wa_lista_item (
  lista_id uuid not null references public.wa_lista(id) on delete cascade,
  empresa_id uuid not null,
  papel text references public.fiscal_papel_ordem(papel),
  pessoa_id uuid,
  incluida_por uuid not null references public.fiscal_usuario(id),
  incluida_em timestamptz not null default now(),
  primary key (lista_id, empresa_id),
  check (pessoa_id is null or papel is not null)
);

create table if not exists public.wa_lote (
  id uuid primary key default gen_random_uuid(),
  nome text not null check (length(btrim(nome)) between 3 and 100),
  lista_id uuid not null references public.wa_lista(id) on delete restrict,
  numero_id uuid not null references public.wa_numero(id),
  modelo_id uuid not null references public.wa_modelo(id),
  categoria_esperada text,
  referencia date not null check (referencia = date_trunc('month', referencia)::date),
  variaveis jsonb not null default '{}'::jsonb,
  um_por_telefone boolean not null default true,
  estado text not null default 'rascunho' check (estado in ('rascunho','agendado','enviando','aguardando_vaga','aguardando_horario','pausado','freio','concluido','cancelado')),
  motivo text,
  agendado_para timestamptz,
  acordar_em timestamptz,
  onda_atual int not null default 0,
  custo_previsto_centavos int,
  criado_por uuid not null references public.fiscal_usuario(id),
  confirmado_por uuid references public.fiscal_usuario(id),
  confirmado_em timestamptz,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);
create unique index if not exists wa_lote_unico_mes on public.wa_lote (lista_id, modelo_id, referencia) where estado not in ('cancelado', 'rascunho');

alter table public.wa_fila_saida
  add column if not exists lote_id uuid references public.wa_lote(id) on delete restrict,
  add column if not exists empresa_id uuid,
  add column if not exists pessoa_id uuid,
  add column if not exists papel_usado text,
  add column if not exists onda int,
  add column if not exists codigo_erro int,
  add column if not exists motivo text;
alter table public.wa_fila_saida drop constraint if exists wa_fila_saida_estado_ck;
alter table public.wa_fila_saida add constraint wa_fila_saida_estado_ck check (estado in ('aguardando','processando','enviado','erro','cancelado','fora'));
alter table public.wa_fila_saida drop constraint if exists wa_fila_saida_conversa_id_fkey, add constraint wa_fila_saida_conversa_id_fkey foreign key (conversa_id) references public.wa_conversa(id) on delete set null;
alter table public.wa_fila_saida drop constraint if exists wa_fila_saida_mensagem_id_fkey, add constraint wa_fila_saida_mensagem_id_fkey foreign key (mensagem_id) references public.wa_mensagem(id) on delete set null;
create unique index if not exists wa_fila_saida_lote_empresa on public.wa_fila_saida (lote_id, empresa_id) where lote_id is not null;

alter table public.modelo_etapas
  add column if not exists wa_modelo_id uuid references public.wa_modelo(id),
  add column if not exists wa_lista_id uuid references public.wa_lista(id);

alter table public.wa_lista enable row level security;
alter table public.wa_lista_item enable row level security;
alter table public.wa_lote enable row level security;
drop policy if exists wa_lista_ler on public.wa_lista;
create policy wa_lista_ler on public.wa_lista for select using ((select fiscal_pode('wa_lote_gerir')));
drop policy if exists wa_lista_item_ler on public.wa_lista_item;
create policy wa_lista_item_ler on public.wa_lista_item for select using ((select fiscal_pode('wa_lote_gerir')));
drop policy if exists wa_lote_ler on public.wa_lote;
create policy wa_lote_ler on public.wa_lote for select using ((select fiscal_pode('wa_lote_gerir')));
drop policy if exists wa_fila_saida_ler on public.wa_fila_saida;
create policy wa_fila_saida_ler on public.wa_fila_saida for select using ((select fiscal_pode('wa_lote_gerir')));
revoke insert, update, delete, truncate on public.wa_lista, public.wa_lista_item, public.wa_lote, public.wa_fila_saida from anon, authenticated;
grant select on public.wa_lista, public.wa_lista_item, public.wa_lote, public.wa_fila_saida to authenticated;
alter publication supabase_realtime add table public.wa_lote, public.wa_fila_saida;

create or replace function public.wa_lote_bl_lote(p_recurso text, p_campo text, p_ids uuid[], p_select text)
 returns jsonb language plpgsql security definer set search_path to 'public', 'extensions', 'pg_temp'
as $function$
declare v_res jsonb := '[]'::jsonb; v_parte uuid[]; i int := 1; n int := coalesce(array_length(p_ids, 1), 0);
begin
  if n = 0 then return v_res; end if;
  perform extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '30000');
  while i <= n loop
    v_parte := p_ids[i:i + 79];
    v_res := v_res || coalesce(fiscal_bl(p_recurso || '?select=' || p_select || '&' || p_campo || '=in.(' ||
               (select string_agg(x::text, ',') from unnest(v_parte) x) || ')'), '[]'::jsonb);
    i := i + 80;
  end loop;
  return v_res;
end $function$;
revoke all on function public.wa_lote_bl_lote(text, text, uuid[], text) from public, anon, authenticated;

create or replace function public.wa_lote_checar() returns void language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$ begin
  if auth.uid() is null or fiscal_nivel() is null or not fiscal_pode('wa_lote_gerir') then raise exception 'sem permissao para envios programados'; end if;
end $function$;
revoke all on function public.wa_lote_checar() from public, anon;
grant execute on function public.wa_lote_checar() to authenticated;

create or replace function public.wa_listas()
 returns jsonb language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  perform wa_lote_checar();
  return coalesce((select jsonb_agg(jsonb_build_object('id', l.id, 'nome', l.nome, 'empresas', (select count(*) from wa_lista_item e where e.lista_id = l.id),
           'criada_em', l.criada_em, 'ultimo_envio', (select max(coalesce(t.confirmado_em, t.criado_em)) from wa_lote t where t.lista_id = l.id and t.estado <> 'rascunho'))
           order by l.nome) from wa_lista l where l.arquivada_em is null), '[]'::jsonb);
end $function$;

create or replace function public.wa_lista_salvar(p_id uuid, p_nome text)
 returns uuid language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v uuid;
begin
  perform wa_lote_checar();
  if coalesce(length(btrim(p_nome)), 0) < 3 then raise exception 'Dê um nome à lista (3 letras ou mais).'; end if;
  if exists (select 1 from wa_lista where lower(btrim(nome)) = lower(btrim(p_nome)) and arquivada_em is null and id is distinct from p_id) then
    raise exception 'Já existe uma lista com esse nome.'; end if;
  if p_id is null then insert into wa_lista (nome, criada_por) values (btrim(p_nome), auth.uid()) returning id into v;
  else update wa_lista set nome = btrim(p_nome), alterada_em = now() where id = p_id and arquivada_em is null returning id into v;
       if v is null then raise exception 'lista nao encontrada'; end if; end if;
  return v;
end $function$;

create or replace function public.wa_lista_arquivar(p_id uuid)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$ begin
  perform wa_lote_checar();
  if exists (select 1 from wa_lote where lista_id = p_id and estado in ('agendado','enviando','aguardando_vaga','aguardando_horario','pausado','freio')) then
    raise exception 'Há envio em andamento com esta lista.'; end if;
  update wa_lista set arquivada_em = now() where id = p_id and arquivada_em is null;
  return found;
end $function$;

create or replace function public.wa_lista_incluir(p_lista uuid, p_texto text, p_empresas uuid[] default null)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_cnpjs text[]; v_achadas jsonb := '[]'::jsonb; v_ids uuid[] := '{}'; v_ins int; v_ja int; v_nao text[]; i int; v_parte text[];
begin
  perform wa_lote_checar();
  if not exists (select 1 from wa_lista where id = p_lista and arquivada_em is null) then raise exception 'lista nao encontrada'; end if;
  select array_agg(distinct m[1]) into v_cnpjs from regexp_matches(regexp_replace(coalesce(p_texto, ''), '[.\-/]', '', 'g'), '(\d{14})', 'g') m;
  if coalesce(array_length(v_cnpjs, 1), 0) > 0 then
    perform extensions.http_set_curlopt('CURLOPT_TIMEOUT_MS', '30000');
    i := 1;
    while i <= array_length(v_cnpjs, 1) loop
      v_parte := v_cnpjs[i:i + 79];
      v_achadas := v_achadas || coalesce(fiscal_bl('you_clientes_para_fiscal?select=empresa_id,cnpj&ativa=eq.true&cnpj=in.(' || array_to_string(v_parte, ',') || ')'), '[]'::jsonb);
      i := i + 80;
    end loop;
    select array_agg(distinct (x->>'empresa_id')::uuid) into v_ids from jsonb_array_elements(v_achadas) x;
    select array_agg(c) into v_nao from unnest(v_cnpjs) c
     where not exists (select 1 from jsonb_array_elements(v_achadas) x where regexp_replace(x->>'cnpj', '\D', '', 'g') = c);
  end if;
  v_ids := coalesce(v_ids, '{}') || coalesce(p_empresas, '{}');
  select count(*) into v_ja from wa_lista_item where lista_id = p_lista and empresa_id = any(v_ids);
  insert into wa_lista_item (lista_id, empresa_id, incluida_por)
  select p_lista, x, auth.uid() from (select distinct unnest(v_ids) x) q where x is not null
  on conflict do nothing;
  get diagnostics v_ins = row_count;
  update wa_lista set alterada_em = now() where id = p_lista;
  return jsonb_build_object('incluidas', v_ins, 'ja_estavam', v_ja, 'nao_achados', coalesce(to_jsonb(v_nao), '[]'::jsonb));
end $function$;

create or replace function public.wa_lista_remover(p_lista uuid, p_empresas uuid[])
 returns int language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$ declare n int; begin
  perform wa_lote_checar();
  delete from wa_lista_item where lista_id = p_lista and empresa_id = any(p_empresas);
  get diagnostics n = row_count; update wa_lista set alterada_em = now() where id = p_lista; return n;
end $function$;

create or replace function public.wa_lista_destino(p_lista uuid, p_empresas uuid[], p_papel text, p_pessoa uuid default null)
 returns int language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$ declare n int; begin
  perform wa_lote_checar();
  if p_papel is not null and not exists (select 1 from fiscal_papel_ordem where papel = p_papel) then raise exception 'papel invalido'; end if;
  if p_pessoa is not null and array_length(p_empresas, 1) <> 1 then raise exception 'pessoa so pode ser escolhida para uma empresa por vez'; end if;
  update wa_lista_item set papel = p_papel, pessoa_id = case when p_papel is null then null else p_pessoa end
   where lista_id = p_lista and empresa_id = any(p_empresas);
  get diagnostics n = row_count; update wa_lista set alterada_em = now() where id = p_lista; return n;
end $function$;

create or replace function public.wa_lista_resolver(p_lista uuid)
 returns table(empresa_id uuid, bl_nome text, bl_doc text, papel text, pessoa_id uuid, pessoa_nome text, telefone text, situacao text, opcoes jsonb)
 language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_ids uuid[]; v_emp jsonb; v_pes jsonb;
begin
  select array_agg(e.empresa_id) into v_ids from wa_lista_item e where e.lista_id = p_lista;
  if v_ids is null then return; end if;
  v_emp := wa_lote_bl_lote('you_clientes_para_fiscal', 'empresa_id', v_ids, 'empresa_id,razao_social,nome_fantasia,cnpj');
  v_pes := wa_lote_bl_lote('you_pessoas_para_fiscal', 'empresa_id', v_ids, 'empresa_id,pessoa_id,nome,papel,whatsapp,ativa,vinculo_empresa_ativo');
  return query
  with le as (select * from wa_lista_item l where l.lista_id = p_lista),
  pes as (select (x->>'empresa_id')::uuid emp, (x->>'pessoa_id')::uuid pid, x->>'nome' nome, x->>'papel' papel,
                 nullif(regexp_replace(coalesce(x->>'whatsapp', ''), '\D', '', 'g'), '') wpp
            from jsonb_array_elements(v_pes) x
           where coalesce((x->>'ativa')::boolean, true) and coalesce((x->>'vinculo_empresa_ativo')::boolean, true)),
  esc as (
    select le.empresa_id, le.papel, e.pid, e.nome, e.wpp
      from le left join lateral (select p.pid, p.nome, p.wpp from pes p where p.emp = le.empresa_id and p.papel = coalesce(le.papel, 'quem_trata')
              and (le.pessoa_id is null or p.pid = le.pessoa_id) order by (p.wpp is null), p.nome limit 1) e on true)
  select esc.empresa_id,
         (select coalesce(x->>'razao_social', x->>'nome_fantasia') from jsonb_array_elements(v_emp) x where (x->>'empresa_id')::uuid = esc.empresa_id limit 1),
         (select x->>'cnpj' from jsonb_array_elements(v_emp) x where (x->>'empresa_id')::uuid = esc.empresa_id limit 1),
         coalesce(esc.papel, case when esc.pid is not null then 'quem_trata' end),
         esc.pid, esc.nome,
         case when esc.wpp is null then null else esc.wpp end,
         case when not exists (select 1 from jsonb_array_elements(v_emp) x where (x->>'empresa_id')::uuid = esc.empresa_id) then 'empresa_inativa'
              when esc.pid is null then 'escolher'
              when esc.wpp is null then 'sem_whatsapp'
              else 'ok' end,
         coalesce((select jsonb_agg(jsonb_build_object('pessoa_id', p.pid, 'nome', p.nome, 'papel', p.papel, 'tem_whatsapp', p.wpp is not null) order by p.papel, p.nome)
                     from pes p where p.emp = esc.empresa_id), '[]'::jsonb)
    from esc;
end $function$;
revoke all on function public.wa_lista_resolver(uuid) from public, anon, authenticated;

create or replace function public.wa_lista_ver(p_lista uuid)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  perform wa_lote_checar();
  return coalesce((select jsonb_agg(jsonb_build_object('empresa_id', r.empresa_id, 'razao_social', r.bl_nome, 'cnpj', r.bl_doc,
            'papel', r.papel, 'pessoa_id', r.pessoa_id, 'pessoa_nome', r.pessoa_nome,
            'telefone', case when r.telefone is null then null else '•••• ' || right(r.telefone, 4) end,
            'situacao', r.situacao, 'opcoes', r.opcoes) order by r.situacao <> 'escolher', r.bl_nome)
          from wa_lista_resolver(p_lista) r), '[]'::jsonb);
end $function$;

create or replace function public.wa_lote_vars(p_modelo uuid)
 returns int[] language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select coalesce(array_agg(distinct m[1]::int order by m[1]::int), '{}')
    from wa_modelo w, jsonb_array_elements(w.componentes) c, regexp_matches(coalesce(c->>'text', ''), '\{\{(\d+)\}\}', 'g') m
   where w.id = p_modelo and c->>'type' = 'BODY';
$function$;
revoke all on function public.wa_lote_vars(uuid) from public, anon;
grant execute on function public.wa_lote_vars(uuid) to authenticated;

create or replace function public.wa_lote_salvar(p jsonb)
 returns uuid language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v uuid; m wa_modelo%rowtype; v_vars int[]; k int; v_ref date; v_num uuid; l wa_lote%rowtype; v_fonte text;
begin
  perform wa_lote_checar();
  select * into m from wa_modelo where id = nullif(p->>'modelo_id', '')::uuid;
  if m.id is null then raise exception 'Escolha o modelo.'; end if;
  if m.estado <> 'APPROVED' or not m.em_uso then raise exception 'O modelo precisa estar aprovado e em uso.'; end if;
  if m.categoria not in ('UTILITY') then raise exception 'Só modelos de utilidade podem ir em lote.'; end if;
  if not exists (select 1 from wa_lista where id = nullif(p->>'lista_id', '')::uuid and arquivada_em is null) then raise exception 'Escolha a lista.'; end if;
  if coalesce(p->>'referencia', '') = '' then raise exception 'Escolha o mês de referência.'; end if;
  v_ref := date_trunc('month', (p->>'referencia')::date)::date;
  if exists (select 1 from jsonb_array_elements(m.componentes) c where c->>'type' = 'HEADER' and c->>'format' in ('IMAGE', 'VIDEO', 'DOCUMENT')) then
    raise exception 'Modelo com arquivo no cabeçalho ainda não vai em lote.'; end if;
  v_vars := wa_lote_vars(m.id);
  foreach k in array v_vars loop
    v_fonte := p->'variaveis'->(k::text)->>'fonte';
    if v_fonte is null or v_fonte not in ('fixo', 'empresa_nome', 'empresa_cnpj', 'pessoa_nome', 'pessoa_primeiro_nome', 'mes_referencia', 'responsavel_nome', 'quem_confirma') then
      raise exception 'Preencha a variável {{%}} do modelo.', k; end if;
    if v_fonte = 'fixo' and coalesce(btrim(p->'variaveis'->(k::text)->>'valor'), '') = '' then raise exception 'Escreva o valor da variável {{%}}.', k; end if;
  end loop;
  if exists (select 1 from jsonb_object_keys(coalesce(p->'variaveis', '{}'::jsonb)) x where not (x ~ '^\d+$' and x::int = any(v_vars))) then
    raise exception 'Há variável que o modelo não tem.'; end if;
  select n.id into v_num from wa_numero n where n.provedor = 'meta_cloud' and n.ativo order by n.criado_em limit 1;
  if v_num is null then raise exception 'numero da Meta nao encontrado'; end if;
  v := nullif(p->>'id', '')::uuid;
  if v is not null then
    select * into l from wa_lote where id = v;
    if l.id is null then raise exception 'envio nao encontrado'; end if;
    if l.estado <> 'rascunho' then raise exception 'Só dá para editar envio em rascunho.'; end if;
    update wa_lote set nome = btrim(p->>'nome'), lista_id = (p->>'lista_id')::uuid, modelo_id = m.id, referencia = v_ref,
           variaveis = coalesce(p->'variaveis', '{}'::jsonb), um_por_telefone = coalesce((p->>'um_por_telefone')::boolean, true),
           agendado_para = nullif(p->>'agendado_para', '')::timestamptz, atualizado_em = now() where id = v;
  else
    insert into wa_lote (nome, lista_id, numero_id, modelo_id, referencia, variaveis, um_por_telefone, agendado_para, criado_por)
    values (btrim(coalesce(p->>'nome', '')), (p->>'lista_id')::uuid, v_num, m.id, v_ref, coalesce(p->'variaveis', '{}'::jsonb),
            coalesce((p->>'um_por_telefone')::boolean, true), nullif(p->>'agendado_para', '')::timestamptz, auth.uid())
    returning id into v;
  end if;
  return v;
end $function$;

create or replace function public.wa_lote_texto(p_lote uuid, p_empresa_nome text, p_doc text, p_pessoa text, p_resp text)
 returns text language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
declare l wa_lote%rowtype; t text; k text; f jsonb; v text; meses text[] := array['janeiro','fevereiro','março','abril','maio','junho','julho','agosto','setembro','outubro','novembro','dezembro'];
begin
  select * into l from wa_lote where id = p_lote;
  select c->>'text' into t from wa_modelo w, jsonb_array_elements(w.componentes) c where w.id = l.modelo_id and c->>'type' = 'BODY';
  for k, f in select * from jsonb_each(l.variaveis) loop
    v := case f->>'fonte' when 'fixo' then f->>'valor' when 'empresa_nome' then p_empresa_nome
           when 'empresa_cnpj' then regexp_replace(coalesce(p_doc, ''), '^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$', '\1.\2.\3/\4-\5')
           when 'pessoa_nome' then p_pessoa when 'pessoa_primeiro_nome' then split_part(btrim(coalesce(p_pessoa, '')), ' ', 1)
           when 'mes_referencia' then meses[extract(month from l.referencia)::int] || '/' || extract(year from l.referencia)::int
           when 'responsavel_nome' then p_resp
           when 'quem_confirma' then (select split_part(nome, ' ', 1) from fiscal_usuario where id = coalesce(l.confirmado_por, auth.uid())) end;
    t := replace(t, '{{' || k || '}}', coalesce(v, '{{' || k || '}}'));
  end loop;
  return t;
end $function$;
revoke all on function public.wa_lote_texto(uuid, text, text, text, text) from public, anon, authenticated;

create or replace function public.wa_lote_previa(p_lote uuid)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare l wa_lote%rowtype; v jsonb; n record;
begin
  perform wa_lote_checar();
  select * into l from wa_lote where id = p_lote;
  if l.id is null then raise exception 'envio nao encontrado'; end if;
  create temp table if not exists _wa_lote_r on commit drop as select * from wa_lista_resolver(l.lista_id) limit 0;
  truncate _wa_lote_r; insert into _wa_lote_r select * from wa_lista_resolver(l.lista_id);
  select count(*) total, count(*) filter (where situacao = 'ok') ok,
         count(*) filter (where situacao = 'escolher') escolher, count(*) filter (where situacao = 'sem_whatsapp') sem_wpp,
         count(*) filter (where situacao = 'empresa_inativa') inativas,
         count(*) filter (where situacao = 'ok') - count(distinct telefone) filter (where situacao = 'ok') repetidos
    into n from _wa_lote_r;
  select coalesce(jsonb_agg(jsonb_build_object('empresa', x.bl_nome, 'texto', wa_lote_texto(p_lote, x.bl_nome, x.bl_doc, x.pessoa_nome,
            (select u.nome from zz_rota_provisoria_carteira cc join fiscal_usuario u on u.id = cc.usuario_id where cc.empresa_id = x.empresa_id limit 1)))), '[]'::jsonb)
    into v from (select * from _wa_lote_r where situacao = 'ok' order by bl_nome limit 3) x;
  return jsonb_build_object('total', n.total, 'entram', n.ok - case when l.um_por_telefone then n.repetidos else 0 end,
    'fora', jsonb_build_object('sem_destinatario', n.escolher, 'sem_whatsapp', n.sem_wpp, 'empresa_inativa', n.inativas,
                               'mesmo_telefone', case when l.um_por_telefone then n.repetidos else 0 end),
    'exemplos', v, 'saude', wa_lote_saude());
end $function$;

create or replace function public.wa_lote_saude()
 returns jsonb language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
declare nm record; v_teto int; v_usadas int; s record;
begin
  select n.id, n.lote_teto_24h, n.lote_margem_pct, n.lote_inicio, n.lote_fim, n.lote_dias, m.qualidade, m.limite, m.situacao, m.nome_exibido
    into nm from wa_numero n left join wa_numero_meta m on m.numero_id = n.id where n.provedor = 'meta_cloud' and n.ativo order by n.criado_em limit 1;
  v_teto := least(coalesce(case nm.limite when 'TIER_250' then 250 when 'TIER_1K' then 1000 when 'TIER_2K' then 2000 when 'TIER_10K' then 10000
                      when 'TIER_100K' then 100000 when 'TIER_UNLIMITED' then 1000000 end, 0) * nm.lote_margem_pct / 100, nm.lote_teto_24h);
  select count(distinct c.contato_id) into v_usadas from wa_mensagem w join wa_conversa c on c.id = w.conversa_id
   where w.direcao = 'saida' and w.dados ? 'modelo' and w.enviado_em > now() - interval '24 hours' and w.status <> 'falhou';
  select * into s from wa_saude limit 1;
  return jsonb_build_object('qualidade', nm.qualidade, 'limite', nm.limite, 'situacao', nm.situacao, 'teto_24h', v_teto, 'usadas_24h', v_usadas,
    'vagas', greatest(v_teto - v_usadas, 0), 'horario', to_char(nm.lote_inicio, 'HH24:MI') || '–' || to_char(nm.lote_fim, 'HH24:MI'), 'dias', nm.lote_dias,
    'bloqueado', coalesce((to_jsonb(s)->>'bloqueia_envio')::boolean, false));
end $function$;
revoke all on function public.wa_lote_saude() from public, anon;
grant execute on function public.wa_lote_saude() to authenticated;

create or replace function public.wa_lote_confirmar(p_lote uuid, p_quando timestamptz default null)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare l wa_lote%rowtype; m wa_modelo%rowtype; v_in int; v_fora int;
begin
  perform wa_lote_checar();
  select * into l from wa_lote where id = p_lote for update;
  if l.id is null then raise exception 'envio nao encontrado'; end if;
  if l.estado <> 'rascunho' then raise exception 'Este envio já foi confirmado.'; end if;
  select * into m from wa_modelo where id = l.modelo_id;
  if m.estado <> 'APPROVED' or not m.em_uso then raise exception 'O modelo deixou de estar aprovado.'; end if;
  if p_quando is not null and p_quando < now() then raise exception 'A data do agendamento já passou.'; end if;
  if exists (select 1 from wa_lote where lista_id = l.lista_id and modelo_id = l.modelo_id and referencia = l.referencia and estado not in ('cancelado', 'rascunho') and id <> l.id) then
    raise exception 'Já existe envio deste modelo para esta lista neste mês.'; end if;
  insert into wa_fila_saida (numero_id, id_local, prioridade, estado, lote_id, empresa_id, pessoa_id, papel_usado, motivo, disponivel_em)
  select l.numero_id, 'lote:' || l.id || ':' || r.empresa_id, 5,
         case when r.situacao <> 'ok' then 'fora'
              when l.um_por_telefone and row_number() over (partition by r.telefone order by r.bl_nome) > 1 then 'fora'
              else 'aguardando' end,
         l.id, r.empresa_id, r.pessoa_id, r.papel,
         case r.situacao when 'escolher' then 'sem destinatário escolhido' when 'sem_whatsapp' then 'destinatário sem WhatsApp'
              when 'empresa_inativa' then 'empresa inativa'
              else case when l.um_por_telefone and row_number() over (partition by r.telefone order by r.bl_nome) > 1 then 'mesmo telefone de outra empresa da lista' end end,
         coalesce(p_quando, now())
    from wa_lista_resolver(l.lista_id) r
  on conflict do nothing;
  select count(*) filter (where estado = 'aguardando'), count(*) filter (where estado = 'fora') into v_in, v_fora from wa_fila_saida where lote_id = l.id;
  if v_in = 0 then raise exception 'Nenhuma empresa da lista está pronta para receber.'; end if;
  update wa_lote set estado = 'agendado', agendado_para = coalesce(p_quando, now()), categoria_esperada = m.categoria,
         custo_previsto_centavos = ceil(v_in * 3.5)::int, confirmado_por = auth.uid(), confirmado_em = now(), atualizado_em = now() where id = l.id;
  return jsonb_build_object('entram', v_in, 'fora', v_fora);
end $function$;

create or replace function public.wa_lote_acao(p_lote uuid, p_acao text, p_motivo text default null)
 returns text language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare l wa_lote%rowtype; v_novo text;
begin
  perform wa_lote_checar();
  select * into l from wa_lote where id = p_lote for update;
  if l.id is null then raise exception 'envio nao encontrado'; end if;
  if p_acao = 'pausar' then
    if l.estado not in ('agendado','enviando','aguardando_vaga','aguardando_horario') then raise exception 'Este envio não pode ser pausado agora.'; end if;
    v_novo := 'pausado';
  elsif p_acao = 'retomar' then
    if l.estado not in ('pausado','freio') then raise exception 'Este envio não está pausado.'; end if;
    v_novo := 'agendado';
  elsif p_acao = 'cancelar' then
    if l.estado in ('concluido','cancelado') then raise exception 'Este envio já terminou.'; end if;
    update wa_fila_saida set estado = 'cancelado', motivo = 'envio cancelado' where lote_id = l.id and estado = 'aguardando';
    v_novo := 'cancelado';
  elsif p_acao = 'excluir_rascunho' then
    if l.estado <> 'rascunho' then raise exception 'Só rascunho pode ser apagado.'; end if;
    delete from wa_lote where id = l.id; return 'apagado';
  else raise exception 'acao invalida'; end if;
  update wa_lote set estado = v_novo, motivo = nullif(btrim(p_motivo), ''), atualizado_em = now() where id = l.id;
  return v_novo;
end $function$;

create or replace function public.wa_lotes()
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  perform wa_lote_checar();
  return coalesce((select jsonb_agg(jsonb_build_object('id', l.id, 'nome', l.nome, 'estado', l.estado, 'motivo', l.motivo, 'referencia', l.referencia,
      'lista', li.nome, 'lista_id', l.lista_id, 'modelo', w.nome, 'modelo_id', l.modelo_id, 'agendado_para', l.agendado_para, 'confirmado_em', l.confirmado_em,
      'criado_em', l.criado_em, 'criado_por', u.nome, 'variaveis', l.variaveis, 'um_por_telefone', l.um_por_telefone, 'custo_previsto_centavos', l.custo_previsto_centavos,
      'n', (select jsonb_build_object(
              'aguardando', count(*) filter (where f.estado = 'aguardando'), 'processando', count(*) filter (where f.estado = 'processando'),
              'fora', count(*) filter (where f.estado = 'fora'), 'cancelado', count(*) filter (where f.estado = 'cancelado'),
              'erro', count(*) filter (where f.estado = 'erro' or ms.status = 'falhou'),
              'enviado', count(*) filter (where ms.status in ('enviada','entregue','lida')),
              'entregue', count(*) filter (where ms.status in ('entregue','lida')), 'lido', count(*) filter (where ms.status = 'lida'),
              'respondeu', count(*) filter (where exists (select 1 from wa_mensagem e where e.conversa_id = ms.conversa_id and e.direcao = 'entrada' and e.ocorrido_em > ms.enviado_em)))
            from wa_fila_saida f left join wa_mensagem ms on ms.id = f.mensagem_id where f.lote_id = l.id))
      order by coalesce(l.confirmado_em, l.criado_em) desc)
    from wa_lote l join wa_lista li on li.id = l.lista_id join wa_modelo w on w.id = l.modelo_id left join fiscal_usuario u on u.id = l.criado_por), '[]'::jsonb);
end $function$;

create or replace function public.wa_lote_itens(p_lote uuid)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_ids uuid[]; v_emp jsonb;
begin
  perform wa_lote_checar();
  select array_agg(empresa_id) into v_ids from wa_fila_saida where lote_id = p_lote;
  v_emp := wa_lote_bl_lote('you_clientes_para_fiscal', 'empresa_id', coalesce(v_ids, '{}'), 'empresa_id,razao_social,nome_fantasia,cnpj');
  return coalesce((select jsonb_agg(jsonb_build_object('empresa_id', f.empresa_id,
       'empresa', (select coalesce(x->>'razao_social', x->>'nome_fantasia') from jsonb_array_elements(v_emp) x where (x->>'empresa_id')::uuid = f.empresa_id limit 1),
       'cnpj', (select x->>'cnpj' from jsonb_array_elements(v_emp) x where (x->>'empresa_id')::uuid = f.empresa_id limit 1),
       'estado', f.estado, 'status', ms.status, 'motivo', coalesce(f.motivo, ms.erro), 'papel', f.papel_usado, 'enviado_em', ms.enviado_em)
       order by f.estado, f.empresa_id)
     from wa_fila_saida f left join wa_mensagem ms on ms.id = f.mensagem_id where f.lote_id = p_lote), '[]'::jsonb);
end $function$;

do $$ declare f text; begin
  foreach f in array array['wa_listas()','wa_lista_salvar(uuid,text)','wa_lista_arquivar(uuid)','wa_lista_incluir(uuid,text,uuid[])','wa_lista_remover(uuid,uuid[])',
    'wa_lista_destino(uuid,uuid[],text,uuid)','wa_lista_ver(uuid)','wa_lote_salvar(jsonb)','wa_lote_previa(uuid)','wa_lote_confirmar(uuid,timestamptz)',
    'wa_lote_acao(uuid,text,text)','wa_lotes()','wa_lote_itens(uuid)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
