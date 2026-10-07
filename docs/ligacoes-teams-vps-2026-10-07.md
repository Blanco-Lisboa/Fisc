# Ligações de voz e vídeo do Team's na VPS — pesquisa (07/10/2026)

## Recomendado: LiveKit (github.com/livekit/livekit)
- Servidor de chamadas pronto (SFU): cada pessoa manda o vídeo uma vez para a VPS e a VPS distribui para os outros. Serve para 1:1 e reunião com várias pessoas.
- Licença Apache 2.0 (pode usar e modificar sem pagar). Feito em Go; usado por Salesforce, Nvidia, Oracle, Spotify.
- Já vem com servidor de passagem (TURN) embutido → funciona entre redes diferentes (casa x escritório).
- Biblioteca JavaScript pronta (livekit-client) → encaixa direto na tela HTML do Java do Fiscal.
- Compartilhar tela, mudo, detector de quem está falando, criptografia ponta a ponta, gravação (opcional, "egress").
- Instala com Docker ou um arquivo só.
- Capacidade publicada (máquina de 16 núcleos): ~19 participantes por núcleo em reunião com todos em vídeo; ~188 por núcleo só áudio. A VPS (2 vCPU, 8 GB) aguenta com folga reuniões internas de 10–20 pessoas com vídeo.

### Como encaixa no que já existe
1. LiveKit roda em Docker na VPS (ao lado do conversor-billy).
2. Função nova no banco do Team's (edge `teams-ligacao-token`): confere que a pessoa pode ver a conversa (`chat_pode_ver_canal`) e devolve um passe temporário (JWT assinado com a chave do LiveKit). A chave fica no cofre/segredo da função, nunca no Java.
3. Sala = id da conversa. O aviso de "tocando" continua pelo canal particular que já existe (`tm-u-<id>`); o áudio/vídeo passa pelo LiveKit.
4. A tela de ligação atual é mantida; troca só o "motor" (hoje ponto a ponto) pelo LiveKit.
5. Registro da chamada continua em `chat_chamada` / `chat_chamada_participante`.

### O que precisa na VPS (Hostinger)
- Subdomínio, ex. `meet.it-ia.tec.br`, apontando DIRETO para o IP da VPS (a Cloudflare não passa UDP).
- Portas: 443/7880 TCP (sinal, com certificado), 7881 TCP, 7882 UDP (mídia, porta única), 3478 UDP e 5349 TCP (TURN).
- Atenção: a VPS mostra "reinicialização pendente"; combinar horário.

## Alternativas avaliadas
- **Jitsi Meet** (Apache 2.0): sala de reunião completa e pronta, mas é um sistema à parte (4 serviços, tela própria em janela embutida). Mais pesado e fica com cara de outro sistema dentro do Team's.
- **mediasoup**: muito eficiente, mas é só uma biblioteca — teríamos de construir o servidor inteiro.
- **Janus**: licença GPLv3 (mais restritiva) e mais trabalhoso de integrar.

## Fontes
- https://github.com/livekit/livekit (README)
- https://docs.livekit.io/home/self-hosting/ports-firewall/
- https://docs.livekit.io/home/self-hosting/benchmark/
- https://selfhostedworld.com/software/jitsi-meet · https://www.opentechhub.io/jitsi-meet/
- https://openvidu.io/3.8/docs/self-hosting/production-ready/performance/

## Correção (07/10/2026, depois da pergunta do William)
- O que é pago é o **LiveKit Cloud** (hospedado por eles). O servidor LiveKit instalado na nossa VPS é gratuito, Apache 2.0, sem limite de pessoas nem recurso bloqueado (fonte: getstream.io/glossary/livekit, docs.livekit.io/intro/cloud).
- Mesmo assim, como o pedido é um **modelo pronto** do GitHub: **Jitsi Meet — github.com/jitsi/docker-jitsi-meet** (3,6 mil estrelas, Apache 2.0, "100% open source", sem plano pago).
  Já vem completo: sala de reunião com voz, vídeo, várias pessoas, compartilhar tela, levantar a mão, chat; instala com Docker na VPS.
  No Team's: os botões Chamar/Vídeo abrem a sala do Jitsi daquela conversa dentro da janela (API de janela embutida do Jitsi), e o aviso de "tocando" continua pelo canal que já existe.
  Lado ruim: a tela da reunião é a do Jitsi (não a nossa) e ele é mais pesado que o LiveKit.
