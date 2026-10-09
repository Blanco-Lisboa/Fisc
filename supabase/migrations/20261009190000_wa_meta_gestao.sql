insert into public.fiscal_permissao (codigo, titulo, descricao, ordem) values
 ('wa_modelo_gerir', 'Gerir modelos da Meta', 'Pedir modelo novo à Meta, atualizar da Meta e ligar ou desligar o uso de um modelo.', 13)
on conflict (codigo) do update set titulo = excluded.titulo, descricao = excluded.descricao, ordem = excluded.ordem;
insert into public.fiscal_nivel_permissao (nivel, permissao)
select nivel, 'wa_modelo_gerir' from public.fiscal_nivel_permissao where permissao = 'wa_conta_ver'
on conflict do nothing;

create table if not exists public.wa_numero_meta (
  numero_id uuid primary key references public.wa_numero(id) on delete restrict,
  phone_number_id text not null,
  waba_id text,
  waba_nome text,
  waba_revisao text,
  telefone text,
  nome_exibido text,
  nome_situacao text,
  qualidade text,
  limite text,
  situacao text,
  verificacao text,
  plataforma text,
  vazao text,
  conta_oficial boolean,
  ligacao jsonb,
  dados jsonb,
  atualizado_em timestamptz not null default now()
);
alter table public.wa_numero_meta enable row level security;
drop policy if exists wa_numero_meta_ler on public.wa_numero_meta;
create policy wa_numero_meta_ler on public.wa_numero_meta for select to authenticated using (fiscal_pode('wa_conta_ver'));
revoke insert, update, delete on public.wa_numero_meta from anon, authenticated;

alter table public.wa_modelo add column if not exists em_uso boolean not null default true;
alter table public.wa_modelo add column if not exists qualidade text;
alter table public.wa_modelo add column if not exists pedido_por uuid;
alter table public.wa_modelo add column if not exists pedido_em timestamptz;

create table if not exists public.wa_modelo_acao (
  id bigint generated always as identity primary key,
  modelo_id uuid references public.wa_modelo(id) on delete restrict,
  nome text,
  acao text not null check (acao in ('pedido', 'pedido_recusado_meta', 'em_uso', 'fora_de_uso', 'sincronizado')),
  por uuid,
  dados jsonb,
  em timestamptz not null default now()
);
alter table public.wa_modelo_acao enable row level security;
drop policy if exists wa_modelo_acao_ler on public.wa_modelo_acao;
create policy wa_modelo_acao_ler on public.wa_modelo_acao for select to authenticated using (fiscal_pode('wa_conta_ver'));
revoke insert, update, delete on public.wa_modelo_acao from anon, authenticated;

create or replace function public.wa_meta_evento_aplicar_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if new.campo = 'message_template_quality_update' then
    update wa_modelo set qualidade = coalesce(new.dados->>'new_quality_score', qualidade), atualizado_em = now()
     where meta_id = new.dados->>'message_template_id';
  elsif new.campo = 'phone_number_quality_update' then
    update wa_numero_meta set qualidade = coalesce(new.dados->>'event', qualidade),
                              limite = coalesce(new.dados->>'current_limit', new.dados->>'messaging_limit_tier', limite),
                              atualizado_em = now()
     where phone_number_id = new.dados->>'display_phone_number' or telefone = regexp_replace(coalesce(new.dados->>'display_phone_number', ''), '\D', '', 'g');
  elsif new.campo = 'phone_number_name_update' then
    update wa_numero_meta set nome_situacao = coalesce(new.dados->>'decision', nome_situacao),
                              nome_exibido = coalesce(new.dados->>'requested_verified_name', nome_exibido), atualizado_em = now()
     where telefone = regexp_replace(coalesce(new.dados->>'display_phone_number', ''), '\D', '', 'g');
  end if;
  return null;
end $function$;
revoke all on function public.wa_meta_evento_aplicar_tg() from public, anon, authenticated;
drop trigger if exists wa_meta_evento_aplicar on public.wa_meta_evento;
create trigger wa_meta_evento_aplicar after insert on public.wa_meta_evento for each row execute function public.wa_meta_evento_aplicar_tg();

create or replace function public.wa_numero_meta_gravar(p_numero uuid, p_waba jsonb, p_fone jsonb)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  insert into wa_numero_meta (numero_id, phone_number_id, waba_id, waba_nome, waba_revisao, telefone, nome_exibido, nome_situacao,
                              qualidade, limite, situacao, verificacao, plataforma, vazao, conta_oficial, dados, atualizado_em)
  values (p_numero, p_fone->>'id', p_waba->>'id', p_waba->>'name', p_waba->>'account_review_status',
          regexp_replace(coalesce(p_fone->>'display_phone_number', ''), '\D', '', 'g'), p_fone->>'verified_name', p_fone->>'name_status',
          p_fone->>'quality_rating',
          coalesce(p_fone->'whatsapp_business_manager_messaging_limit'->>'current_limit', p_fone->>'whatsapp_business_manager_messaging_limit', p_fone->>'messaging_limit_tier'),
          p_fone->>'status', p_fone->>'code_verification_status', p_fone->>'platform_type', p_fone->'throughput'->>'level',
          (p_fone->>'is_official_business_account')::boolean, jsonb_build_object('waba', p_waba, 'numero', p_fone), now())
  on conflict (numero_id) do update set phone_number_id = excluded.phone_number_id, waba_id = excluded.waba_id,
    waba_nome = excluded.waba_nome, waba_revisao = excluded.waba_revisao, telefone = excluded.telefone,
    nome_exibido = excluded.nome_exibido, nome_situacao = excluded.nome_situacao, qualidade = excluded.qualidade,
    limite = excluded.limite, situacao = excluded.situacao, verificacao = excluded.verificacao, plataforma = excluded.plataforma,
    vazao = excluded.vazao, conta_oficial = excluded.conta_oficial, dados = excluded.dados, atualizado_em = now();
  return true;
end $function$;
revoke all on function public.wa_numero_meta_gravar(uuid, jsonb, jsonb) from public, anon, authenticated;

create or replace function public.wa_modelo_validar(p jsonb)
 returns jsonb language plpgsql immutable set search_path to 'pg_catalog'
as $function$
declare e text[] := '{}'; v_corpo text := coalesce(p->>'corpo', ''); v_n int; v_ex jsonb := coalesce(p->'exemplos', '[]'); b jsonb; v_cat text := p->>'categoria';
begin
  if coalesce(p->>'nome', '') !~ '^[a-z0-9_]+$' or length(p->>'nome') > 512 then e := array_append(e, 'Nome: só letras minúsculas, números e _.'::text); end if;
  if v_cat is null or v_cat not in ('UTILITY', 'MARKETING', 'AUTHENTICATION') then e := array_append(e, 'Escolha a categoria.'::text); end if;
  if coalesce(p->>'idioma', '') = '' then e := array_append(e, 'Escolha o idioma.'::text); end if;
  if length(v_corpo) = 0 then e := array_append(e, 'O texto é obrigatório.'::text); end if;
  if length(v_corpo) > 1024 then e := array_append(e, 'O texto passa de 1024 caracteres.'::text); end if;
  if length(coalesce(p->>'cabecalho', '')) > 60 then e := array_append(e, 'O cabeçalho passa de 60 caracteres.'::text); end if;
  if length(coalesce(p->>'rodape', '')) > 60 then e := array_append(e, 'O rodapé passa de 60 caracteres.'::text); end if;
  if v_corpo ~ '^\s*\{\{' or v_corpo ~ '\}\}\s*$' then e := array_append(e, 'O texto não pode começar nem terminar com lacuna.'::text); end if;
  select count(distinct m[1]) into v_n from regexp_matches(v_corpo, '\{\{([0-9]+)\}\}', 'g') m;
  if v_n > 0 and exists (select 1 from generate_series(1, v_n) i where position('{{' || i || '}}' in v_corpo) = 0) then
    e := array_append(e, 'As lacunas têm que ser {{1}}, {{2}}, {{3}}... sem pular.'::text);
  end if;
  if jsonb_array_length(v_ex) < v_n or exists (select 1 from jsonb_array_elements_text(v_ex) x where btrim(x) = '') then
    e := array_append(e, 'Preencha o exemplo de cada lacuna.'::text);
  end if;
  if jsonb_array_length(coalesce(p->'botoes', '[]')) > 10 then e := array_append(e, 'No máximo 10 botões.'::text); end if;
  for b in select * from jsonb_array_elements(coalesce(p->'botoes', '[]')) loop
    if coalesce(b->>'texto', '') = '' or length(b->>'texto') > 25 then e := array_append(e, 'Todo botão precisa de texto de até 25 caracteres.'::text); end if;
    if b->>'tipo' = 'URL' and coalesce(b->>'url', '') !~ '^https://' then e := array_append(e, 'Botão de link precisa de endereço https://.'::text); end if;
    if b->>'tipo' = 'PHONE_NUMBER' and coalesce(b->>'telefone', '') !~ '^\+?[0-9]{8,15}$' then e := array_append(e, 'Botão de ligar precisa de telefone com DDI.'::text); end if;
  end loop;
  return to_jsonb(e);
end $function$;
grant execute on function public.wa_modelo_validar(jsonb) to authenticated;

create or replace function public.wa_modelo_pedido_preparar(p jsonb)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_err jsonb; comp jsonb := '[]'; b jsonb; bts jsonb := '[]';
begin
  if not fiscal_pode('wa_modelo_gerir') then return jsonb_build_object('ok', false, 'erro', 'Sem permissão para pedir modelo.'); end if;
  v_err := wa_modelo_validar(p);
  if jsonb_array_length(v_err) > 0 then return jsonb_build_object('ok', false, 'erros', v_err); end if;
  if exists (select 1 from wa_modelo where nome = p->>'nome' and idioma = p->>'idioma') then
    return jsonb_build_object('ok', false, 'erros', jsonb_build_array('Já existe um modelo com esse nome.'));
  end if;
  if coalesce(p->>'cabecalho', '') <> '' then
    comp := comp || jsonb_build_object('type', 'HEADER', 'format', 'TEXT', 'text', p->>'cabecalho');
  end if;
  comp := comp || (jsonb_build_object('type', 'BODY', 'text', p->>'corpo')
    || case when jsonb_array_length(coalesce(p->'exemplos', '[]')) > 0
            then jsonb_build_object('example', jsonb_build_object('body_text', jsonb_build_array(p->'exemplos'))) else '{}'::jsonb end);
  if coalesce(p->>'rodape', '') <> '' then comp := comp || jsonb_build_object('type', 'FOOTER', 'text', p->>'rodape'); end if;
  for b in select * from jsonb_array_elements(coalesce(p->'botoes', '[]')) loop
    bts := bts || case b->>'tipo'
      when 'URL' then jsonb_build_object('type', 'URL', 'text', b->>'texto', 'url', b->>'url')
      when 'PHONE_NUMBER' then jsonb_build_object('type', 'PHONE_NUMBER', 'text', b->>'texto', 'phone_number', b->>'telefone')
      else jsonb_build_object('type', 'QUICK_REPLY', 'text', b->>'texto') end;
  end loop;
  if jsonb_array_length(bts) > 0 then comp := comp || jsonb_build_object('type', 'BUTTONS', 'buttons', bts); end if;
  return jsonb_build_object('ok', true, 'corpo', jsonb_build_object('name', p->>'nome', 'language', p->>'idioma',
    'category', p->>'categoria', 'components', comp));
end $function$;
revoke all on function public.wa_modelo_pedido_preparar(jsonb) from public, anon;
grant execute on function public.wa_modelo_pedido_preparar(jsonb) to authenticated;

create or replace function public.wa_modelo_pedido_resultado(p_por uuid, p_corpo jsonb, p_meta_id text, p_estado text, p_categoria text, p_erro text)
 returns jsonb language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_id uuid;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if p_meta_id is null then
    insert into wa_modelo_acao (nome, acao, por, dados) values (p_corpo->>'name', 'pedido_recusado_meta', p_por, jsonb_build_object('erro', left(p_erro, 1000)));
    return jsonb_build_object('ok', false);
  end if;
  insert into wa_modelo (meta_id, nome, idioma, categoria, estado, componentes, pedido_por, pedido_em, atualizado_em)
  values (p_meta_id, p_corpo->>'name', p_corpo->>'language', coalesce(p_categoria, p_corpo->>'category'), coalesce(p_estado, 'PENDING'),
          p_corpo->'components', p_por, now(), now())
  on conflict (meta_id) do update set estado = excluded.estado, atualizado_em = now()
  returning id into v_id;
  insert into wa_modelo_acao (modelo_id, nome, acao, por, dados) values (v_id, p_corpo->>'name', 'pedido', p_por, p_corpo);
  return jsonb_build_object('ok', true, 'id', v_id);
end $function$;
revoke all on function public.wa_modelo_pedido_resultado(uuid, jsonb, text, text, text, text) from public, anon, authenticated;

create or replace function public.wa_modelo_usar(p_modelo uuid, p_em_uso boolean)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare n int;
begin
  if not fiscal_pode('wa_modelo_gerir') then raise exception 'sem permissao'; end if;
  update wa_modelo set em_uso = p_em_uso, atualizado_em = now() where id = p_modelo and em_uso is distinct from p_em_uso;
  get diagnostics n = row_count;
  if n = 1 then
    insert into wa_modelo_acao (modelo_id, nome, acao, por) select id, nome, case when p_em_uso then 'em_uso' else 'fora_de_uso' end, auth.uid() from wa_modelo where id = p_modelo;
  end if;
  return n = 1;
end $function$;
revoke all on function public.wa_modelo_usar(uuid, boolean) from public, anon;
grant execute on function public.wa_modelo_usar(uuid, boolean) to authenticated;

create or replace function public.wa_meta_painel()
 returns jsonb language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
begin
  if not fiscal_pode('wa_conta_ver') then raise exception 'sem permissao'; end if;
  return jsonb_build_object(
    'numero', (select to_jsonb(x) - 'dados' from wa_numero_meta x join wa_numero n on n.id = x.numero_id and n.ativo and n.provedor = 'meta_cloud' order by x.atualizado_em desc limit 1),
    'saude', (select to_jsonb(s) from wa_saude s join wa_numero n on n.id = s.numero_id and n.ativo and n.provedor = 'meta_cloud' limit 1),
    'pode_gerir', fiscal_pode('wa_modelo_gerir'),
    'modelos', coalesce((select jsonb_agg(jsonb_build_object('id', m.id, 'nome', m.nome, 'idioma', m.idioma, 'categoria', m.categoria,
        'estado', m.estado, 'motivo', m.motivo, 'qualidade', m.qualidade, 'em_uso', m.em_uso, 'componentes', m.componentes,
        'atualizado_em', m.atualizado_em, 'pedido_em', m.pedido_em,
        'pedido_por', (select u.nome from fiscal_usuario u where u.id = m.pedido_por)) order by m.nome) from wa_modelo m), '[]'),
    'avisos', coalesce((select jsonb_agg(jsonb_build_object('id', e.id, 'campo', e.campo, 'evento', e.evento, 'gravidade', e.gravidade,
        'titulo', e.titulo, 'explicacao', e.explicacao, 'recebido_em', e.recebido_em, 'ciente_em', e.ciente_em,
        'ciente_por', (select u.nome from fiscal_usuario u where u.id = e.ciente_por)) order by e.recebido_em desc)
        from (select * from wa_meta_evento order by recebido_em desc limit 300) e), '[]'),
    'acoes', coalesce((select jsonb_agg(jsonb_build_object('nome', a.nome, 'acao', a.acao, 'em', a.em,
        'por', (select u.nome from fiscal_usuario u where u.id = a.por)) order by a.em desc)
        from (select * from wa_modelo_acao order by em desc limit 100) a), '[]'));
end $function$;
revoke all on function public.wa_meta_painel() from public, anon;
grant execute on function public.wa_meta_painel() to authenticated;

do $$ begin
  begin alter publication supabase_realtime add table public.wa_modelo; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.wa_numero_meta; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.wa_saude; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.wa_modelo_acao; exception when duplicate_object then null; end;
end $$;
