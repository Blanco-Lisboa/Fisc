create table if not exists public.fiscal_info_item (
  id text primary key check (id ~ '^[a-z0-9_]{1,40}$'),
  grupo text not null check (grupo in ('perfil','modulo','whatsapp')),
  ordem int not null,
  icone text not null default '',
  titulo text not null,
  resumo text not null default '',
  acesso text not null check (acesso in ('todos','colaborador','gestor','diferente')),
  colaborador text not null default '',
  gestor text not null default '',
  atualizado_em timestamptz not null default now()
);
alter table public.fiscal_info_item enable row level security;
revoke all on public.fiscal_info_item from anon;
revoke all on public.fiscal_info_item from authenticated;
grant select on public.fiscal_info_item to authenticated;
create policy fiscal_info_item_ler on public.fiscal_info_item for select to authenticated using (fiscal_nivel() is not null);

insert into public.fiscal_info_item (id, grupo, ordem, icone, titulo, resumo, acesso, colaborador, gestor) values
('perfil_colaborador','perfil',1,'pessoa','Colaborador','Quem cuida dos clientes no dia a dia.','colaborador',
 'Trabalha com os clientes da própria carteira: acompanha a apuração, resolve pendências e conversa com os clientes.',''),
('perfil_gestor','perfil',2,'grafico','Gestor','Assistente ou gerente do departamento.','gestor','',
 'Enxerga o departamento inteiro: acompanha a equipe, distribui os clientes entre as pessoas e organiza as conversas de todos.'),

('central','modulo',1,'casa','Central','A tela inicial do colaborador.','colaborador',
 'O sistema abre direto nela.','Não aparece. O gestor começa pelo Painel do Gestor.'),
('painel_gestor','modulo',2,'grafico','Painel do Gestor','Visão do departamento inteiro.','gestor',
 'Não aparece.','Abre direto nele. Tem três abas: Central (resumo da equipe), Mapa do Departamento (quem cuida de quem) e Clientes (a base toda, onde monta a carteira de cada pessoa).'),
('apuracao','modulo',3,'prancheta','Apuração','Os clientes do mês e o andamento de cada um.','diferente',
 'Vê só os clientes da sua carteira.','Vê todos os clientes do departamento.'),
('pendencias','modulo',4,'sino','Pendências','O que está esperando alguma ação.','todos','Usa normalmente.','Usa normalmente.'),
('esteiras','modulo',5,'fluxo','Esteiras','As etapas de cada processo.','todos','Usa normalmente.','Usa normalmente.'),
('templates','modulo',6,'modelo','Templates','Modelos de mensagem prontos.','todos','Usa normalmente.','Usa normalmente.'),
('ia_meta','modulo',7,'brilho','IA & Meta','Ajuda da inteligência artificial e ligação com a Meta.','todos','Usa normalmente.','Usa normalmente.'),
('email','modulo',8,'email','E-mail''s','As caixas de e-mail da empresa.','todos',
 'Vê só as caixas liberadas para você no sistema da BL.','Vê só as caixas liberadas para você no sistema da BL.'),
('teams','modulo',9,'equipe','Team''s','Conversa interna da equipe e chamadas.','todos','Usa normalmente.','Usa normalmente.'),
('whatsapp','modulo',10,'whats','WhatsApp','Conversa com os clientes pelo número oficial.','diferente',
 'Cuida das conversas que são suas.','Cuida de todas as conversas e dos grupos.'),
('configuracoes','modulo',11,'engrenagem','Configurações','Esta tela.','todos','Usa normalmente.','Usa normalmente.'),

('wa_entrada','whatsapp',1,'caixa','Conversa nova sem dono','Mensagem de cliente que ainda não é de ninguém.','diferente',
 'Pode ler, mas não responde.','Responde, manda modelo ou arquivo.'),
('wa_organizar','whatsapp',2,'fixar','Fixar e organizar conversas','Deixar uma conversa no topo e afins.','diferente',
 'Só nas conversas que são suas.','Em qualquer conversa.'),
('wa_grupo_criar','whatsapp',3,'grupo','Criar grupo','Montar um grupo novo com clientes.','gestor','Não pode.','Pode.'),
('wa_grupo_gerir','whatsapp',4,'engrenagem','Cuidar dos grupos','Link de convite, pedidos para entrar, editar e apagar.','gestor','Não pode.','Pode.'),
('wa_grupo_ver','whatsapp',5,'equipe','Ver quem está no grupo','A lista de participantes.','gestor','Não vê.','Vê.')
on conflict (id) do update set grupo=excluded.grupo, ordem=excluded.ordem, icone=excluded.icone, titulo=excluded.titulo,
  resumo=excluded.resumo, acesso=excluded.acesso, colaborador=excluded.colaborador, gestor=excluded.gestor, atualizado_em=now();
