insert into public.fiscal_nivel_permissao (nivel, permissao)
select d.nivel, p from public.fiscal_nivel_def d, unnest(array['wa_grupo_criar', 'wa_grupo_gerir', 'wa_ligacao_fazer']) p
on conflict do nothing;
update public.fiscal_info_item set acesso = 'todos', colaborador = 'Cria grupo.', gestor = 'Cria grupo.' where id = 'wa_grupo_criar';
update public.fiscal_info_item set acesso = 'todos', colaborador = 'Muda nome, descrição, link de convite e aceita pedidos para entrar.', gestor = 'Muda nome, descrição, link de convite e aceita pedidos para entrar.' where id = 'wa_grupo_gerir';
update public.fiscal_info_item set acesso = 'todos', colaborador = 'Vê quem está no grupo.', gestor = 'Vê quem está no grupo.' where id = 'wa_grupo_ver';
update public.fiscal_info_item set acesso = 'todos', colaborador = 'Pede permissão ao cliente e liga pelo próprio sistema.', gestor = 'Pede permissão ao cliente e liga pelo próprio sistema.' where id = 'wa_ligar';
