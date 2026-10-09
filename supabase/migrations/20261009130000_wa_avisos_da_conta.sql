create table if not exists public.wa_meta_evento_tipo (
  campo text not null,
  evento text not null,
  gravidade text not null check (gravidade in ('info', 'atencao', 'critico')),
  titulo text not null,
  explicacao text not null,
  primary key (campo, evento)
);

create table if not exists public.wa_meta_evento (
  id bigint generated always as identity primary key,
  campo text not null,
  evento text not null,
  gravidade text not null check (gravidade in ('info', 'atencao', 'critico')),
  titulo text not null,
  explicacao text not null,
  numero_id uuid references public.wa_numero(id) on delete restrict,
  dados jsonb not null,
  ciente_por uuid references public.fiscal_usuario(id) on delete restrict,
  ciente_em timestamptz,
  recebido_em timestamptz not null default now()
);
create index if not exists wa_meta_evento_recebido_ix on public.wa_meta_evento (recebido_em desc);
create index if not exists wa_meta_evento_pendente_ix on public.wa_meta_evento (gravidade) where ciente_em is null;
create index if not exists wa_meta_evento_numero_ix on public.wa_meta_evento (numero_id);
create index if not exists wa_meta_evento_ciente_ix on public.wa_meta_evento (ciente_por);

create table if not exists public.wa_contato_preferencia (
  contato_id uuid primary key references public.wa_contato(id) on delete restrict,
  aceita_marketing boolean not null default true,
  origem text,
  detalhe text,
  atualizado_em timestamptz not null default now()
);

alter table public.wa_meta_evento_tipo enable row level security;
alter table public.wa_meta_evento enable row level security;
alter table public.wa_contato_preferencia enable row level security;
revoke all on public.wa_meta_evento_tipo, public.wa_meta_evento, public.wa_contato_preferencia from anon, authenticated;
grant select on public.wa_meta_evento_tipo, public.wa_meta_evento, public.wa_contato_preferencia to authenticated;

insert into public.fiscal_permissao (codigo, titulo, descricao, ordem) values
 ('wa_conta_ver', 'Ver avisos da conta do WhatsApp', 'Ver os avisos da Meta sobre a conta, o número, os modelos e a segurança.', 13)
on conflict (codigo) do update set titulo = excluded.titulo, descricao = excluded.descricao, ordem = excluded.ordem;
insert into public.fiscal_nivel_permissao (nivel, permissao)
select n, 'wa_conta_ver' from unnest(array['assistente', 'gerente']) n
on conflict do nothing;

create policy wa_meta_evento_tipo_ler on public.wa_meta_evento_tipo for select to authenticated using (fiscal_pode('wa_conta_ver'));
create policy wa_meta_evento_ler on public.wa_meta_evento for select to authenticated using (fiscal_pode('wa_conta_ver'));
create policy wa_contato_preferencia_ler on public.wa_contato_preferencia for select to authenticated
  using (fiscal_nivel() is not null and fiscal_pode_ver_contato(contato_id));

insert into public.wa_meta_evento_tipo (campo, evento, gravidade, titulo, explicacao) values
 ('account_alerts', '*', 'atencao', 'Alerta da conta', 'A Meta mandou um alerta sobre a conta do WhatsApp. Ver o detalhe e agir se for preciso.'),
 ('account_review_update', 'APPROVED', 'info', 'Conta aprovada', 'A Meta terminou a revisão da conta do WhatsApp e aprovou.'),
 ('account_review_update', 'REJECTED', 'critico', 'Conta reprovada', 'A Meta reprovou a conta do WhatsApp na revisão. Os envios podem ser bloqueados.'),
 ('account_review_update', 'PENDING', 'info', 'Conta em revisão', 'A conta do WhatsApp está em revisão pela Meta.'),
 ('account_review_update', '*', 'atencao', 'Revisão da conta', 'A Meta mudou a situação da revisão da conta do WhatsApp.'),
 ('account_update', 'VERIFIED_ACCOUNT', 'info', 'Conta verificada', 'A Meta confirmou a verificação da conta do WhatsApp.'),
 ('account_update', 'ACCOUNT_VIOLATION', 'critico', 'Violação de regra', 'A Meta apontou que a conta quebrou uma regra de uso. Pode haver restrição de envio.'),
 ('account_update', 'ACCOUNT_RESTRICTION', 'critico', 'Conta com restrição', 'A Meta restringiu a conta: alguns envios ficam bloqueados por um tempo.'),
 ('account_update', 'ACCOUNT_DELETED', 'critico', 'Conta apagada', 'A conta do WhatsApp foi apagada na Meta.'),
 ('account_update', 'DISABLED_UPDATE', 'critico', 'Conta desativada', 'A Meta desativou ou mudou a situação de desativação da conta.'),
 ('account_update', 'PARTNER_ADDED', 'info', 'Parceiro adicionado', 'Um parceiro foi ligado à conta do WhatsApp.'),
 ('account_update', 'PARTNER_REMOVED', 'atencao', 'Parceiro removido', 'Um parceiro foi desligado da conta do WhatsApp.'),
 ('account_update', '*', 'atencao', 'Mudança na conta', 'A Meta avisou uma mudança na conta do WhatsApp.'),
 ('business_capability_update', '*', 'info', 'Limites da conta mudaram', 'A Meta mudou os limites da empresa (conversas por dia ou quantidade de números).'),
 ('business_status_update', '*', 'atencao', 'Situação da empresa mudou', 'A Meta mudou a situação da empresa no gerenciador de negócios.'),
 ('message_template_quality_update', 'GREEN', 'info', 'Modelo com qualidade alta', 'A qualidade de um modelo de mensagem subiu ou está alta.'),
 ('message_template_quality_update', 'YELLOW', 'atencao', 'Modelo com qualidade média', 'Clientes estão reclamando ou bloqueando depois de um modelo. Revisar o texto e para quem é enviado.'),
 ('message_template_quality_update', 'RED', 'critico', 'Modelo com qualidade baixa', 'Um modelo está com qualidade baixa e pode ser pausado ou desativado pela Meta.'),
 ('message_template_quality_update', '*', 'atencao', 'Qualidade de modelo mudou', 'A Meta mudou a nota de qualidade de um modelo de mensagem.'),
 ('message_template_status_update', 'APPROVED', 'info', 'Modelo aprovado', 'A Meta aprovou um modelo de mensagem. Já pode ser usado.'),
 ('message_template_status_update', 'REJECTED', 'atencao', 'Modelo reprovado', 'A Meta reprovou um modelo de mensagem. Ver o motivo.'),
 ('message_template_status_update', 'PAUSED', 'critico', 'Modelo pausado', 'A Meta pausou um modelo por baixa qualidade. Ele não pode ser enviado agora.'),
 ('message_template_status_update', 'DISABLED', 'critico', 'Modelo desativado', 'A Meta desativou um modelo. Ele não pode mais ser enviado.'),
 ('message_template_status_update', 'FLAGGED', 'atencao', 'Modelo sinalizado', 'A Meta sinalizou um modelo por queda de qualidade.'),
 ('message_template_status_update', 'PENDING_DELETION', 'atencao', 'Modelo sendo apagado', 'Um modelo está em processo de exclusão.'),
 ('message_template_status_update', '*', 'info', 'Situação de modelo mudou', 'A Meta mudou a situação de um modelo de mensagem.'),
 ('template_category_update', '*', 'atencao', 'Categoria de modelo mudou', 'A Meta mudou a categoria de um modelo (ex.: de utilidade para marketing). Isso muda o preço e as regras de envio.'),
 ('message_template_components_update', '*', 'info', 'Modelo alterado', 'O conteúdo de um modelo de mensagem foi alterado.'),
 ('phone_number_name_update', 'APPROVED', 'info', 'Nome de exibição aprovado', 'A Meta aprovou o nome que aparece para os clientes.'),
 ('phone_number_name_update', 'REJECTED', 'critico', 'Nome de exibição reprovado', 'A Meta reprovou o nome que aparece para os clientes. Ver o motivo e pedir de novo.'),
 ('phone_number_name_update', 'DEFERRED', 'atencao', 'Nome de exibição adiado', 'A Meta adiou a análise do nome de exibição.'),
 ('phone_number_name_update', '*', 'atencao', 'Nome de exibição', 'A Meta mudou a situação do nome de exibição do número.'),
 ('phone_number_quality_update', 'FLAGGED', 'critico', 'Qualidade do número caiu', 'A qualidade do número caiu. Se continuar, a Meta reduz o limite de envios.'),
 ('phone_number_quality_update', 'UNFLAGGED', 'info', 'Qualidade do número normalizou', 'A qualidade do número voltou ao normal.'),
 ('phone_number_quality_update', 'UPGRADE', 'info', 'Limite de envio aumentou', 'A Meta aumentou o limite de clientes por dia do número.'),
 ('phone_number_quality_update', 'DOWNGRADE', 'critico', 'Limite de envio diminuiu', 'A Meta diminuiu o limite de clientes por dia do número por queda de qualidade.'),
 ('phone_number_quality_update', '*', 'atencao', 'Qualidade do número', 'A Meta mudou a qualidade ou o limite do número.'),
 ('security', 'PIN_CHANGED', 'critico', 'PIN do número trocado', 'O PIN de confirmação em duas etapas do número foi trocado. Se não foi alguém da equipe, é preciso agir na hora.'),
 ('security', 'PIN_RESET_REQUEST', 'critico', 'Pedido para trocar o PIN', 'Alguém pediu para redefinir o PIN do número. Se não foi alguém da equipe, é preciso agir na hora.'),
 ('security', '*', 'critico', 'Aviso de segurança', 'A Meta mandou um aviso de segurança sobre o número.'),
 ('business_username_updates', '*', 'info', 'Nome de usuário da empresa', 'Mudou o nome de usuário da empresa no WhatsApp.'),
 ('flows', '*', 'atencao', 'Formulário do WhatsApp', 'A Meta avisou sobre um formulário (Flow) do WhatsApp.'),
 ('*', '*', 'info', 'Aviso da Meta', 'A Meta mandou um aviso que o sistema ainda não detalha. Ver os dados.')
on conflict (campo, evento) do update set gravidade = excluded.gravidade, titulo = excluded.titulo, explicacao = excluded.explicacao;

create or replace function public.wa_meta_conta_evento(p_campo text, v jsonb)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare v_ev text; t wa_meta_evento_tipo%rowtype; v_num uuid;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  v_ev := upper(coalesce(v->>'event', v->>'decision', v->'alert_info'->>'alert_type', v->>'new_quality_score', ''));
  select * into t from wa_meta_evento_tipo where campo = p_campo and evento = v_ev;
  if t.campo is null then select * into t from wa_meta_evento_tipo where campo = p_campo and evento = '*'; end if;
  if t.campo is null then select * into t from wa_meta_evento_tipo where campo = '*' and evento = '*'; end if;
  select id into v_num from wa_numero
   where provedor = 'meta_cloud'
     and (identificador = coalesce(v->'metadata'->>'phone_number_id', v->>'phone_number_id')
          or (coalesce(v->>'display_phone_number', v->>'phone_number') <> ''
              and telefone = regexp_replace(coalesce(v->>'display_phone_number', v->>'phone_number'), '\D', '', 'g')))
   limit 1;
  insert into wa_meta_evento (campo, evento, gravidade, titulo, explicacao, numero_id, dados)
  values (p_campo, coalesce(nullif(v_ev, ''), '-'), t.gravidade, t.titulo, t.explicacao, v_num, v);
end $function$;
revoke all on function public.wa_meta_conta_evento(text, jsonb) from public, anon, authenticated;

create or replace function public.wa_meta_preferencias(v jsonb)
 returns void language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare p jsonb; v_tel text; v_cont uuid;
begin
  if not fiscal_e_servidor() then raise exception 'so o servidor'; end if;
  for p in select * from jsonb_array_elements(coalesce(v->'user_preferences', '[]')) loop
    continue when coalesce(p->>'category', '') <> 'marketing_messages';
    v_tel := nullif(regexp_replace(coalesce(p->>'wa_id', ''), '\D', '', 'g'), '');
    continue when v_tel is null and nullif(p->>'user_id', '') is null;
    v_cont := wa_meta_contato(v_tel, nullif(p->>'user_id', ''), null, null);
    insert into wa_contato_preferencia (contato_id, aceita_marketing, origem, detalhe, atualizado_em)
    values (v_cont, lower(coalesce(p->>'value', '')) <> 'stop', 'cliente', p->>'detail', now())
    on conflict (contato_id) do update set aceita_marketing = excluded.aceita_marketing, origem = excluded.origem,
                                           detalhe = excluded.detalhe, atualizado_em = now();
  end loop;
end $function$;
revoke all on function public.wa_meta_preferencias(jsonb) from public, anon, authenticated;

create or replace function public.wa_meta_evento_ciente(p_evento bigint)
 returns boolean language plpgsql security definer set search_path to 'public', 'pg_temp'
as $function$
declare n int;
begin
  if not fiscal_pode('wa_conta_ver') then raise exception 'sem permissao'; end if;
  update wa_meta_evento set ciente_por = auth.uid(), ciente_em = now() where id = p_evento and ciente_em is null;
  get diagnostics n = row_count;
  return n = 1;
end $function$;
revoke all on function public.wa_meta_evento_ciente(bigint) from public, anon;
grant execute on function public.wa_meta_evento_ciente(bigint) to authenticated;

do $$ begin
  begin alter publication supabase_realtime add table public.wa_meta_evento; exception when duplicate_object then null; end;
end $$;

do $$
declare d text;
  a1 text := '      v := ch->''value'';
      begin
';
  b1 text := '      v := ch->''value'';
      begin
        if ch->>''field'' = ''user_preferences'' then
          perform wa_meta_preferencias(v);
          v_outros := v_outros + 1;
          continue;
        end if;
        if ch->>''field'' not in (''messages'', ''calls'') then
          perform wa_meta_conta_evento(ch->>''field'', v);
        end if;
';
  a2 text := '          insert into wa_webhook_falha (evento_id, campo, erro, trecho) values (v_ev, ch->>''field'', ''campo sem tratamento'', v);
          v_ign := v_ign + 1;
          continue;';
  b2 text := '          v_outros := v_outros + 1;
          continue;';
begin
  d := pg_get_functiondef('public.wa_meta_receber'::regproc);
  if position('wa_meta_conta_evento' in d) = 0 then
    if position(a1 in d) = 0 or position(a2 in d) = 0 then raise exception 'trechos do receber nao encontrados'; end if;
    d := replace(d, a1, b1);
    d := replace(d, a2, b2);
    execute d;
  end if;
end $$;

do $$
declare d text;
  a text := '    if md.id is null then
      return jsonb_build_object(''ok'', false, ''erro'', ''Modelo nao aprovado pela Meta.'');
    end if;';
  b text := '    if md.id is null then
      return jsonb_build_object(''ok'', false, ''erro'', ''Modelo nao aprovado pela Meta.'');
    end if;
    if upper(coalesce(md.categoria, '''')) = ''MARKETING''
       and exists (select 1 from wa_contato_preferencia pf where pf.contato_id = cv.contato_id and not pf.aceita_marketing) then
      return jsonb_build_object(''ok'', false, ''erro'', ''O cliente pediu para nao receber mensagens de propaganda.'');
    end if;';
begin
  d := pg_get_functiondef('public.wa_meta_preparar_envio'::regproc);
  if position('aceita_marketing' in d) = 0 then
    if position(a in d) = 0 then raise exception 'trecho do modelo nao encontrado'; end if;
    execute replace(d, a, b);
  end if;
end $$;
