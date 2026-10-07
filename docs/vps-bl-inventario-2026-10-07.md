# VPS BL — o que roda nela (levantamento de 07/10/2026, só leitura)

Servidor: Hostinger KVM 2 · Ubuntu 26.04 LTS · srv1837708 (srv1837708.hstgr.cloud) · 2 vCPU · 8 GB · 100 GB.
Como foi levantado: comandos só de leitura no terminal da Hostinger (docker ps, ss, systemctl, arquivos de configuração sem segredos).

## Para preencher no cadastro da VPS (um bloco por item)

### 1. MeshCentral (acesso remoto às máquinas)
- Nome: MeshCentral
- Tipo: Aplicação
- Tecnologia: Node.js 22 · MeshCentral
- Versão: 1.2.5
- Porta: 443 (e 80, que redireciona)
- Endereço: acesso.youcontabilidade.com
- Atende: Blanco & Lisboa (todas as máquinas do grupo)
- Pasta: /opt/meshcentral (serviço meshcentral.service)

### 2. Passe da tela remota (mint-share)
- Nome: Passe da tela remota (mint-share)
- Tipo: Serviço
- Tecnologia: Node.js 22
- Versão: —
- Porta: 8443
- Endereço: acesso.youcontabilidade.com:8443 (CONFIRMAR)
- Atende: Java BL (cria o link temporário para ver a tela de uma máquina)
- Pasta: /opt/meshcentral/mint-share.mjs (serviço mint-share.service)

### 3. Auto-gravador
- Nome: Auto-gravador de tela
- Tipo: Serviço
- Tecnologia: Node.js 22
- Versão: —
- Porta: nenhuma (só escuta o MeshCentral por dentro)
- Endereço: —
- Atende: Gravações de tela (instala o gravador nas máquinas quando elas conectam, por evento)
- Pasta: /opt/meshcentral/auto-gravador.mjs (serviço auto-gravador.service)

### 4. Sincronismo de dispositivos
- Nome: Sincronismo de dispositivos
- Tipo: Serviço
- Tecnologia: Node.js 22
- Versão: —
- Porta: nenhuma
- Endereço: —
- Atende: Banco da BL (atualiza a lista de máquinas no banco quando algo muda, por evento)
- Pasta: /opt/meshcentral/sync-dispositivos.mjs (serviço sync-dispositivos.service)

### 5. Conversor Billy (transcrição de áudio e voz)
- Nome: Conversor Billy
- Tipo: API
- Tecnologia: Python 3.12 · FastAPI 0.115 · faster-whisper (áudio → texto) · Piper (texto → voz)
- Versão: —
- Porta: 8000 (só dentro do servidor)
- Endereço: conversor.it-ia.tec.br (publicado pelo túnel da Cloudflare)
- Atende: Fiscal (transcrever o último áudio do cliente), robôs que falam/ouvem
- Pasta: /root/conversor-billy/docker-compose.yml
- Funções: /saude, /vozes, /falar, /converter, /transcrever

### 6. CicloDev Mapa (trabalhador)
- Nome: CicloDev Mapa
- Tipo: Trabalhador (sem tela)
- Tecnologia: Node.js (trabalhador.mjs) em Docker
- Versão: —
- Porta: nenhuma
- Endereço: —
- Atende: CicloDev
- Pasta: contêiner ciclodev-mapa (sem docker-compose; CONFIRMAR de onde foi criado)

### 7. Túnel da Cloudflare
- Nome: Cloudflare Tunnel
- Tipo: Infraestrutura
- Tecnologia: cloudflared
- Versão: 2026.9.1
- Porta: 20241 (só local, painel interno)
- Endereço: publica conversor.it-ia.tec.br
- Atende: Conversor Billy
- Pasta: /etc/cloudflared (serviço cloudflared.service)

### 8. Monarx (segurança da Hostinger)
- Nome: Monarx Agent
- Tipo: Infraestrutura
- Tecnologia: agente da Hostinger
- Porta: 65529 (só local)
- Atende: proteção contra malware do servidor

## Pontos de atenção
- "System restart required" e 44 atualizações pendentes: reiniciar derruba tudo acima. Combinar horário.
- O arquivo /root/conversor-billy/Caddyfile aponta para srv1837708.hstgr.cloud, mas não há Caddy rodando: parece sobra antiga. Confirmar antes de apagar.
- O contêiner ciclodev-mapa não tem docker-compose registrado: se o servidor for recriado, ele não volta sozinho.
