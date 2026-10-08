# WhatsApp do Fiscal — tela nova (08/10/2026)

Proposta aprovada: https://claude.ai/artifact/TC5J6nU2XS2uKrszHGvkzx

## O que ficou funcionando (tudo com dado real)
- Fila: número oficial, indicadores (não lidas, abertas, janela acabando) que filtram ao clicar, abas Entrada/Minhas,
  busca por nome/telefone/empresa/CNPJ, filtros (Não lidas, Janela acabando, Fixadas, Arquivadas), seções
  Fixadas/Hoje/Ontem/Anteriores, empresa e tempo da janela em cada conversa, tiques de lida.
- Conversa: medidor da janela de 24h com barra, quem está atendendo, busca na conversa, menu; balões com nome do
  colaborador, modelos completos (cabeçalho, rodapé, botões), cartões de arquivo com baixar, áudio com onda + play +
  transcrição; Enter envia, Shift+Enter nova linha, "/" abre modelos; rodapé de janela fechada com "Enviar modelo".
- Ficha: etiquetas do contato, Modelos/Etiqueta/Fixar, "Pode falar sobre" (empresas e níveis), Editar vínculos
  (assistente/gerente), carteira, primeiro contato, mensagens no mês, arquivos da conversa e "Ver todos".

## Banco
- Novas: wa_painel_conversas(), wa_ficha_conversa(conversa), fiscal_pessoas_da_empresa(empresa).
- wa_meta_preparar_envio grava o nome do modelo em dados.modelo.
- Migração: supabase/migrations/20261008150000_wa_painel_e_ficha.sql.

## Testes
- Segurança: sem login negado; logado sem cadastro = 0 linhas e negado; colaborador não vincula contato nem lista
  pessoas; assistente consegue; servidor ok. Achado e corrigido: nível nulo deixava passar fiscal_pessoas_da_empresa.
- Tela: fotos em 1500 e 1180 px com dados de exemplo; Apuração, modelos e Team's sem erro.
- Dado real: conversa do número de teste lida pelas funções novas (janela, última mensagem, ficha).
- Não testado: a tela dentro do Java com login real (não consigo ver a janela).
- Nenhum contato tem vínculo ainda: "Pode falar sobre" fica vazio até usar a Etiqueta.
