# Modelos de mensagem do Fiscal — rascunho para o William revisar (06/10/2026)

Como funciona a aprovação:
- O modelo é um texto fixo com "lacunas" ({{1}}, {{2}}...) que o sistema preenche (nome, mês, valor...).
- Eu envio o modelo para a Meta pelo sistema (ou pelo painel "Modelos de mensagem" do WhatsApp Manager).
- A Meta analisa sozinha, em geral em minutos, às vezes até 24 horas. A resposta (aprovado/recusado) já chega
  automática no nosso banco (tabela de modelos).
- Categoria "Utilidade" (aviso de serviço, não propaganda) — é a mais barata e a mais fácil de aprovar.
- Nunca colocar nome de colaborador no texto (regra do William); quem falou aparece só na tela.
- Os modelos são da conta do número de verdade: só envio depois que o número do Fiscal estiver na Meta.

## 1. solicitacao_xml — pedir os XMLs do mês
Olá, {{1}}! Chegou a hora da apuração de {{2}}. Por favor, envie por aqui os arquivos XML das suas vendas do mês.
Botões: "Vou enviar" · "Não tive vendas"
Exemplo: {{1}}=Mix Imports · {{2}}=setembro/2026

## 2. envio_guia — mandar a guia de imposto (com PDF anexo)
Olá, {{1}}! Segue a guia de {{2}} referente a {{3}}, com vencimento em {{4}} e valor de {{5}}.
Anexo: PDF da guia
Botões: "Já paguei" · "Falar com o Fiscal"
Exemplo: Mix Imports · Simples Nacional (DAS) · setembro/2026 · 20/10/2026 · R$ 348,20

## 3. lembrete_vencimento — lembrar do vencimento
Olá, {{1}}! Lembrete: a guia de {{2}} vence em {{3}}, no valor de {{4}}.
Botões: "Já paguei" · "Enviar comprovante"

## 4. cobranca_movimento — documentos que faltam
Olá, {{1}}! Ainda não recebemos os documentos de {{2}} para fechar a apuração. Consegue enviar hoje?
Botões: "Vou enviar" · "Falar com o Fiscal"

## 5. retomar_conversa — reabrir contato (fora das 24h)
Olá, {{1}}! Aqui é o departamento Fiscal da YOU Contabilidade. Podemos continuar o atendimento por aqui?
Botões: "Sim" · "Agora não"
