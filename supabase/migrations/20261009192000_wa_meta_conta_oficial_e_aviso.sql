alter table public.fiscal_config add column if not exists meta_waba_oficial text;
update public.fiscal_config set meta_waba_oficial = '1054069641023968' where meta_waba_oficial is null;

create or replace function public.wa_meta_conta_modelos()
 returns text language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$ select meta_waba_oficial from fiscal_config limit 1 $function$;
revoke all on function public.wa_meta_conta_modelos() from public, anon, authenticated;

create table if not exists public.wa_conta_meta (
  waba_id text primary key,
  nome text,
  revisao text,
  dados jsonb,
  atualizado_em timestamptz not null default now()
);
alter table public.wa_conta_meta enable row level security;
drop policy if exists wa_conta_meta_ler on public.wa_conta_meta;
create policy wa_conta_meta_ler on public.wa_conta_meta for select to authenticated using (fiscal_pode('wa_conta_ver'));
revoke insert, update, delete on public.wa_conta_meta from anon, authenticated;

delete from public.wa_numero_meta where waba_id is distinct from (select meta_waba_oficial from public.fiscal_config limit 1);
alter table public.wa_numero_meta drop constraint if exists wa_numero_meta_pkey;
alter table public.wa_numero_meta alter column numero_id drop not null;
alter table public.wa_numero_meta add constraint wa_numero_meta_pkey primary key (phone_number_id);

create or replace function public.wa_conta_meta_gravar(p_waba jsonb, p_numeros jsonb)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare f jsonb;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  if coalesce(p_waba->>'id', '') <> (select meta_waba_oficial from fiscal_config limit 1) then raise exception 'conta nao e a oficial'; end if;
  insert into wa_conta_meta (waba_id, nome, revisao, dados, atualizado_em)
  values (p_waba->>'id', p_waba->>'name', p_waba->>'account_review_status', p_waba, now())
  on conflict (waba_id) do update set nome = excluded.nome, revisao = excluded.revisao, dados = excluded.dados, atualizado_em = now();
  for f in select * from jsonb_array_elements(coalesce(p_numeros, '[]')) loop
    insert into wa_numero_meta (numero_id, phone_number_id, waba_id, waba_nome, waba_revisao, telefone, nome_exibido, nome_situacao,
                                qualidade, limite, situacao, verificacao, plataforma, vazao, conta_oficial, dados, atualizado_em)
    values ((select id from wa_numero where provedor = 'meta_cloud' and identificador = f->>'id' limit 1), f->>'id', p_waba->>'id',
            p_waba->>'name', p_waba->>'account_review_status', regexp_replace(coalesce(f->>'display_phone_number', ''), '\D', '', 'g'),
            f->>'verified_name', f->>'name_status', f->>'quality_rating',
            coalesce(f->'whatsapp_business_manager_messaging_limit'->>'current_limit', f->>'whatsapp_business_manager_messaging_limit', f->>'messaging_limit_tier'),
            f->>'status', f->>'code_verification_status', f->>'platform_type', f->'throughput'->>'level',
            (f->>'is_official_business_account')::boolean, f, now())
    on conflict (phone_number_id) do update set numero_id = excluded.numero_id, waba_id = excluded.waba_id, waba_nome = excluded.waba_nome,
      waba_revisao = excluded.waba_revisao, telefone = excluded.telefone, nome_exibido = excluded.nome_exibido,
      nome_situacao = excluded.nome_situacao, qualidade = excluded.qualidade, limite = excluded.limite, situacao = excluded.situacao,
      verificacao = excluded.verificacao, plataforma = excluded.plataforma, vazao = excluded.vazao,
      conta_oficial = excluded.conta_oficial, dados = excluded.dados, atualizado_em = now();
  end loop;
  return true;
end $function$;
revoke all on function public.wa_conta_meta_gravar(jsonb, jsonb) from public, anon, authenticated;
drop function if exists public.wa_numero_meta_gravar(uuid, jsonb, jsonb);

create or replace function public.wa_meta_painel()
 returns jsonb language plpgsql stable security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_waba text := (select meta_waba_oficial from fiscal_config limit 1);
begin
  if not fiscal_pode('wa_conta_ver') then raise exception 'sem permissao'; end if;
  return jsonb_build_object(
    'conta', (select jsonb_build_object('waba_id', c.waba_id, 'nome', c.nome, 'revisao', c.revisao, 'atualizado_em', c.atualizado_em)
                from wa_conta_meta c where c.waba_id = v_waba),
    'numero', (select to_jsonb(x) - 'dados' from wa_numero_meta x where x.waba_id = v_waba order by x.atualizado_em desc limit 1),
    'saude', (select to_jsonb(s) from wa_saude s join wa_numero_meta x on x.numero_id = s.numero_id and x.waba_id = v_waba limit 1),
    'pode_gerir', fiscal_pode('wa_modelo_gerir'),
    'modelos', coalesce((select jsonb_agg(jsonb_build_object('id', m.id, 'nome', m.nome, 'idioma', m.idioma, 'categoria', m.categoria,
        'estado', m.estado, 'motivo', m.motivo, 'qualidade', m.qualidade, 'em_uso', m.em_uso, 'componentes', m.componentes,
        'atualizado_em', m.atualizado_em, 'pedido_em', m.pedido_em,
        'pedido_por', (select u.nome from fiscal_usuario u where u.id = m.pedido_por)) order by m.nome)
        from wa_modelo m where m.waba_id = v_waba), '[]'),
    'avisos', coalesce((select jsonb_agg(jsonb_build_object('id', e.id, 'campo', e.campo, 'evento', e.evento, 'gravidade', e.gravidade,
        'titulo', e.titulo, 'explicacao', e.explicacao, 'recebido_em', e.recebido_em, 'ciente_em', e.ciente_em,
        'ciente_por', (select u.nome from fiscal_usuario u where u.id = e.ciente_por)) order by e.recebido_em desc)
        from (select * from wa_meta_evento ev
               where coalesce(ev.dados #>> '{phone_number_settings,phone_number_id}', ev.dados ->> 'phone_number_id') is null
                  or coalesce(ev.dados #>> '{phone_number_settings,phone_number_id}', ev.dados ->> 'phone_number_id')
                     in (select phone_number_id from wa_numero_meta where waba_id = v_waba)
               order by ev.recebido_em desc limit 300) e), '[]'),
    'acoes', coalesce((select jsonb_agg(jsonb_build_object('nome', a.nome, 'acao', a.acao, 'em', a.em,
        'por', (select u.nome from fiscal_usuario u where u.id = a.por)) order by a.em desc)
        from (select * from wa_modelo_acao order by em desc limit 100) a), '[]'));
end $function$;
revoke all on function public.wa_meta_painel() from public, anon;
grant execute on function public.wa_meta_painel() to authenticated;

do $$ declare d text; n text; begin
  d := pg_get_functiondef('public.wa_modelos_sincronizar(text)'::regprocedure);
  n := replace(d, '(select waba_nome from wa_numero_meta where waba_id = p_waba limit 1)', '(select nome from wa_conta_meta where waba_id = p_waba)');
  if n <> d then execute n; end if;
end $$;

do $$ begin
  if not exists (select 1 from vault.secrets where name = 'wa_meta_gestao_chave') then
    perform vault.create_secret(encode(extensions.gen_random_bytes(32), 'hex'), 'wa_meta_gestao_chave');
  end if;
end $$;

create or replace function public.wa_meta_gestao_chave_ok(p_chave text)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select coalesce(p_chave, '') <> '' and p_chave = (select decrypted_secret from vault.decrypted_secrets where name = 'wa_meta_gestao_chave');
$function$;
revoke all on function public.wa_meta_gestao_chave_ok(text) from public, anon, authenticated;

create or replace function public.wa_meta_evento_sincronizar_tg()
 returns trigger language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_chave text;
begin
  begin
    select decrypted_secret into v_chave from vault.decrypted_secrets where name = 'wa_meta_gestao_chave';
    perform net.http_post(
      url := 'https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/wa-meta-gestao',
      body := jsonb_build_object('acao', 'sincronizar'),
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-chave-interna', v_chave));
  exception when others then
    raise warning 'sincronizar meta falhou: %', sqlerrm;
  end;
  return null;
end $function$;
revoke all on function public.wa_meta_evento_sincronizar_tg() from public, anon, authenticated;
drop trigger if exists wa_meta_evento_sincronizar on public.wa_meta_evento;
create trigger wa_meta_evento_sincronizar after insert on public.wa_meta_evento for each row execute function public.wa_meta_evento_sincronizar_tg();

do $$ begin
  begin alter publication supabase_realtime add table public.wa_conta_meta; exception when duplicate_object then null; end;
end $$;
