-- room: importacao dos grupos de anotacao e escrita so por funcao
alter table public.room_nota add column if not exists origem text;
create unique index if not exists room_nota_origem on public.room_nota(origem) where origem is not null;
revoke insert, update, delete on public.room_categoria, public.room_nota, public.room_item from authenticated;
-- _room_arquivos_ok, room_nota_salvar (valida caminho na pasta do dono, sem bucket externo),
-- policy room_wa_importado_ler (wa-midia so para arquivo citado em nota importada do proprio dono)
-- e _room_importar_grupo(usuario, conversa, titulo): aplicados no Fiscal e no Legal em 15/10/2026;
-- importados: Gustavo 135 notas (GUSTAVO - INFORMACOES SUPORTE), Pedro 64 (ANOTACOES PEDRO).
