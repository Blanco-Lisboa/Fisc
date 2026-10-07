# Team's — o que o Java do CEO precisa para conversar e ligar com o Fiscal

Situação em 07/10/2026: o Team's do Java do CEO ainda lê e grava nas tabelas chat_* do banco da BL
(wfqcoocfastgsfgegpcm) e a ligação dele é demonstração. O Fiscal já usa o banco próprio do Team's
(lhqjfdexfexpmnoqhbyv). Por isso mensagens e ligações do Fiscal NÃO chegam no CEO.
Prova: ligação do William para o CEO às 22:39 saiu do Fiscal, tocou 45 s e encerrou sem resposta;
o banco do Team's só tem 2 usuários (o CEO nunca entrou nele).

## 1. Entrar no banco do Team's (login da BL, sem senha nova)
- POST https://lhqjfdexfexpmnoqhbyv.supabase.co/functions/v1/teams-entrar  corpo {"bl_token":"<access_token da sessão BL>"}
- Resposta {ok, access_token, refresh_token}. Criar cliente supabase-js do Team's
  (URL acima, chave pública sb_publishable_wJLNCeunyVFZz4yUJAaJMQ_x7qPMU_v) com persistSession:false e setSession.
- Refazer a entrada a cada abertura do Java (quem for desativado na BL perde o acesso).

## 2. Trocar as leituras/gravações de chat_* para o banco do Team's
Funções prontas: chat_resumo() (conversas + não lidas), chat_abrir_direta(p_outro), chat_abrir_setor(p_setor,p_nome),
chat_criar_grupo(p_nome,p_membros), chat_marcar_lido(p_canal), chat_pendencias(p_setores), chat_marcar_visto(p_o_que).
Regras: conversa direta/grupo só membros; autor_id tem de ser o próprio usuário. Anexos no bucket privado chat-anexo
(pasta = id da conversa). Tempo real ligado em chat_mensagem, chat_presenca, chat_canal, chat_canal_membro,
chat_pedido, chat_aviso, chat_recibo, chat_anexo, chat_reuniao_participante, chat_aviso_visto.

## 3. Ligações (voz e vídeo) — mesmo protocolo do Fiscal
- Ouvir o canal particular do Realtime `tm-u-<id do usuário>` com config {private:true}, evento broadcast.
- Enviar aviso para outra pessoa: POST https://lhqjfdexfexpmnoqhbyv.supabase.co/realtime/v1/api/broadcast
  corpo {"messages":[{"topic":"tm-u-<id do destino>","event":"<evento>","payload":{...,"chamada":"<id>","de":"<meu id>"},"private":true}]}
- Eventos: ligar {chamada, canal, tipo voz|video, modo lk, nome, canal_nome, participantes[]}, entrou, recusar, ocupado, sair.
- Áudio/vídeo pelo LiveKit: pedir o passe em POST .../functions/v1/teams-ligacao-token {"canal_id":"..."} → {url, token};
  conectar com livekit-client (Room.connect(url, token)), sala = id da conversa. Registro em chat_chamada/chat_chamada_participante.
- Código de referência: Fisc/app/src/main/resources/static/index.html (funções tmLigar, tmSinalChegou, tmAtender, tmLkEntrar, tmEncerrar).

## 4. Depois de tudo provado
Só então apagar as 17 chat_* do banco da BL (ver memória bl-teams-banco-proprio).
