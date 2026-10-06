# WhatsApp Fiscal — o que falta para a Meta liberar de verdade (06/10/2026)

## Resposta curta
NÃO precisa de vídeo nem de análise do app (App Review) no nosso caso.
A Meta só exige vídeo de quem é "provedor de tecnologia" (faz app para OUTRAS empresas usarem).
Nós usamos o WhatsApp da própria YOU, na conta da própria empresa = "Direct Developer".
Fonte (Meta, App Review): "if you are using the API for yourself as a Direct Developer, you do not need Advanced
access or app review." — https://developers.facebook.com/documentation/business-messaging/whatsapp/solution-providers/app-review

Se um dia o grupo quiser oferecer o sistema para empresas de fora, aí sim: 2 vídeos separados
(1. app enviando mensagem e o WhatsApp recebendo — whatsapp_business_messaging;
 2. criação de um modelo de mensagem — whatsapp_business_management), gravação de tela, com texto explicando cada um.

## O que falta para sair do teste e usar o número de verdade
1. Publicar o app BL-conect (modo "Live"). Enquanto não publica, a Meta só manda avisos de teste do painel
   ("Make sure your app is in Live mode; some webhooks will not be sent if your app is in Dev mode").
   Para publicar, o painel pede: link de Política de Privacidade, link de Termos de Uso, link/instrução de
   exclusão de dados, ícone (512×512 a 1024×1024), categoria e e-mail de contato.
2. Número de verdade do Fiscal: cadastrar na conta do WhatsApp da YOU (Etapa 2 do painel), nome de exibição
   aprovado pela Meta e PIN de 6 dígitos. Atenção: o número que hoje roda no WhatsGW não pode estar ativo em
   outro lugar ao mesmo tempo (decidir: migrar o número atual ou usar um número novo).
3. Chave permanente (Usuário do Sistema) no lugar da chave de 24h, com as permissões de mensagens e de
   gestão na conta do WhatsApp da YOU. Vai na tela Integrações do Java CEO.
4. Atualizar a integração com os dados do número real; eu ligo o número ao Fiscal e assino o app na conta
   (mesmo passo feito com o número de teste em 05/10).
5. Modelos de mensagem (templates) aprovados para falar com cliente fora das 24h (ex.: envio de guia,
   pedido de XML). Sem modelo aprovado o sistema só responde quem escreveu nas últimas 24h.

## Já feito
- Verificação da empresa (Etapa 3) concluída; forma de pagamento cadastrada.
- Recebedor de avisos verificado, ciclo real ida/volta testado com o número de teste.
- Java do Fiscal: login pela BL funcionando (06/10, usuário "teste 2").
