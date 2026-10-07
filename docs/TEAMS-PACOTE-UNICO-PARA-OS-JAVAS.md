# TEAM'S — pacote único para todos os Javas (com o visual de cada empresa)

Escrito pelo Zap em 07/10/2026. Substitui a ideia de "copiar o Team's para cada Java": agora existe **um código só**,
servido pela VPS, e cada Java só carrega e passa o seu visual.

- Endereço: `https://teams.it-ia.tec.br/teams.js` (VPS da BL, pelo túnel da Cloudflare)
- Código-fonte: repo `Blanco-Lisboa/Fisc`, pasta `app/src/main/resources/static/teams-web/`
  (`teams.js` + `img/` + `vendor/` com supabase-js e livekit-client)
- Publicação: todo push nessa pasta avisa a VPS sozinho (GitHub Actions `teams-web.yml`), a VPS baixa a versão nova
  do GitHub e o próprio Actions confere que o arquivo no ar é igual ao do GitHub. Sem nada ficar perguntando de tempos
  em tempos.
- Todos os Javas recebem a versão nova na próxima vez que abrirem (o servidor manda `no-cache`).

O Team's roda isolado (Shadow DOM): o CSS do Java não mexe no Team's e o do Team's não mexe no Java. Tudo que ele
deixa global começa com `tmx` ou `TeamsIT` — não usar esses nomes no Java.

---

## 1. Como ligar num Java (CEO, Financeiro, etc.)

1. **Tirar o Team's antigo** do Java (funções, CSS e tabelas `chat_*` do banco da BL não são mais usadas).
2. Carregar o pacote (com reserva local, se quiser):
```js
const TEAMS_JS=['https://teams.it-ia.tec.br/teams.js'];
function teamsCarregar(){return new Promise(ok=>{const tenta=i=>{if(window.TeamsIT)return ok(true);if(i>=TEAMS_JS.length)return ok(false);
 const s=document.createElement('script');s.src=TEAMS_JS[i];s.onload=()=>ok(!!window.TeamsIT);s.onerror=()=>{s.remove();tenta(i+1);};document.head.appendChild(s);};tenta(0);});}
```
3. Depois do login da BL:
```js
await teamsCarregar();
TeamsIT.iniciar({
  origem: 'ceo',                       // vai no registro chat_evento
  chave: 'ceo-teams',                  // onde guarda a posição da bolinha
  entrar: async () => ({ bl_token: '<access_token da BL>' }),
  usuario: () => ({ id: '<id do usuário na BL>', nome: '<nome>' }),
  pessoas: () => /* Promise de {data:{setores:[{id,nome}], pessoas:[{id,nome,nivel,email,foto_url,setores:[ids]}]}, error} */,
  buscarClientes: texto => /* Promise de {data:[{empresa_id,razao_social,nome_fantasia,cnpj,ativa}], error} */,
  clientes: ids => /* mesmo formato, buscando pelos ids */,
  abrirModulo: () => /* navegar para a aba Team's do Java */,
  aoContar: n => /* número de não vistos para o selo do menu */,
  toast: texto => /* aviso curto do próprio Java (opcional) */,
  camada: 70,                          // altura (z-index) da bolinha/janelas por cima do Java
  tema: { /* ver item 2 */ },
  layout: { lista: 'esquerda' | 'direita', compacto: false }
});
```
   - `pessoas`, `buscarClientes` e `clientes` leem da **BL** (base única). O Team's nunca guarda cliente nem
     funcionário — só o id. No Fiscal elas são `fiscal_equipe`, `fiscal_buscar_clientes`, `fiscal_empresas`.
4. Ao abrir a aba Team's: `TeamsIT.abrirModulo(elementoDaArea)` — ele ocupa a área toda do elemento.
5. A cada troca de tela do Java: `TeamsIT.tela({ bolinhaAlta: false })` (a bolinha some dentro do módulo e volta
   fora dele; `bolinhaAlta:true` sobe a bolinha quando a tela tiver barra embaixo).
6. JCEF: manter o argumento `--enable-media-stream` (microfone/câmera das ligações).

## 2. Visual de cada empresa (`tema`)

Tudo opcional; o que não for passado fica no padrão (YOU, laranja).

| Chave | O que muda |
|---|---|
| `cor`, `corClara`, `corTexto`, `corSuave`, `corBorda` | cor principal da marca e variações (botões, selos, destaques) |
| `gradiente` | fundo dos botões e cabeçalhos (ex.: `linear-gradient(135deg,#1F3A8A,#3B82F6)`) |
| `cabecalho` | fundo do cabeçalho das conversas (padrão = `gradiente`) |
| `fundoConversa` | fundo da área de mensagens |
| `fonte`, `fonteTitulo` | fonte do corpo e dos títulos (`fonteCss` = link da fonte, ex. Google Fonts) |
| `texto`, `textoApoio`, `textoApagado`, `fundo`, `fundoSuave`, `fundoSuave2`, `borda`, `raio` | cores neutras e arredondamento |
| `bolinha` | endereço da imagem da bolinha flutuante |
| `vars` | qualquer outra variável CSS (`{'--verde':'#0a0'}`) |

`layout.lista:'direita'` põe a lista de conversas do lado direito; `layout.compacto:true` deixa a lista mais estreita.

Comportamento (abas, ferramentas, ligações, segurança) é o mesmo em todos — só o visual muda.

## 3. Testado (07/10/2026)
- Fiscal com o pacote: 16 telas fotografadas antes e depois — iguais (só muda o relógio).
- Ligação direta, ligação pelo servidor (LiveKit) e em grupo com 3 pessoas — áudio e vídeo nos dois/três lados.
- Outro visual (azul, fonte Inter, lista à direita, compacto) — ok.
- Servidor da VPS testado aqui: entrega os arquivos, bloqueia tentativa de sair da pasta (404), limita o "atualizar"
  (1 a cada 15 s).
- Java do Fiscal reaberto e entrou no Team's de verdade pelo pacote (presença gravada no banco).
