revoke insert, update, delete, truncate on public.wa_contato from anon, authenticated;

insert into public.fiscal_permissao (codigo, titulo, descricao, ordem) values
 ('wa_bloquear', 'Bloquear cliente no WhatsApp', 'Bloquear e desbloquear um número no WhatsApp oficial.', 10)
on conflict (codigo) do update set titulo = excluded.titulo, descricao = excluded.descricao, ordem = excluded.ordem;
insert into public.fiscal_nivel_permissao (nivel, permissao)
select n, 'wa_bloquear' from unnest(array['assistente', 'gerente']) n
on conflict do nothing;

do $$
declare d text; a text := 'select * into nm from wa_numero where id = cv.numero_id;';
begin
  d := pg_get_functiondef('public.wa_meta_acao_preparar'::regproc);
  if position('wa_bloquear' in d) = 0 then
    if position(a in d) = 0 then raise exception 'trecho nao encontrado'; end if;
    d := replace(d, a, 'if p_acao in (''bloquear'', ''desbloquear'') and not fiscal_pode(''wa_bloquear'') and not fiscal_e_servidor() then
    return jsonb_build_object(''ok'', false, ''erro'', ''Sem permissao para bloquear.'');
  end if;
  ' || a);
    execute d;
  end if;
end $$;

insert into public.fiscal_info_item (id, grupo, ordem, icone, titulo, resumo, acesso, colaborador, gestor) values
 ('wa_bloquear', 'whatsapp', 6, 'engrenagem', 'Bloquear cliente', 'Impedir que um número mande ou receba mensagens.', 'gestor', 'Não pode.', 'Pode.')
on conflict (id) do update set grupo = excluded.grupo, ordem = excluded.ordem, titulo = excluded.titulo, resumo = excluded.resumo,
  acesso = excluded.acesso, colaborador = excluded.colaborador, gestor = excluded.gestor, atualizado_em = now();
