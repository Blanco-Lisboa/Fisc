create table public.tipos_recorrencia (id uuid primary key default gen_random_uuid(), codigo text not null unique, nome text not null,
  exige_dias_mes boolean not null default false, exige_dia_anual boolean not null default false, exige_mes_anual boolean not null default false, exige_dias_semana boolean not null default false);
create table public.tipos_gatilho_momento (id uuid primary key default gen_random_uuid(), codigo text not null unique, nome text not null);
create table public.tipos_gatilho_acao (id uuid primary key default gen_random_uuid(), codigo text not null unique, nome text not null);
create table public.tipos_dependencia (id uuid primary key default gen_random_uuid(), codigo text not null unique, nome text not null);
create table public.tipos_libera_quando (id uuid primary key default gen_random_uuid(), codigo text not null unique, nome text not null);
create table public.tipos_canal_relato (id uuid primary key default gen_random_uuid(), codigo text not null unique, nome text not null);
create table public.regimes_tributarios (id uuid primary key default gen_random_uuid(), codigo text not null unique, nome text not null);
create table public.tipos_avanco_fase (id uuid primary key default gen_random_uuid(), codigo text not null unique, nome text not null, descricao text);
create table public.tipos_evento_historico (id uuid primary key default gen_random_uuid(), codigo text not null unique, nome text not null);

insert into public.tipos_recorrencia (codigo, nome, exige_dias_mes, exige_dia_anual, exige_mes_anual, exige_dias_semana) values
 ('nao_repete', 'Não repete', false, false, false, false), ('diario', 'Diário', false, false, false, false),
 ('dias_uteis', 'Dias úteis', false, false, false, true), ('mensal', 'Mensal', true, false, false, false), ('anual', 'Anual', false, true, true, false);
insert into public.tipos_gatilho_momento (codigo, nome) values ('ao_aplicar', 'Ao aplicar'), ('ao_concluir', 'Ao concluir');
insert into public.tipos_gatilho_acao (codigo, nome) values ('mensagem_cliente', 'Mensagem ao cliente'), ('alerta_interno', 'Alerta interno');
insert into public.tipos_dependencia (codigo, nome) values ('etapa_mesma_demanda', 'Etapa da mesma demanda'), ('modelo_outro', 'Outro modelo');
insert into public.tipos_libera_quando (codigo, nome) values ('inicio', 'Quando começar'), ('conclusao', 'Quando concluir');
insert into public.tipos_canal_relato (codigo, nome) values ('texto', 'Texto'), ('audio', 'Áudio'), ('presencial', 'Presencial');
insert into public.regimes_tributarios (codigo, nome) values ('simples_nacional', 'Simples Nacional'), ('mei', 'MEI'), ('lucro_presumido', 'Lucro Presumido'), ('lucro_real', 'Lucro Real');
insert into public.tipos_avanco_fase (codigo, nome, descricao) values
 ('manual', 'Manual', 'Colaborador aciona uma ação rápida ou marca na mão, sempre com justificativa.'),
 ('automatico_arquivo_detectado', 'Arquivo detectado', 'Avança sozinho quando um arquivo com o padrão esperado aparece nos documentos do cliente.'),
 ('automatico_mensagem_recebida', 'Mensagem recebida', 'Avança sozinho quando chega mensagem ou anexo novo na conversa de WhatsApp ligada à tarefa.'),
 ('automatico_dependencia_liberada', 'Dependência liberada', 'Avança sozinho quando a etapa da qual depende libera.'),
 ('automatico_integracao_externa', 'Integração externa', 'Avança sozinho por confirmação vinda de fora (só se a integração for autorizada e construída).');
insert into public.tipos_evento_historico (codigo, nome) values
 ('mudanca_fase_manual', 'Mudança de fase manual'), ('mudanca_fase_automatica', 'Mudança de fase automática'), ('cobranca_cliente', 'Cobrança ao cliente'),
 ('problema_informado', 'Problema informado'), ('relato_registrado', 'Relato registrado'), ('comentario', 'Comentário'),
 ('retificacao_zerada_solicitada', 'Retificação de zerada solicitada'), ('retificacao_zerada_decidida', 'Retificação de zerada decidida'),
 ('credencial_visualizada', 'Credencial visualizada'), ('outro', 'Outro');

create table public.motivos_atraso_catalogo (id uuid primary key default gen_random_uuid(), nome text not null, ativo boolean not null default true);
create table public.tags_catalogo (id uuid primary key default gen_random_uuid(), nome text not null, escopo text not null check (escopo in ('oficial', 'pessoal')),
  dono_usuario_id uuid, check ((escopo = 'pessoal') = (dono_usuario_id is not null)));
create table public.fases_processo (id uuid primary key default gen_random_uuid(), nome text not null, ordem smallint not null);

create table public.modelos (id uuid primary key default gen_random_uuid(), nome text not null check (length(trim(nome)) > 0), descricao text,
  dono_tipo text not null check (dono_tipo in ('oficial', 'pessoal')), criado_por uuid not null,
  status text not null default 'ativo' check (status in ('ativo', 'inativo', 'arquivado')),
  aparecer_filtro_clientes boolean not null default true, bloquear_se_regime_incompativel boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.modelo_etapas (id uuid primary key default gen_random_uuid(), modelo_id uuid not null references public.modelos(id) on delete cascade,
  ordem int not null, titulo text not null check (length(trim(titulo)) > 0), descricao text, logo_url text, link_url text, mensagem_envio text,
  fase_id uuid references public.fases_processo(id) on delete set null);
create index modelo_etapas_modelo_ix on public.modelo_etapas (modelo_id, ordem);
create table public.modelo_etapa_config (etapa_id uuid primary key references public.modelo_etapas(id) on delete cascade,
  recorrencia_tipo_id uuid references public.tipos_recorrencia(id), recorrencia_dia_anual smallint check (recorrencia_dia_anual between 1 and 31),
  recorrencia_mes_anual smallint check (recorrencia_mes_anual between 1 and 12), relatar_ativo boolean not null default false,
  relatar_destino_tipo text check (relatar_destino_tipo in ('interno', 'cliente')), relatar_destino_usuario_id uuid,
  exigir_confirmacao_sem_notas boolean not null default false, exigir_motivo_atraso boolean not null default false,
  aparecer_ficha_cliente boolean not null default false, habilitar_anotacoes boolean not null default false, permite_logo_link boolean not null default false,
  pergunta_ao_concluir_ativo boolean not null default false, pergunta_ao_concluir_texto text,
  pergunta_ao_concluir_modelo_destino_id uuid references public.modelos(id) on delete set null,
  criacao_automatica_bloqueada boolean not null default false);
create table public.modelo_etapa_relato_canais (etapa_id uuid not null references public.modelo_etapas(id) on delete cascade,
  canal_id uuid not null references public.tipos_canal_relato(id), primary key (etapa_id, canal_id));
create table public.modelo_etapa_recorrencia_dias_mes (etapa_id uuid not null references public.modelo_etapas(id) on delete cascade,
  dia smallint not null check (dia between 1 and 31), primary key (etapa_id, dia));
create table public.modelo_etapa_recorrencia_dias_semana (etapa_id uuid not null references public.modelo_etapas(id) on delete cascade,
  dia_semana smallint not null check (dia_semana between 0 and 6), primary key (etapa_id, dia_semana));
create table public.modelo_etapa_gatilhos (id uuid primary key default gen_random_uuid(), etapa_id uuid not null references public.modelo_etapas(id) on delete cascade,
  momento_id uuid not null references public.tipos_gatilho_momento(id), acao_id uuid not null references public.tipos_gatilho_acao(id), texto text, destino_usuario_id uuid);
create table public.modelo_etapa_checklist_itens (id uuid primary key default gen_random_uuid(), etapa_id uuid not null references public.modelo_etapas(id) on delete cascade,
  titulo text not null, ordem int not null);
create table public.modelo_etapa_dependencias (id uuid primary key default gen_random_uuid(), etapa_id uuid not null references public.modelo_etapas(id) on delete cascade,
  tipo_id uuid not null references public.tipos_dependencia(id), etapa_alvo_id uuid references public.modelo_etapas(id) on delete cascade,
  modelo_alvo_id uuid references public.modelos(id) on delete cascade, libera_quando_id uuid not null references public.tipos_libera_quando(id),
  espera_dias int not null default 0 check (espera_dias >= 0), espera_dias_uteis boolean not null default false,
  check (num_nonnulls(etapa_alvo_id, modelo_alvo_id) = 1));
create table public.modelo_regimes_permitidos (modelo_id uuid not null references public.modelos(id) on delete cascade,
  regime_id uuid not null references public.regimes_tributarios(id), primary key (modelo_id, regime_id));
create table public.modelo_tags (modelo_id uuid not null references public.modelos(id) on delete cascade,
  tag_id uuid not null references public.tags_catalogo(id) on delete cascade, primary key (modelo_id, tag_id));
create table public.modelo_etapa_opcoes_escolha (id uuid primary key default gen_random_uuid(), etapa_id uuid not null references public.modelo_etapas(id) on delete cascade,
  texto_opcao text not null, ordem int not null);
create table public.modelo_etapa_fases_status (id uuid primary key default gen_random_uuid(), etapa_id uuid not null references public.modelo_etapas(id) on delete cascade,
  nome text not null, ordem smallint not null, avanco_tipo_id uuid not null references public.tipos_avanco_fase(id),
  avanco_padrao_arquivo text, exigir_justificativa boolean not null default true);
create table public.modelo_etapa_acoes_rapidas (id uuid primary key default gen_random_uuid(),
  fase_id uuid not null references public.modelo_etapa_fases_status(id) on delete cascade, nome text not null, mensagem_texto text,
  mudar_para_fase_id uuid references public.modelo_etapa_fases_status(id) on delete set null,
  tipo_evento_id uuid not null references public.tipos_evento_historico(id), ordem int not null);

create table public.modelo_solicitacoes_padrao (id uuid primary key default gen_random_uuid(), modelo_id uuid not null references public.modelos(id) on delete cascade,
  solicitado_por uuid not null, solicitado_em timestamptz not null default now(),
  status text not null default 'pendente' check (status in ('pendente', 'aprovado', 'recusado')),
  decidido_por uuid, decidido_em timestamptz, motivo_recusa text);
create table public.modelo_compartilhamentos (id uuid primary key default gen_random_uuid(), modelo_id uuid not null references public.modelos(id) on delete cascade,
  compartilhado_com uuid not null, compartilhado_por uuid not null, compartilhado_em timestamptz not null default now(), unique (modelo_id, compartilhado_com));

create table public.apu_tarefa (id uuid primary key default gen_random_uuid(), empresa_id uuid not null,
  etapa_id uuid not null references public.modelo_etapas(id) on delete cascade, modelo_id uuid not null references public.modelos(id) on delete cascade,
  origem text not null check (origem in ('oficial', 'pessoal')), ciclo_referencia date,
  status_id uuid references public.modelo_etapa_fases_status(id) on delete set null, responsavel_id uuid, prazo date, prioridade text,
  motivo_atraso_id uuid references public.motivos_atraso_catalogo(id), motivo_atraso_texto text, zerada boolean not null default false, anotacoes text,
  relato_texto text, relato_em timestamptz, relato_por uuid, origem_atendimento_id uuid, ultima_interacao_cliente_em timestamptz,
  resposta_opcao_id uuid references public.modelo_etapa_opcoes_escolha(id) on delete set null,
  created_at timestamptz not null default now(), unique (empresa_id, etapa_id, ciclo_referencia));
create index apu_tarefa_empresa_ix on public.apu_tarefa (empresa_id, ciclo_referencia);
create index apu_tarefa_resp_ix on public.apu_tarefa (responsavel_id, ciclo_referencia);
create table public.tarefa_checklist_estado (tarefa_id uuid not null references public.apu_tarefa(id) on delete cascade,
  checklist_item_id uuid not null references public.modelo_etapa_checklist_itens(id) on delete cascade,
  concluido boolean not null default false, concluido_em timestamptz, concluido_por uuid, primary key (tarefa_id, checklist_item_id));
create table public.apu_tarefa_historico (id uuid primary key default gen_random_uuid(),
  tarefa_id uuid not null references public.apu_tarefa(id) on delete cascade, tipo_evento_id uuid not null references public.tipos_evento_historico(id),
  origem text not null check (origem in ('manual', 'automatico')), descricao text, justificativa text, usuario_id uuid,
  created_at timestamptz not null default now(), check ((origem = 'automatico') = (usuario_id is null)));
create index historico_tarefa_ix on public.apu_tarefa_historico (tarefa_id, created_at);
create table public.tarefa_zerada_retificacoes (id uuid primary key default gen_random_uuid(),
  tarefa_id uuid not null references public.apu_tarefa(id) on delete cascade, solicitado_por uuid not null,
  solicitado_em timestamptz not null default now(), motivo text not null,
  status text not null default 'pendente' check (status in ('pendente', 'aprovado', 'recusado')),
  revisado_por uuid, revisado_em timestamptz, decisao_observacao text);

create table public.apu_acesso_servico (id uuid primary key default gen_random_uuid(), empresa_id uuid not null, nome_servico text not null,
  usuario_login text, segredo_id uuid, criado_por uuid not null, criado_em timestamptz not null default now(), ativo boolean not null default true);
create table public.apu_acesso_servico_visto (id uuid primary key default gen_random_uuid(),
  credencial_id uuid not null references public.apu_acesso_servico(id) on delete cascade, visualizado_por uuid not null,
  visualizado_em timestamptz not null default now());

insert into public.fiscal_permissao (codigo, titulo, descricao, ordem) values
 ('criar_modelo_oficial', 'Criar demanda oficial', 'Criar modelo de demanda que vale para todo o Fiscal.', 20),
 ('editar_modelo_oficial', 'Editar demanda oficial', 'Editar modelo oficial e suas etapas.', 21),
 ('excluir_modelo_oficial', 'Excluir demanda oficial', 'Excluir modelo oficial (só quem criou).', 22),
 ('ativar_inativar_modelo_oficial', 'Ativar ou inativar demanda oficial', 'Ativar, inativar ou arquivar modelo oficial.', 23),
 ('repropagar_modelo', 'Repropagar demanda', 'Aplicar mudanças do modelo nas pendências já criadas.', 24),
 ('aprovar_solicitacao_padrao', 'Aprovar pedido de virar padrão', 'Aprovar modelo pessoal para virar oficial.', 25),
 ('recusar_solicitacao_padrao', 'Recusar pedido de virar padrão', 'Recusar modelo pessoal para virar oficial.', 26),
 ('aplicar_modelo_cliente', 'Aplicar demanda em cliente', 'Aplicar modelo em um cliente.', 27),
 ('aplicar_modelo_lote', 'Aplicar demanda em lote', 'Aplicar modelo em vários clientes de uma vez.', 28),
 ('remover_tarefa_de_cliente', 'Remover demanda de cliente', 'Tirar a aplicação de um modelo de um cliente.', 29),
 ('gerenciar_fases_processo', 'Cuidar das fases do processo', 'Criar e ordenar as fases da jornada mensal.', 30),
 ('gerenciar_motivos_atraso', 'Cuidar dos motivos de atraso', 'Criar e desativar motivos de atraso.', 31),
 ('gerenciar_tags_oficiais', 'Cuidar das tags oficiais', 'Criar e apagar tags oficiais.', 32),
 ('editar_campo_estrutural_tarefa_oficial', 'Editar campo estrutural de demanda oficial', 'Mudar campos estruturais de uma tarefa de demanda oficial.', 33),
 ('cadastrar_credencial_cliente', 'Cadastrar acesso de cliente', 'Cadastrar login e senha de serviço do cliente.', 34),
 ('revelar_credencial_cliente', 'Ver senha de cliente', 'Revelar senha cadastrada (fica registrado).', 35),
 ('decidir_retificacao_zerada', 'Decidir retificação de zerada', 'Aprovar ou recusar retificação de declaração zerada.', 36)
on conflict (codigo) do update set titulo = excluded.titulo, descricao = excluded.descricao, ordem = excluded.ordem;
insert into public.fiscal_nivel_permissao (nivel, permissao)
select n.nivel, p.codigo from (values ('assistente'), ('gerente')) n(nivel),
 (values ('criar_modelo_oficial'), ('editar_modelo_oficial'), ('excluir_modelo_oficial'), ('ativar_inativar_modelo_oficial'), ('repropagar_modelo'),
         ('aprovar_solicitacao_padrao'), ('recusar_solicitacao_padrao'), ('aplicar_modelo_cliente'), ('aplicar_modelo_lote'), ('remover_tarefa_de_cliente'),
         ('gerenciar_fases_processo'), ('gerenciar_motivos_atraso'), ('gerenciar_tags_oficiais'), ('editar_campo_estrutural_tarefa_oficial'),
         ('cadastrar_credencial_cliente'), ('revelar_credencial_cliente'), ('decidir_retificacao_zerada')) p(codigo)
union all
select 'colaborador', c from unnest(array['aplicar_modelo_cliente', 'aplicar_modelo_lote', 'remover_tarefa_de_cliente', 'cadastrar_credencial_cliente']) c
on conflict do nothing;

create or replace function public.apu_pode_ver_modelo(p_modelo uuid)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select fiscal_nivel() is not null and exists (
    select 1 from modelos m where m.id = p_modelo and (m.dono_tipo = 'oficial' or m.criado_por = auth.uid()
      or exists (select 1 from modelo_compartilhamentos c where c.modelo_id = m.id and c.compartilhado_com = auth.uid())))
$function$;
create or replace function public.apu_pode_ver_etapa(p_etapa uuid)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$ select apu_pode_ver_modelo((select modelo_id from modelo_etapas where id = p_etapa)) $function$;
create or replace function public.apu_pode_ver_empresa(p_empresa uuid)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$
  select fiscal_nivel() is not null and (fiscal_pode('departamento_ver') or exists (select 1 from fiscal_apuracao_carteira() x where x = p_empresa))
$function$;
create or replace function public.apu_pode_ver_tarefa(p_tarefa uuid)
 returns boolean language sql stable security definer set search_path to 'public', 'pg_temp'
as $function$ select apu_pode_ver_empresa((select empresa_id from apu_tarefa where id = p_tarefa)) $function$;
revoke all on function public.apu_pode_ver_modelo(uuid), public.apu_pode_ver_etapa(uuid), public.apu_pode_ver_empresa(uuid), public.apu_pode_ver_tarefa(uuid) from public, anon;
grant execute on function public.apu_pode_ver_modelo(uuid), public.apu_pode_ver_etapa(uuid), public.apu_pode_ver_empresa(uuid), public.apu_pode_ver_tarefa(uuid) to authenticated;

do $$
declare t text;
begin
  foreach t in array array['tipos_recorrencia','tipos_gatilho_momento','tipos_gatilho_acao','tipos_dependencia','tipos_libera_quando','tipos_canal_relato',
    'regimes_tributarios','tipos_avanco_fase','tipos_evento_historico','motivos_atraso_catalogo','fases_processo'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for select to authenticated using (fiscal_nivel() is not null)', t || '_ler', t);
    execute format('revoke insert, update, delete, truncate on public.%I from anon, authenticated', t);
  end loop;
  foreach t in array array['modelo_etapas','modelo_regimes_permitidos','modelo_tags','modelo_solicitacoes_padrao','modelo_compartilhamentos'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for select to authenticated using (apu_pode_ver_modelo(modelo_id))', t || '_ler', t);
    execute format('revoke insert, update, delete, truncate on public.%I from anon, authenticated', t);
  end loop;
  foreach t in array array['modelo_etapa_config','modelo_etapa_relato_canais','modelo_etapa_recorrencia_dias_mes','modelo_etapa_recorrencia_dias_semana',
    'modelo_etapa_gatilhos','modelo_etapa_checklist_itens','modelo_etapa_dependencias','modelo_etapa_opcoes_escolha','modelo_etapa_fases_status'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for select to authenticated using (apu_pode_ver_etapa(etapa_id))', t || '_ler', t);
    execute format('revoke insert, update, delete, truncate on public.%I from anon, authenticated', t);
  end loop;
  foreach t in array array['tarefa_checklist_estado','apu_tarefa_historico','tarefa_zerada_retificacoes'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for select to authenticated using (apu_pode_ver_tarefa(tarefa_id))', t || '_ler', t);
    execute format('revoke insert, update, delete, truncate on public.%I from anon, authenticated', t);
  end loop;
end $$;

alter table public.modelos enable row level security;
create policy modelos_ler on public.modelos for select to authenticated using (apu_pode_ver_modelo(id));
revoke insert, update, delete, truncate on public.modelos from anon, authenticated;
alter table public.modelo_etapa_acoes_rapidas enable row level security;
create policy modelo_etapa_acoes_rapidas_ler on public.modelo_etapa_acoes_rapidas for select to authenticated
  using (apu_pode_ver_etapa((select f.etapa_id from modelo_etapa_fases_status f where f.id = fase_id)));
revoke insert, update, delete, truncate on public.modelo_etapa_acoes_rapidas from anon, authenticated;
alter table public.tags_catalogo enable row level security;
create policy tags_catalogo_ler on public.tags_catalogo for select to authenticated
  using (fiscal_nivel() is not null and (escopo = 'oficial' or dono_usuario_id = auth.uid()));
revoke insert, update, delete, truncate on public.tags_catalogo from anon, authenticated;
alter table public.apu_tarefa enable row level security;
create policy apu_tarefa_ler on public.apu_tarefa for select to authenticated using (apu_pode_ver_empresa(empresa_id));
revoke insert, update, delete, truncate on public.apu_tarefa from anon, authenticated;
alter table public.apu_acesso_servico enable row level security;
create policy apu_acesso_servico_ler on public.apu_acesso_servico for select to authenticated using (apu_pode_ver_empresa(empresa_id));
revoke insert, update, delete, truncate on public.apu_acesso_servico from anon, authenticated;
revoke select on public.apu_acesso_servico from anon, authenticated;
grant select (id, empresa_id, nome_servico, usuario_login, criado_por, criado_em, ativo) on public.apu_acesso_servico to authenticated;
alter table public.apu_acesso_servico_visto enable row level security;
create policy apu_acesso_servico_visto_ler on public.apu_acesso_servico_visto for select to authenticated
  using (fiscal_pode('revelar_credencial_cliente'));
revoke insert, update, delete, truncate on public.apu_acesso_servico_visto from anon, authenticated;
