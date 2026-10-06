# Sem coexistência + ligações pelo sistema — o que a Meta diz (06/10/2026)

## Decisão
William: sem coexistência. O número do Fiscal fica só na API (Java). Precisa de ligações pelo sistema.
Volta a valer: Direct Developer (app da YOU, número da YOU) → sem vídeo e sem análise do app.

## Ligações (WhatsApp Cloud API Calling)
Fonte: https://developers.facebook.com/documentation/business-messaging/whatsapp/calling
- Dois tipos: cliente liga para a empresa (recebida) e empresa liga para o cliente (feita).
- Requisitos: número na Cloud API (não no app do celular — combina com "sem coexistência"); assinar o aviso
  "calls"; permissão whatsapp_business_messaging (já temos); ligar a função de chamadas nas configurações do número.
- Requisito de volume: "a daily messaging limit of at least 2,000 unique recipients". Número novo costuma começar
  com limite menor e sobe com o uso e a qualidade → conferir o limite do número real quando ele for ligado.
- Brasil: liberado (as exceções são EUA, Canadá, Egito, Vietnã e Nigéria).
- Para LIGAR para o cliente, ele precisa autorizar antes (pedido de permissão pelo WhatsApp). Há limite de pedidos e,
  se o cliente não atender várias vezes seguidas, a permissão cai (2 sem atender → reavaliação; 4 → revoga).
- Ligações recebidas (cliente liga) são grátis. Ligações feitas pela empresa são cobradas por tempo (pulsos de 6 s),
  conforme o país.
  Fonte de preço: https://chatmaxima.com/blog/whatsapp-business-calling-pricing-2026/
- Dá para configurar horário de atendimento de chamadas e mostrar/esconder o botão de ligar.

## Como funciona por dentro (recebida)
Fonte: https://developers.facebook.com/documentation/business-messaging/whatsapp/calling/user-initiated-calls
1. Cliente liga → a Meta manda aviso "calls" com event "connect" e a oferta de áudio (SDP).
2. Em 30–60 s o sistema responde: POST /<PHONE_NUMBER_ID>/calls "pre_accept" (com a resposta SDP) e depois "accept".
3. O áudio corre direto entre o Java e a Meta (WebRTC, áudio OPUS) — o Chromium embutido do Java faz isso.
4. Fim: "terminate" (obrigatório mandar) e aviso de término com duração.

## O que eu preciso construir
- Recebedor: tratar o aviso "calls" (connect/terminate) e avisar a tela na hora (tempo real).
- Função que repassa pre_accept/accept/reject/terminate e iniciar ligação (com a chave guardada no servidor).
- Java do Fiscal: tocar/atender/recusar/desligar, microfone liberado no Chromium embutido, histórico de ligações.
- Banco: tabela de ligações (quem, quando, duração, quem atendeu) e pedido/registro de permissão para ligar.
- Assinar o campo "calls" no app e ligar a função de chamadas no número.

## Ordem sugerida
1. Chave definitiva (Usuário do Sistema) → Integrações.
2. Enviar os modelos de mensagem para aprovação.
3. Java do Fiscal pronto para a equipe (Entrada/assumir, guias e arquivos, modelos).
4. Dia da troca: número do Fiscal sai do celular/WhatsGW e entra na API.
5. Ligações: assim que o número tiver o limite de 2.000 e a função for ligada (eu construo em paralelo, testo
   com o número de teste se a Meta permitir).
