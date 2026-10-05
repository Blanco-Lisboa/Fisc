# Fiscal · Colaborador — Java + JavaFX + Spring

Porte para **Java 17 + JavaFX 21 + Spring Boot 3** do preview do módulo **Fiscal**
(visão do colaborador), tal como publicado e validado no navegador.

## Por que o front está embutido igual, e não reescrito em JavaFX puro

Você pediu **100% de tudo, nada faltando, nem uma vírgula**: todos os módulos,
todos os botões, todos os modais (Em lote, Meu espaço, Enviar guia), o
WhatsApp (padrão único reaproveitado do Societário), as esteiras reais
(MODELO V1/V2/Enviar Guia), o Radar de XML, IA por cliente — tudo.

Reescrever esse front à mão em controles JavaFX nativos (`Button`, `TableView`,
`GridPane`...) correria o risco real de divergir em algum detalhe — um
espaçamento, uma regra condicional, um texto — exatamente o "faltando uma
vírgula" que você não quer. Por isso a solução é:

- O arquivo **`src/main/resources/web/index.html`** é uma cópia **byte a
  byte** do HTML/CSS/JS publicado (mesmo arquivo, sem edição).
- A janela JavaFX abre um **`WebView`** (motor de navegador embutido do
  próprio JavaFX, baseado em WebKit) e carrega esse `index.html`.
- Resultado: a tela roda **idêntica** ao que foi validado no navegador —
  mesmo CSS, mesmo JavaScript, mesmos dados de demonstração, mesmo
  comportamento de clique/modal/aba.
- O Spring Boot sobe o contexto da aplicação (sem servidor web) e é o lugar
  onde entram os serviços reais depois — ver "Próximo passo" abaixo.

Se no futuro quiser controles 100% nativos JavaFX (sem WebView), isso é um
retrabalho novo, tela por tela — e nesse caso alguma diferença visual em
relação ao HTML é inevitável. Este porte prioriza fidelidade total, como
pedido.

## Verificado de verdade (compilado, empacotado e executado nesta sessão)

Diferente de portes anteriores (em que eu disse honestamente "não executei no
ambiente"), **este eu compilei, empacotei e rodei de verdade**: `mvn compile`,
`mvn package` (gerou `target/fiscal-colaborador-1.0.0.jar` com as classes e o
`index.html` completo dentro) e `mvn javafx:run` — a janela **abriu de fato no
Windows**, com o título "Fiscal · Colaborador — You Contabilidade (IT.FC)",
e o conteúdo renderizado bateu com o preview no navegador (mesa do Pedro,
esteira real, WhatsApp, botões "Em lote"/"Meu espaço", IA).

**Único ponto observado:** alguns emojis do texto (📥 🏛️ 🗂️ ⚠️) aparecem como
quadrado no WebView do JavaFX nesta máquina — é limitação de fonte de emoji
do motor WebKit embutido do JavaFX no Windows, não um problema de dados ou
lógica. Se incomodar, a correção é trocar os emojis por ícones SVG inline
(como já fizemos nos menus laterais) ou instalar uma fonte de emoji colorida
reconhecida pelo WebView.

## Como rodar

Pré-requisitos: **JDK 17+** e **Maven 3.9+**.

```bash
mvn clean javafx:run
```

Abre a janela "Fiscal · Colaborador" em 1440×900 com a tela completa.

Alternativa (gera o jar e roda por ele):

```bash
mvn -q clean package
mvn -q javafx:run
```

## Estrutura

```
fiscal-java/
├─ pom.xml                                  # Spring Boot 3.3.4 + JavaFX 21 (openjfx-maven-plugin)
└─ src/main/
   ├─ java/com/you/fiscal/
   │  ├─ FiscalApplication.java             # @SpringBootApplication (main)
   │  └─ JavaFxApplication.java             # sobe o Spring + abre a janela com o WebView
   └─ resources/
      ├─ application.properties
      └─ web/
         └─ index.html                      # front completo — cópia exata do preview publicado
```

## O que está dentro do `index.html` (tudo incluído)

- **Menu lateral IT.FC** (padrão dos módulos): Apuração, WhatsApp, Pendências,
  Esteiras, Templates, IA & Meta.
- **Apuração**: abas "Apuração" / "Radar XML" + botões **Em lote** e
  **Meu espaço** (modais), mesa com 3 colunas (clientes, WhatsApp + esteira,
  IA), esteira real (MODELO V2: Solicitar XML → Prefeitura → SIEG →
  Apuração no Domínio → Gerar guias → Enviar Guia → Confirmar pagamento).
- **WhatsApp**: janela geral estilo WhatsApp Web com abas **Entrada**
  (contatos sem carteira) / **Meus** (carteira do usuário), botão **Assumir**,
  componente único de bolha (cabeçalho verde, balão escuro/branco) reusado
  em toda a app.
- **Modal "Enviar guia"**, **Demanda em lote**, **Meu espaço** (Meus modelos +
  Minhas tags), **Nova tarefa exclusiva do cliente**, **escopo da IA por
  cliente** (não tratar / até certo ponto / tratar tudo).
- **Esteiras (moldes)**: MODELO PADRÃO V1, MODELO V2, Enviar Guia e as
  tarefas avulsas reais (Solicitar XML, SIEG, Apuração no Domínio, ICMS-DIFAL,
  DeSTDA, RBA), com "Ver passos".
- **Pendências**, **Templates & Flows** (Meta), **IA & Meta** (o que a IA faz
  em 3 fases + montagem com Meta Tools).

Os nomes dos clientes e valores são **fictícios** (produção é somente leitura,
nada de conteúdo real de cliente). A equipe (Pedro H. S. Almeida) e as
esteiras/modelos são **reais**, levantados no banco legado.

## Próximo passo (troca do motor)

Hoje os dados moram no próprio `index.html` (arrays JS). Para produção:

1. Expor um pequeno **bridge Java↔JS**: `WebEngine.getLoadWorker()` +
   `JSObject window = (JSObject) engine.executeScript("window")` para
   registrar um objeto Java (`window.setMember("AppFiscal", bridge)`), e
   o JS chama `window.AppFiscal.buscarClientes(...)` em vez de ler o array
   fixo.
2. O `bridge` Java chama os serviços Spring, que por sua vez chamam as
   RPCs/API reais (Supabase legado, ou a nova API do app Fiscal, conforme a
   migração dos bancos).
3. O HTML/CSS/JS não precisa mudar — só a fonte dos dados.
