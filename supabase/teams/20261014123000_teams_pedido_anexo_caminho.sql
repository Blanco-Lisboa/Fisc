drop policy if exists chat_anexo_ins on chat_anexo;
create policy chat_anexo_ins on chat_anexo for insert with check (
  (mensagem_id is not null and exists (select 1 from chat_mensagem m where m.id = chat_anexo.mensagem_id and m.autor_id = auth.uid() and chat_pode_ver_canal(m.canal_id)))
  or (pedido_id is not null and url ~ ('^pedido/' || pedido_id::text || '/[0-9a-f-]{36}\.[a-z0-9]{1,5}$')
      and exists (select 1 from chat_pedido p where p.id = chat_anexo.pedido_id and p.solicitante_id = auth.uid())));
