# App da Meta para várias empresas (CNPJs diferentes) — o que a Meta exige (06/10/2026)

## Conclusão
Sim, dá para um app atender empresas de CNPJs diferentes — o outro agente está certo. Mas, pela Meta, isso tem nome:
**Provedor de Tecnologia (Tech Provider)**. E tem regras próprias:

1. O app tem que pertencer ao portfólio da empresa que presta o serviço (ex.: IT), não ao de um cliente.
   Meta: o app deve ser criado "with the WhatsApp use case and a connected business portfolio" do Tech Provider.
2. Cada empresa atendida continua dona do próprio portfólio, da própria conta de WhatsApp (WABA) e do próprio número;
   ela só dá acesso ao app. Se trocar de fornecedor, leva tudo junto.
3. A empresa entra pelo "Cadastro Incorporado" (Embedded Signup): uma tela/botão nosso em que o cliente faz login no
   Facebook, escolhe/cria a conta do WhatsApp e libera o acesso ao app.
4. Obrigatório: verificação da empresa provedora (IT) + Análise do App com acesso avançado a
   whatsapp_business_messaging e whatsapp_business_management + 2 VÍDEOS (um enviando mensagem e o WhatsApp
   recebendo; outro criando um modelo de mensagem) + verificação de acesso.
5. Limite: sem as verificações, até 10 empresas novas a cada 7 dias; com tudo aprovado, até 200 a cada 7 dias.

Fontes:
- https://developers.facebook.com/documentation/business-messaging/whatsapp/solution-providers/get-started-for-tech-providers
- https://developers.facebook.com/documentation/business-messaging/whatsapp/solution-providers/app-review
- Limites e posse dos ativos (guia de parceiro oficial): https://www.infobip.com/docs/whatsapp/tech-provider-program/business-onboarding

## Caminhos
A) Agora: deixar o app na YOU, sem vídeo, e ligar só o Fiscal da YOU rápido. Depois, para outras empresas,
   criar/mover o app para a IT e fazer o processo de Provedor de Tecnologia.
B) Já fazer certo para várias empresas: passar o app para o portfólio da IT, verificar a IT, gravar os 2 vídeos,
   pedir a análise e montar o Cadastro Incorporado. A própria YOU entra como primeira cliente pelo cadastro.
   Mais demorado (análise da Meta leva dias), mas não precisa refazer depois.

## Caso "tudo dentro da YOU" (pergunta do William, 06/10)
Vários Javas (Fiscal, Societário, Financeiro...) com números diferentes, TODOS da YOU (mesmo CNPJ/portfólio):
funciona com o app na YOU, sem vídeo (Direct Developer). Um app só, uma chave só; cada número é separado pelo
"phone_number_id" (o banco do Fiscal já separa por número em wa_numero).
Limite: empresa verificada pode ter até 20 números (não verificada: 2); acima disso, pedido à Meta (até 50).
Fonte: https://api.support.vonage.com/hc/en-us/articles/13159743458460-WhatsApp-Platform-Phone-Number-Limits
Condição: o app fica no portfólio da YOU. Empresas de outro CNPJ (BL, MK, 40%...) → caminho de Provedor de Tecnologia.
