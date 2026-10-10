# API do Fiscal para a BL (fiscal-api)

Endereço: `POST https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/fiscal-api`
Cabeçalho: `Authorization: Bearer <token de login da BL>` (o mesmo login do Java BL).

Quem pode: login da BL com nível listado em `fiscal_api_bl_nivel` (hoje: ceo), conferido na BL a cada chamada; exceções em `fiscal_api_bl_acesso`. Toda chamada fica em `fiscal_api_bl_log`.
Bloqueado: qualquer tabela ou função com segredo/chave/senha/token no nome e as próprias tabelas de acesso da API.

## Operações (corpo JSON)

- `{"operacao":"tabelas"}` — lista tabelas e colunas.
- `{"operacao":"funcoes"}` — lista funções (RPC) e argumentos.
- `{"operacao":"ler","tabela":"wa_conversa","colunas":"id,contato_nome,ultima_em","filtros":[["estado","neq","arquivada"]],"ordem":[["ultima_em","desc"]],"limite":100,"de":0}`
  - filtros: `eq, neq, gt, gte, lt, lte, like, ilike, in, is`; limite máximo 1000; volta `total`.
- `{"operacao":"inserir","tabela":"...","dados":{...} ou [{...}]}`
- `{"operacao":"atualizar","tabela":"...","dados":{...},"filtros":[[...]]}` — filtro obrigatório.
- `{"operacao":"apagar","tabela":"...","filtros":[[...]]}` — filtro obrigatório.
- `{"operacao":"rpc","funcao":"wa_meta_painel","args":{}}`

Resposta: `{"ok":true,"dados":...,"total":n}` ou `{"ok":false,"erro":"..."}` (401 login inválido, 403 conta sem acesso, 400 pedido inválido).

Observação: a API roda como servidor do Fiscal (acesso total). Funções que dependem do usuário logado no Fiscal (`auth.uid()`) não enxergam o usuário da BL; para essas, usar as funções de servidor equivalentes.
