# Instalar o servidor do Team's na VPS (teams.it-ia.tec.br)

Uma vez só. Depois disso, toda atualização chega sozinha (push no GitHub → VPS baixa → conferência automática).

Terminal da VPS (Hostinger → Terminal). Se aparecer `^[[200~` ao colar: digitar `reset`, Enter, e colar de novo.

```bash
apt-get install -y git python3
useradd --system --home /opt/teams-web --shell /usr/sbin/nologin teamsweb
mkdir -p /opt/teams-web && git clone --depth 1 --filter=blob:none --sparse https://github.com/Blanco-Lisboa/Fisc /opt/teams-web/repo
git -C /opt/teams-web/repo sparse-checkout set app/src/main/resources/static/teams-web deploy/teams-web
chown -R teamsweb:teamsweb /opt/teams-web
cp /opt/teams-web/repo/deploy/teams-web/teams-web.service /etc/systemd/system/ && systemctl daemon-reload && systemctl enable --now teams-web
sleep 3; curl -s -o /dev/null -w "local=%{http_code}\n" http://127.0.0.1:7890/teams.js
cp /etc/cloudflared/config.yml /etc/cloudflared/config.yml.bak2 && sed -i 's#  - service: http_status:404#  - hostname: teams.it-ia.tec.br\n    service: http://localhost:7890\n  - service: http_status:404#' /etc/cloudflared/config.yml && systemctl restart cloudflared && cloudflared tunnel route dns c8ca294e-b68d-4b09-b635-70800c559acf teams.it-ia.tec.br
sleep 8; curl -s -o /dev/null -w "internet=%{http_code}\n" https://teams.it-ia.tec.br/teams.js
```

Esperado no fim: `local=200` e `internet=200`.

- O servidor só escuta dentro da VPS (127.0.0.1:7890); de fora, só pelo túnel.
- Roda com usuário próprio sem login (`teamsweb`), só escreve em `/opt/teams-web`.
- Só entrega os arquivos da pasta `teams-web` (código público do Team's, sem segredo).
- Não mexe no LiveKit (meet) nem no conversor; o arquivo do túnel ganha cópia `config.yml.bak2` antes.
