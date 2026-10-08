# Gmail dentro do Java sem guardar os e-mails no nosso banco (pesquisa 08/10/2026)

## Resposta curta
Sim. A API oficial do Gmail deixa o Java ler, buscar, enviar, responder, etiquetar e arquivar direto na caixa do Google.
Os e-mails continuam guardados no Google. No nosso lado fica só a autorização de cada usuário (no cofre) e, se quiser, um marcador de "até onde já li".

## O que NÃO dá
- Abrir o site do Gmail dentro do Java: o Google bloqueia (cabeçalho X-Frame-Options), não aparece dentro de outra tela.

## Como funcionaria
1. Listar e ler: `users.threads.list` / `users.messages.list` com `q=` (mesma busca do Gmail), `users.messages.get` para abrir. Anexo: `users.messages.attachments.get`, baixado na hora e mostrado, sem gravar.
2. Enviar/responder: `users.messages.send` (rascunhos: `users.drafts.*`).
3. Etiquetas/arquivar/lida: `users.messages.modify`, `users.labels.*`.
4. Chegou e-mail novo (sem polling): `users.watch` manda aviso para um tópico do Google Pub/Sub, que empurra para uma função nossa; a função chama `users.history.list` e avisa a tela. O `watch` precisa ser renovado a cada 7 dias (agendamento de renovação, não é consulta de e-mail).
5. Acesso: como as contas são do Google Workspace da empresa, o app do Google fica como "Interno". Interno não passa pela verificação/auditoria de segurança do Google e não tem limite de 100 usuários.
   Alternativa: conta de serviço com delegação no domínio (o administrador libera uma vez; ninguém precisa clicar em "permitir").

## Pontos de atenção
- Velocidade: cada tela pede ao Google na hora; lista com muitos e-mails pede em lotes (`batch`). Um cache curto só na memória da tela resolve, sem banco.
- Busca: usa a busca do próprio Gmail (`q=`), não a nossa.
- Já existe no banco central da BL o módulo "E-mail's/Meet" que foi desenhado como espelho (guarda cópia). Se o caminho for "não guardar", aquele módulo precisa ser revisto para ler direto do Google.

## Fontes
- https://developers.google.com/workspace/gmail/api/guides/push
- https://developers.google.com/workspace/gmail/api/auth/scopes
- https://support.google.com/cloud/answer/13464323 (isenções de verificação: uso interno)
- https://www.unipile.com/gmail-api-service-account-domain-wide-delegation/
