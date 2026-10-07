# Instalar o LiveKit na VPS (servidor das ligações do Team's)

Versão: livekit-server v1.13.9 (Apache 2.0, gratuito). Testado aqui (07/10/2026) com servidor local:
1:1 com vídeo e grupo com 3 pessoas — todos recebendo áudio e vídeo dos outros.

## O que o William faz (uma vez)
1. **Firewall da Hostinger** (painel da VPS → Firewall): liberar entrada
   - TCP 7881
   - UDP 50000–50200 (mídia das ligações)
   - UDP 3478 (servidor de passagem)
   - UDP 30000–30100 (passagem)
2. **Endereço** `meet.it-ia.tec.br`: pelo túnel da Cloudflare que já existe na VPS (o mesmo do conversor), apontando para `http://localhost:7880`. O Zap guia o clique.
3. **Rodar o bloco abaixo no terminal da VPS** (Hostinger → Terminal). Ele cria a pasta, gera a chave, sobe o LiveKit e mostra no fim o NOME da chave e onde está o segredo.
4. **Segredos no Supabase do Team's** (projeto lhqjfdexfexpmnoqhbyv → Edge Functions → Secrets):
   `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` (copiar do arquivo /opt/livekit/livekit.yaml, sem passar pelo chat) e `LIVEKIT_URL = wss://meet.it-ia.tec.br`.

## Bloco para colar no terminal da VPS
```bash
mkdir -p /opt/livekit && cd /opt/livekit
CHAVE="API$(openssl rand -hex 6)"
SEGREDO="$(openssl rand -base64 36 | tr -d '/+=' | cut -c1-40)"
cat > livekit.yaml <<EOF
port: 7880
bind_addresses: [""]
rtc:
  tcp_port: 7881
  port_range_start: 50000
  port_range_end: 50200
  use_external_ip: true
turn:
  enabled: true
  udp_port: 3478
  relay_range_start: 30000
  relay_range_end: 30100
keys:
  ${CHAVE}: ${SEGREDO}
logging:
  level: info
EOF
chmod 600 livekit.yaml
cat > docker-compose.yml <<'EOF'
services:
  livekit:
    image: livekit/livekit-server:v1.13.9
    command: --config /etc/livekit.yaml
    network_mode: host
    restart: unless-stopped
    volumes:
      - ./livekit.yaml:/etc/livekit.yaml:ro
EOF
docker compose up -d && sleep 3 && docker compose ps
echo "Nome da chave: ${CHAVE}  (o segredo esta em /opt/livekit/livekit.yaml)"
```

## Como o Fiscal usa
- Função `teams-ligacao-token` (banco do Team's) só dá o passe para quem participa da conversa; sala = id da conversa.
- Enquanto os segredos não existem, o Team's continua ligando direto (ponto a ponto); depois passa sozinho a usar o LiveKit.
