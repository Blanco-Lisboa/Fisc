# WhatsApp do Fiscal — o que a API oficial da Meta permite (levantamento 07/10/2026)

Fontes oficiais (developers.facebook.com/documentation/business-messaging/whatsapp/...):
messages/send-messages · reference/whatsapp-business-phone-number/message-api · block-users ·
groups · groups/groups-messaging · groups/reference.

## A. Funções que a Meta oferece pela API (vão funcionar de verdade com o cliente)
| Função | Como | Observação |
|---|---|---|
| Texto, imagem, vídeo, áudio, documento, figurinha | POST /{phone}/messages | já existia texto/arquivo no back; tela ganha anexar |
| Responder citando | `context.message_id` | o cliente vê a citação |
| Reagir / tirar reação | `type: reaction`, emoji "" remove | só em mensagem recebida/enviada |
| Localização e contato (cartão) | `type: location` / `type: contacts` | |
| Marcar como lida (dois tiques azuis) | `status: read` + message_id | ao abrir a conversa |
| "Digitando…" | `typing_indicator: {type: text}` junto com o lida | some em ~25 s ou ao responder |
| Bloquear / desbloquear / lista | POST·DELETE·GET /{phone}/block_users | **só quem mandou mensagem nas últimas 24 h** (erro 131047); máx. 64.000 |
| Grupos: criar, link de convite, trocar link, aprovar/recusar pedido, remover participante, editar nome/descrição/foto, apagar grupo, mensagens no grupo, fixar mensagem (admin, até 3) | /{phone}/groups, /{group_id}/... | **exige Conta Comercial Oficial (selo verde)**; máx. **8 participantes**; ninguém é adicionado direto, só por link |

## B. O que a Meta NÃO permite pela API (impossível para qualquer sistema com a API oficial)
- **Apagar para todos** — não existe na API.
- **Editar mensagem enviada** — não existe.
- **Encaminhar com a etiqueta "Encaminhada"** — não existe; o que dá é reenviar o mesmo conteúdo para outra conversa.
- **Status/Stories, chamada de vídeo, mensagem temporária, visualização única** — não existem na API (chamada de voz é outra API, a de Calling, item pendente à parte).
- Em grupos também não: apagar, editar, mensagens interativas, esconder participantes.

## C. Funções do WhatsApp que são do aparelho (fazemos dentro do sistema, valem para a equipe)
Arquivar, fixar conversa, silenciar, marcar como não lida, favoritar mensagem, apagar para mim
(some da tela da equipe; o cliente continua vendo), buscar conversa, buscar dentro da conversa.

## D. Bloqueios hoje
- O número do Fiscal ainda é o **número de teste da Meta** (+1 555-204-7263), `is_official_business_account = false`.
  **Grupos só vão funcionar depois da virada para o número real e do selo de Conta Oficial.**
- Bloquear só pega quem escreveu nas últimas 24 h (regra da Meta).

## E. O que foi construído (07/10/2026)
Banco (migração 20261007210000): colunas de arquivar/fixar/silenciar/não lida/grupo na conversa; reação nossa, encaminhada,
favorita, apagada-para-mim e dados (local/contato) na mensagem; funções wa_conversa_marcar, wa_mensagem_marcar,
wa_meta_acao_preparar/resultado, wa_grupo_registrar, wa_encaminhar_preparar; envio aceita local e contato e manda para grupo;
recebimento entende mensagem de grupo, localização, contato, "encaminhada" e os avisos de grupo da Meta; regras de arquivo
(subir e ver só quem pode na conversa).
Servidor: wa-meta-acao (lida, digitando, reagir, bloquear/desbloquear, todas as de grupo) e wa-meta-enviar (local, contato,
grupo, encaminhar com cópia do arquivo).
Tela: menu de cada conversa (arquivar, fixar, silenciar, não lida, bloquear), Arquivadas, busca de conversa, menu ⋮ do chat
(dados, buscar na conversa, favoritas, grupo: link/pedidos/editar/apagar), menu de cada mensagem (responder, reagir, copiar,
encaminhar, favoritar, apagar para mim), clipe (documento, foto/vídeo, áudio, contato, localização), gravação de voz convertida
para OGG/Opus na própria tela, novo grupo, mostra foto/vídeo/áudio/documento/local/contato, citação, reação, autor no grupo.
Segurança: texto do cliente agora é sempre neutralizado na tela (antes entrava sem filtro).

## F. Testes feitos
- Travas no banco (bloco desfeito no fim): sem login negado; logado sem cadastro negado; colaborador sem carteira negado em
  marcar, apagar, ação na Meta, encaminhar, gravar resultado e registrar grupo; gestor ok; localização inválida recusada.
- Recebimento simulado: texto, localização e mensagem de grupo + aviso de grupo criado → gravados certos.
- Meta de verdade (número de teste): "lida + digitando" = success; lista de bloqueados = ok; criar grupo = recusado com 131215
  (número sem acesso a grupos), como esperado.
- Tela no Chrome sem janela, 10 situações; mensagem com código malicioso não executou.
- Gravação de voz: 2 s gravados → OGG válido, tocou 1,9 s.
- Não testado com cliente real: reagir, responder, bloquear, encaminhar e anexos (precisam de alguém que tenha escrito
  nas últimas 24 h). Grupos só depois da virada + Conta Oficial.
