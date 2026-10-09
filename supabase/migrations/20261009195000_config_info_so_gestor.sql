insert into public.fiscal_permissao (codigo, titulo, descricao, ordem) values
 ('config_info', 'Ver a aba Info das Configurações', 'Página que explica o que muda entre colaborador e gestor.', 14)
on conflict (codigo) do update set titulo = excluded.titulo, descricao = excluded.descricao, ordem = excluded.ordem;
insert into public.fiscal_nivel_permissao (nivel, permissao)
select nivel, 'config_info' from public.fiscal_nivel_def where perfil = 'gestor'
on conflict do nothing;
drop policy if exists fiscal_info_item_ler on public.fiscal_info_item;
create policy fiscal_info_item_ler on public.fiscal_info_item for select to authenticated using (fiscal_pode('config_info'));
update public.fiscal_info_item set acesso = 'gestor', colaborador = 'Vê só a aba Áudio.', gestor = 'Vê as abas Info e Áudio.'
 where id = 'configuracoes' or titulo = 'Configurações';
