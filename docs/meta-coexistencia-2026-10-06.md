# Modo coexistência (app WhatsApp Business + API no mesmo número) — o que muda (06/10/2026)

Fonte: https://developers.facebook.com/documentation/business-messaging/whatsapp/embedded-signup/onboarding-business-app-users/

## Regras da Meta
- Só Provedor de Tecnologia / Parceiro pode ligar coexistência ("You must already be a Solution Partner or Tech Provider").
- A entrada é obrigatoriamente pelo Cadastro Incorporado (Embedded Signup): o número recebe um código no próprio WhatsApp.
- App WhatsApp Business versão 2.24.17 ou maior.
- Sincroniza contatos e até 6 meses de conversas (só 1:1; grupos não), em até 24h após ligar.
- Mensagens mandadas pelo celular continuam grátis e não abrem/estendem a janela de 24h da API.
- No celular deixam de funcionar: mensagens temporárias, visualização única, localização em tempo real, listas de transmissão.
- Todos os aparelhos conectados (WhatsApp Web etc.) são desconectados ao ligar; dá para reconectar até 4 (não vale WhatsApp para Windows).
- Velocidade fixa de 20 mensagens por segundo.

## Consequência para o nosso plano
1. Volta a exigência de virar Provedor de Tecnologia → Análise do App com acesso avançado a
   whatsapp_business_messaging e whatsapp_business_management + 2 vídeos + verificação de acesso.
2. Precisamos de uma página de Cadastro Incorporado (botão "Conectar WhatsApp" da Meta) — a YOU entra por ela.
3. O recebedor do Fiscal precisa tratar 3 avisos novos: smb_message_echoes (mensagem enviada pelo celular),
   history (histórico) e smb_app_state_sync (contatos).
4. O WhatsGW (que usa sessão de WhatsApp Web) será desconectado no dia da ligação.

## Vídeos (os mesmos da análise)
- whatsapp_business_messaging: o Java do Fiscal enviando uma mensagem e o WhatsApp recebendo.
- whatsapp_business_management: criação de um modelo de mensagem (no nosso app ou no WhatsApp Manager).
