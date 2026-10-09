delete from public.fiscal_info_item where id = 'templates';
update public.fiscal_info_item set acesso = 'gestor',
  resumo = 'A conta oficial do Fiscal na Meta e os modelos de mensagem.',
  colaborador = 'Não aparece.',
  gestor = 'Vê a conta oficial, os avisos da Meta e todos os modelos com a situação de cada um. Pede modelo novo e liga ou desliga o uso de um modelo. Tudo atualiza sozinho.'
 where id = 'ia_meta';
insert into public.fiscal_info_item (id, grupo, ordem, icone, titulo, resumo, acesso, colaborador, gestor)
select 'wa_ligar', 'whatsapp', coalesce(max(ordem), 0) + 1, 'whats', 'Ligar para o cliente', 'Ligação de voz pelo WhatsApp oficial.', 'gestor',
       'Não liga. Atende as ligações que chegam.', 'Pede permissão ao cliente e liga pelo próprio sistema.'
  from public.fiscal_info_item
on conflict (id) do nothing;
