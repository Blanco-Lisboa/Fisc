# TEAM'S — guia para o agente do App/Java do CEO aplicar tudo igual ao Fiscal

Escrito pelo Zap (agente do Fiscal) em 07/10/2026. Tudo abaixo já está funcionando no Java do Fiscal
(repo Blanco-Lisboa/Fisc, arquivo `app/src/main/resources/static/index.html`, funções que começam com `tm`).
Objetivo: o Team's ser UM só — mesmo banco, mesmas regras, mesmas ferramentas, mesma ligação — em todos os
Javas e nos aplicativos (iOS/Android).

---

## 1. Onde fica cada coisa

| O quê | Onde |
|---|---|
| Banco do Team's (mensagens, grupos, avisos, pedidos, reuniões, ligações) | Supabase `lhqjfdexfexpmnoqhbyv` — https://lhqjfdexfexpmnoqhbyv.supabase.co |
| Chave pública do banco do Team's | `sb_publishable_wJLNCeunyVFZz4yUJAaJMQ_x7qPMU_v` (pública, pode ir no app) |
| Login | SEMPRE o da BL (`wfqcoocfastgsfgegpcm`). Não existe senha do Team's. |
| Pessoas, setores, clientes | Banco da BL (base única). O Team's guarda só o ID. **Nunca copiar cliente nem lista de funcionários para o Team's.** |
| Servidor de ligações (voz e vídeo) | LiveKit na VPS da BL — `wss://meet.it-ia.tec.br` (gratuito, Apache 2.0, versão v1.13.9) |
| Arquivos e áudios do chat | Bucket privado `chat-anexo` no banco do Team's (pasta = id da conversa) |

**As tabelas `chat_*` antigas que estão no banco da BL NÃO devem mais ser usadas.** Depois que o Java do CEO
migrar e for provado, elas serão apagadas de lá.

---

## 2. Entrar no Team's (sem senha nova)

1. O usuário já está logado na BL (tem o `access_token` da BL).
2. Chamar: `POST https://lhqjfdexfexpmnoqhbyv.supabase.co/functions/v1/teams-entrar`
   corpo `{"bl_token": "<access_token da BL>"}`
3. Resposta: `{ ok, access_token, refresh_token, usuario:{id, nome} }`.
   A função confere na BL que a pessoa é funcionária ativa (`usuarios_internos.ativo`). Se não for → 403.
4. Criar o cliente supabase do Team's com essa sessão (`setSession`). **Não guardar a sessão do Team's no
   aparelho** (persistSession:false): refazer a entrada a cada abertura do app — assim, quem for desativado na
   BL perde o acesso.
5. O id do usuário no Team's é o MESMO id da BL.

---

## 3. Regras de segurança que já estão no banco (não precisam ser refeitas, só respeitadas)

- Conversa de **setor**: qualquer funcionário vê. Conversa **direta** e **grupo**: só quem é membro.
- Ninguém grava mensagem em nome de outro (`autor_id` tem de ser o próprio usuário). Só o autor edita/apaga.
- Pedido: só quem pediu ou o responsável altera. Reunião: só o criador e os participantes veem.
- Anexo: só quem vê a conversa sobe/abre.
- Quem não está logado ou não é funcionário: não vê nada (testado).

---

## 4. Funções prontas do banco do Team's (chamar com `rpc`)

| Função | Para que serve |
|---|---|
| `chat_resumo()` | Lista das conversas que eu vejo, com última mensagem e quantas não li |
| `chat_abrir_direta(p_outro)` | Abre (ou acha) a conversa direta com uma pessoa |
| `chat_abrir_setor(p_setor, p_nome)` | Abre (ou acha) o canal do departamento |
| `chat_criar_grupo(p_nome, p_membros[], p_descricao)` | Cria grupo (quem cria vira dono) |
| `chat_marcar_lido(p_canal)` | Marca a conversa como lida (e gera o "lido" das mensagens) |
| `chat_pendencias(p_setores[])` | Contadores de não vistos: avisos, pedidos, reuniões |
| `chat_marcar_visto('pedidos' \| 'reunioes')` | Zera os não vistos ao abrir a aba |
| `chat_pode_ver_canal(p_canal)` | Pergunta se posso ver a conversa |

Tabelas usadas direto (com as regras acima): `chat_mensagem`, `chat_anexo`, `chat_mencao`, `chat_presenca`,
`chat_canal_membro`, `chat_aviso` (+ `nivel`: info | visto | urgente), `chat_aviso_visto`, `chat_pedido`
(+ `visto_em`), `chat_reuniao`, `chat_reuniao_participante` (+ `visto_em`, `confirmado`), `chat_chamada`,
`chat_chamada_participante`, `chat_evento` (registro para integrações).

**Tempo real (sem ficar perguntando ao banco):** escutar mudanças de `chat_mensagem`, `chat_presenca`,
`chat_canal_membro`, `chat_pedido`, `chat_aviso`, `chat_aviso_visto`, `chat_reuniao_participante`.

**Lista de pessoas e departamentos:** vem da BL na hora (`usuarios_internos` ativos + `usuario_setores` +
`setores` com `eh_departamento = true`). No Fiscal isso é a função `fiscal_equipe()`; no CEO, ler da própria BL.

---

## 5. Como a tela do Team's funciona no Fiscal (fazer igual)

- **Topo**: foto, nome, departamentos e o seletor de status (Online, Em reunião, Ausente, Não me interrompam) →
  grava em `chat_presenca`. Botão laranja "+" = nova conversa.
- **Abas principais em colunas** (separadas por barra; a selecionada fica preta com texto branco):
  Conversas | Avisos | Pedidos | Reuniões — cada uma com o número de não vistos.
- **Sub-abas de Conversas**: Caixa de entrada (mensagem de hoje) | Anteriores (dias anteriores; volta para a
  caixa quando alguém escreve) | Grupos (os 8 departamentos + os grupos).
- **"+" Nova conversa**: busca por nome, departamento ou nível; filtros de departamento e de nível;
  "Novo grupo".
- **Barra de ferramentas da conversa** (também na janelinha flutuante): Pedido, Aviso, Reunião, Anexo, Áudio,
  Chamar, Vídeo, Cliente, Menção (@ também abre a lista de pessoas).
  - Cliente: busca o cliente e manda um cartão. **Guarda só o id da empresa** (`meta.cliente_id`); nome/CNPJ
    vêm da BL na hora, respeitando quem pode ver o quê.
  - Áudio: gravar em OGG/Opus.
- **Bolinha flutuante** no canto inferior direito (imagem do anel laranja): abre o Team's por cima de
  qualquer tela, arrasta para cima/baixo, dois cliques ou botão direito voltam ao lugar, some dentro do módulo,
  e tem "Abrir no Team's" que leva para a mesma conversa.
- Cabeçalho das conversas na cor da marca.

---

## 6. Ligações de voz e vídeo (o mais importante para ser igual)

Duas partes: o **aviso de "tocando"** (passa pelo banco do Team's) e o **áudio/vídeo** (passa pelo LiveKit na VPS).

### 6.1 Aviso de chamada — canal particular de cada pessoa
- Cada pessoa escuta o canal do Realtime **`tm-u-<id da pessoa>`** com `config: { private: true }` (evento broadcast).
  Só o dono consegue escutar o próprio canal (regra no banco).
- Para avisar alguém: `POST https://lhqjfdexfexpmnoqhbyv.supabase.co/realtime/v1/api/broadcast`
  com o token do Team's e corpo:
  `{"messages":[{"topic":"tm-u-<id do destino>","event":"<evento>","payload":{...},"private":true}]}`
- Eventos (todos levam `chamada` = id da chamada e `de` = id de quem manda):
  - `ligar` → `{chamada, canal, tipo: "voz"|"video", modo: "lk", nome, canal_nome, participantes:[ids]}` — faz tocar
  - `entrou` → a pessoa atendeu
  - `recusar` / `ocupado` / `sair`
- Registro: criar linha em `chat_chamada` (canal_id, tipo, iniciada_por) e em `chat_chamada_participante`;
  ao encerrar, gravar `encerrada_em` e uma mensagem `tipo: sistema` na conversa ("📞 Chamada de voz · 02:13").
- Se ninguém atender em 45 s: encerrar como "Chamada não atendida".

### 6.2 Áudio e vídeo — LiveKit na VPS
1. Pedir o passe: `POST https://lhqjfdexfexpmnoqhbyv.supabase.co/functions/v1/teams-ligacao-token`
   corpo `{"canal_id": "<id da conversa>"}` com o token do Team's.
   Resposta `{ ok, url: "wss://meet.it-ia.tec.br", token }`. O passe só sai se a pessoa participa da conversa;
   vale 4 h. **A chave secreta do LiveKit NUNCA vai para o app** — fica só na VPS e nos segredos do Supabase.
2. Conectar na sala: sala = id da conversa (1:1, grupo ou departamento — várias pessoas na mesma sala).
3. Ligar microfone; câmera se for vídeo; compartilhar tela quando pedir.
4. Mostrar um quadro por participante (vídeo, ou foto/iniciais quando sem câmera), o próprio vídeo pequeno no
   canto, o tempo de ligação e os botões: Mudo, Câmera, Tela, Encerrar.
5. Quando todos saírem, encerrar.

**Bibliotecas oficiais do LiveKit (gratuitas):**
- Java com tela HTML (JCEF): `livekit-client` (JavaScript) — no Fiscal está em `static/vendor/livekit-client.umd.js` (v2.22.3).
- Aplicativo Flutter (iOS e Android): pacote `livekit_client` (pub.dev).
- Swift (iOS nativo): `client-sdk-swift` · Android nativo: `client-sdk-android`.
- No JCEF, ligar o microfone/câmera com o argumento `--enable-media-stream`.

**Teste feito (07/10/2026):** 1:1 com vídeo e grupo com 3 pessoas pelo LiveKit — todos recebendo áudio e vídeo
uns dos outros. Servidor na VPS respondendo e fechado para quem não tem passe (sem passe = 401).

---

## 7. O que NÃO fazer
- Não criar tabela de chat em outro banco nem copiar clientes/funcionários.
- Não deixar segredo (chave do LiveKit, chave de serviço) no app, no código ou no chat.
- Não ficar consultando o banco de tempos em tempos: usar o tempo real e o canal `tm-u-<id>`.
- Não usar mais as `chat_*` do banco da BL.
- "Senha" (cofre) e "Decisão do CEO" ainda não existem de verdade — não fingir na tela.

## 8. Checklist para dizer "pronto"
1. Entrar com o login da BL e ver as mesmas conversas que o Fiscal vê.
2. Mandar mensagem do CEO e ela aparecer na hora no Fiscal (e vice-versa).
3. Ligar do Fiscal para o CEO: tocar, atender, áudio e vídeo nos dois lados.
4. Ligação em grupo com 3 pessoas.
5. Pessoa de fora da conversa não consegue abrir nem entrar na ligação.
