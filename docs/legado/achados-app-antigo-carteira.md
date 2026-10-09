# Achados do app antigo (Tauri "you-contabilidade"): carteira de clientes e vínculos

Investigação só de leitura, feita em 09/10/2026, sobre o clone em `scratchpad/app-antigo`.
Fontes lidas: `CHANGELOG.md` inteiro (190 entradas), `AGENTS.md`, `docs/agentes/06-clientes-e-departamentos.md`,
`02-banco-de-dados.md`, `03-whatsapp.md` (trechos do tema), as migrações de carteira, vínculo, dono de conversa e
telefone em `supabase/migrations/`, os 50 commits do git (`git log`, `git show --stat`) e as telas em `apps/web/src`.

Datas abaixo são as do changelog ou da migração. "Correções" conta quantas vezes o mesmo problema voltou a ser
consertado. Quando algo não teve prova, está escrito.

---

## (a) Problemas reais encontrados

### 1. Dono da conversa do WhatsApp separado da carteira do cliente (o maior de todos)

- **O que acontecia:** conversa "sumia" para quem cuidava do cliente; ou aparecia para a pessoa errada, inclusive de
  outro departamento, com a notificação do navegador mostrando o texto do cliente.
- **Causa técnica:** havia três "donos" independentes e nada sincronizava:
  `clientes.responsavel_id` (carteira antiga), `cliente_setor_responsavel` (carteira nova por setor) e
  `wa_conversas.atribuido_a` / `atendente_atual` / `transferida_para` (dono da conversa). A RLS da conversa só liberava
  para `atribuido_a`. Cada botão mexia num lado só:
  - `transferir_cliente` mudava só o cliente ("nenhuma toca em wa_conversas, e nao ha gatilho fazendo isso",
    migração `20260911125256`);
  - "Transferir" conversa passava só a conversa;
  - "Finalizar" (`wa_fiscal_finalizar/_varias`) **copiava o dono da conversa para a carteira**, apagando a decisão do
    gestor (`20260917171929`);
  - `wa_receber_mensagem` usava `clientes.responsavel_id` (que é do Fiscal) como dono da conversa **em qualquer
    setor** (`20260911154354`).
- **Frase que resume (migração `20260911154354`):** "Sao 7 caminhos que escrevem o dono e so 2 conferiam o setor; ja
  se limpou 926 conversas em agosto e setembro e o problema sempre voltou, porque se limpava o dado sem impedir a
  escrita."
- **Prova de que voltava:** a limpeza da manhã de 11/09 zerou o indicador e "sem a trava, ele voltou a 156 no mesmo
  dia" (`docs/agentes/02-banco-de-dados.md`).
- **Correções (pelo menos 9):** 08/09 caixa compartilhada Realizze/Societário (499 donos limpos,
  `20260908134315`); 08/09 a mesma no 40% (225 conversas invisíveis, `20260908144519`); 08/09 regra que faltava na
  RLS das mensagens (`20260908143343`); 11/09 `transferir_cliente` leva a conversa + limpeza de 202+11
  (`20260911125256`, `20260911125507`); 11/09 trava de dono fora do setor + limpeza de 156 (`20260911154354/154525`);
  11/09 devolver dono depois da fusão de duplicatas (`20260911164014`); 15/09 transferência que não entregava
  (`20260915180000`); 17/09 carteira definitiva do Arthur + finalizar para de roubar carteira (`20260917171929`);
  17/09 "a carteira manda na conversa" (`20260917175620`, 22 carteiras e 20 conversas corrigidas); 24/09 botão de
  transferir do WhatsApp Fiscal removido (commit `81b144cd`).

### 2. Duas fontes de verdade para a carteira (`responsavel_id` x `cliente_setor_responsavel`)

- **O que acontecia:** colaborador com "carteira quase vazia" na Apuração (Fernando, 23/09); "Credenciais: só o
  responsável do cliente" em cliente que era dele (23/09); tarefa aplicada que sumia da tela; não conseguia remover
  ticket do próprio cliente.
- **Causa:** surgiu a tabela nova `cliente_setor_responsavel`, mas dezenas de RPCs, políticas e telas continuaram
  olhando só `clientes.responsavel_id`. Commit `238d65dc` (24/09): "mesmo padrão de bug já corrigido hoje 3 vezes".
- **Correções (6 em 2 dias, e ainda aberto):** RLS de `clientes` (23/09, aplicada direto, **sem arquivo**); `ApuracaoClaro.jsx`
  (`82726d65`); credenciais (`633836f3`); `tarefa_credenciais` RLS (`20260924155126`); `clientes_com_modelo` e
  `remover_modelo_de_clientes` (`20260924170004`); `ticket_cliente_remover`, `guia_definir_mes`, ordem
  (`20260924172954`).
- **Ainda no código, mesmo defeito (achado nesta leitura, sem correção registrada):** filtros só por
  `responsavel_id` em `fiscal/components/PuxarTarefaModal.jsx:321`, `EditarDemandaClienteModal.jsx:272`,
  `MinhasPendenciasFiscal.jsx:127`, `AplicarModeloLoteModal.jsx:65`, `dashboard/hooks/useAlertasOperacionais.js:99`,
  `useTarefasCriticasPendentes.js:80`, `useTarefasDoAlerta.js:103`, e em `ApuracaoClaro.jsx:187` para
  gerente/assistente ("Minha carteira").
- **Não está no repositório:** o `CREATE TABLE cliente_setor_responsavel` e a função `colaborador_vinculado_ao_cliente`
  não aparecem em nenhum arquivo de migração.

### 3. Quem pode ver qual cliente: regra mudou 6 vezes e sempre de um jeito diferente

- **Sintomas:** gerente do Fiscal não achava cliente (chamado #70, 21/08); assistente não via cliente de código alto
  (31/08); Mapa do setor mostrava só a pessoa logada e "0 clientes" (31/08); ficha do cliente **em branco** para
  colaborador que não era o responsável (Pedro, 23/09).
- **Causas, uma por vez:**
  - RLS `clientes_select` prendia gerente a `setor_id IN (get_user_setores())` (corrigido em `20260825130000`,
    "Regra 11").
  - Clientes espalhados em setores Diretoria/Financeiro/sem setor: todos movidos à força para o Fiscal
    (`20260831200000`), e `responsavel_id` zerado quando o dono não era do Fiscal (`20260831170000`, 31 linhas).
  - Teto de 200 linhas no hook `useClientes` (`PAGE_LIMIT`), com filtro feito no navegador (Denise, 75 clientes,
    via 7).
  - RLS de `usuario_setores` devolvia só a linha do próprio usuário, e o Mapa lia a tabela direto (criada a RPC
    `pessoas_setor_carteira`, `20260831190000`).
  - RLS filtrava a linha "sem erro" e a ficha ficava em branco. A saída foi uma RPC `security definer`
    (`cliente_ficha_para_visualizacao`, aplicada direto no banco, sem arquivo) que libera a ficha para qualquer
    interno. Ou seja: a regra de visão virou "lista restrita, ficha aberta" por remendo, não por desenho.
- **Correções:** 6 (21/08, 25/08, 31/08 três vezes, 23/09).

### 4. Carteira marcada em departamento que não tem carteira

- **O que era:** 10 clientes do Gustavo marcados na "Diretoria" (no mesmo milissegundo, chamada em lote) e 1 da Carla
  no "Financeiro". Lembrava o bug aberto em 25/08 "Vazamento de carteira entre departamentos".
- **Causa:** `atribuir_clientes_em_lote` aceitava qualquer setor. A lista de setores permitidos ficou **duplicada à
  mão** no front (`useSetoresOperacionais.js`: Fiscal, Pessoal, Legal, Societário) e no banco
  (`c_operacionais constant text[] := ARRAY['Fiscal','Pessoal','Legal','Societário']`).
- **Contradição não resolvida:** o próprio arquivo registra que o cofre diz "o Fiscal é o ÚNICO com carteira",
  mas a tela oferece quatro (`20260911161100`). Das 1.005 linhas de carteira, 994 eram do Fiscal.
- **Correções:** 1 trava + 1 limpeza (`20260911161100`, `20260911161126`).

### 5. Conversa duplicada com o mesmo contato

- **O que acontecia:** o mesmo número aparecia em dois cards, um com o histórico e outro vazio em letra maiúscula;
  mensagens perdidas com `duplicate key ... uq_wa_conversa_aberta`.
- **Causa:** o Fiscal tinha 1 número e 2 conexões (principal e reserva). As funções procuravam a conversa pela
  **conexão** e não pelo **setor**, escolhendo a conexão com `LIMIT 1` "sem `ORDER BY` -- ou seja, sem criterio"
  (`20260911152725`). Ao fundir as duplicatas, a escolhida (a com mais mensagens) às vezes estava sem dono, e a
  conversa "sumiu" de quem a via (`20260911164014`).
- **Correções (4):** 04/09 recebimento (`20260904160000`); 08/09 recebimento de novo (`20260908211854`); 11/09 abrir
  conversa pela ficha + índice único (`20260911152725/153003/153432`); 11/09 dono devolvido depois da fusão.

### 6. Transferência que não transferia

- **O que acontecia:** conversa transferida aparecia em "Transferidos" mas abria "Sem mensagens ainda" (José
  Everaldo, 55 e 83 mensagens reais). 14 conversas presas.
- **Causa:** `wa_fiscal_transferir` gravava só `transferida_para`; a RLS só libera para `atribuido_a`. Nunca gravou
  `transferida_por` (o aviso sempre dizia "Um colaborador transferiu..."). Não existia botão de aceitar.
- **Correções (3):** 15/09 entrega na hora (`20260915180000`); 17/09 colaborador não transfere cliente de outra
  carteira, gestor leva a carteira junto (`20260917175620`); 24/09 transferir só pelo Mapa (`81b144cd`).

### 7. Contato ligado ao cliente: "assunto" perdeu o setor e quebrou telas e permissões em silêncio

- **O que acontecia:** coluna de WhatsApp da ficha do Fiscal **nunca** mostrava conversa ("cliente foi passado pra
  minha carteira e ainda não consigo ver as mensagens antigas", Pedro); seletor de QSA/quem trata vazio;
  colaborador não conseguia editar contato nem trocar tag, "mesmo a tela mostrando que podia".
- **Causa:** em 03/09 uma leva de 11 migrações aplicadas ao vivo (**sem arquivo e sem entrada no changelog**) tirou
  o setor do "assunto" (`setor_assuntos.setor_id` vazio em todas as linhas). `cliente_arvore_contatos` parou de
  devolver `setores`, mas 4 telas continuaram lendo (`PainelWppColuna3.jsx`, `ResponsaveisGeraisCliente.jsx`,
  `WaNovaConversaModal.jsx`, `AbaCadastroCliente.jsx`). A RLS de `cliente_pessoas` e `cliente_assunto_vinculos`
  continuou testando `setor_assuntos.setor_id = ANY(meus_setores_ids())` até 24/09: "a gravação sempre falhava calada"
  (`20260924190000`).
- **Correções (3):** 15/09 `setores` volta calculado por tag (`20260915140000`) + 8 migrações recuperadas; 22/09
  coluna 3 deixa de exigir tag de assunto (`be2cbfed`); 24/09 RLS dos contatos (`20260924190000`).

### 8. "Quem trata" e "QSA" com três mecanismos diferentes e o mesmo nome

- **O que era:** o papel existia como (1) flag na pessoa (`eh_representante_legal` e "responsável operacional geral",
  gravadas por `EditarResponsavelModal`), (2) vínculo de assunto em `cliente_assunto_vinculos` ("Responsável (Quem
  trata)") e (3) tag manual em `cliente_pessoa_tags`. O changelog de 12/09 registra "dois mecanismos com o mesmo
  nome e **251 clientes com 2+ 'quem trata'**".
- **Dado sujo:** 1.649 vínculos "quem trata", dos quais **1.173 sem criador** (carga de 18/06 a 15/07). Em 12/09,
  539 vínculos foram removidos e viraram tag em três ordens seguidas (`20260912152504`, `153331`, `155617`). Os 1.173
  ficaram. "Amarrar quem tem a tag ao card Responsáveis" ficou pendente ("não faça ainda").
- **Casamento por texto:** as tags de assunto eram ligadas aos assuntos **pelo nome**. Renomear a tag
  "GERAL OPERACIONAL" para "Responsável (Quem trata)" obrigou a renomear 15 assuntos, senão "essas tags sumiam de todo
  contato ... silenciosamente". O histórico do QSA é gravado com `campo: 'Representante legal (QSA)'`, e o nome
  "tem que ser IDÊNTICO ... senão o histórico nunca aparece (são strings comparadas, não id)".
- **Regra do QSA só no front:** "obrigatório ter outra pessoa" só existe porque o botão Salvar do modal exige
  escolher alguém; não há trava no banco.

### 9. Telefone: duas regras de limpeza e cada tela com a sua

- **O que acontecia:** o sistema não entendia que "5519974220182", "(19) 97422-0182" e "1974220182" são o mesmo
  número. Etiqueta da 40% "nunca funcionou pra ninguém" (08/09).
- **Causa:** `normalizar_telefone` (tira 55 e o nono dígito, 10 dígitos, usada por 49 funções) x `wa_norm_fone`
  (últimos 11, usada por 10 funções, entre elas o "Atender" do Fiscal). "99% dos numeros gravados fora de qualquer
  padrao, 104 arquivos do front com limpeza propria" (commit `c2aac294`). O telefone do cliente mora em pelo menos
  6 lugares: `clientes.contato_operacional_whatsapp`, `clientes.responsavel_legal_whatsapp`, `cliente_whatsapps`,
  `clientes_contatos`, `cliente_pessoas.whatsapp/telefone`, `clientes_contatos_financeiros`. A coluna 3 do Fiscal
  casava conversa por **sufixo de 8 dígitos** (`PainelWppColuna3.jsx:129`).
- **Correções (4):** 01/09 índices (`20260901213553`); 08/09 `chaveEtiqueta()` no front; 17/09 chave única no banco
  (`20260917175650`) e coluna `*_chave` gerada (`20260917180245`).

### 10. Pessoa física sem entidade própria e contatos duplicados

- **O que era:** "'pessoa física' nunca teve linha própria no banco — sempre foi um agrupamento CALCULADO no front
  por CPF/telefone/nome (`montarCadastro`)". Pessoa = uma linha de `cliente_pessoas` **por empresa**, copiada a cada
  vínculo. O "Adicionar pessoa" carrega até 20.000 linhas e filtra no navegador.
- **Remendo de 12/09:** 1.980 perfis criados em lote (`20260912222523`). "Telefone compartilhado por 3+ primeiros
  nomes diferentes (escritório, contador) não junta ninguém, senão 26 pessoas viravam uma." Passo 2 (achar o
  perfil pelo telefone) ficou pendente, então pessoa só da Realizze/40% ainda podia ganhar perfil repetido.
- **Base de clientes paralela:** em 12/09 nasceram `you_clientes_v2*` "separadas de `clientes`" e 36 tabelas
  `<prefixo>_clientes_v2` por empresa (`20260912174754`, `20260912182807`).
- O changelog cita "duplicidade recente de contatos" relatada pelo William, sem detalhar a causa. **Sem mais
  evidência no repositório.**

### 11. Dono atribuído por sorteio ou por herança em setor sem carteira

- **O que acontecia:** na Realizze, 340 de 416 conversas nasceram com dono; no Societário, 159 de 176 (142 do João).
  No 40%, 225 de 542 conversas ficaram invisíveis para todos (146 com mensagem não lida).
- **Causa:** `wa_escolher_colaborador_carteira` sorteava dono em qualquer setor; `wa_abrir_conversa` herdava
  `clientes.responsavel_id` pelo "+" ("porta de trás"). O front do 40% já se comportava como "sem carteira"
  (`ocultarAcoesCarteira`) e o banco continuava atribuindo: "as duas metades discordavam".
- **Efeito colateral:** em 83% das conversas da Realizze o `atribuido_a` era o único registro de quem atendeu; foi
  preciso gravar 499 eventos `dono_anterior` antes de limpar.
- **Correções:** 2 (08/09 duas vezes) mais o item 1.

### 12. Mesma regra de acesso copiada em dois lugares do banco

- `wa_conversas_select` e `wa_mensagens_select` tinham "a PRÓPRIA CÓPIA da mesma lógica". Mexer numa só fazia a
  conversa "aparecer na lista e abrir VAZIA, sem erro" (`20260908143343`). O mesmo sintoma voltou em 15/09
  (transferência) por outro caminho.

### 13. Nome da empresa gravado como nome do contato

- 130 conversas com o nome da empresa no lugar do nome da pessoa (ex.: "LUCY GIRLMODAS FASHION LTDA" no lugar de
  "Renato"). `wa_receber_mensagem` caía num `COALESCE` de nome_fantasia/razão social, e o nome real que chegava
  depois era descartado. A solução foi uma trava no campo (`trg_wa_nome_contato_nunca_empresa`,
  `20260908154233`), não a correção da função de 283 linhas.

### 14. Contas de teste e grupos presos a pessoas reais

- "Usuario Teste" (nível CEO, sem setor) era responsável por 19 clientes reais (`20260904200000`) e tinha 11
  conversas de outros departamentos. "~60 grupos do sistema ainda estão presos a uma pessoa" (08/09, pendente).

### 15. Mudanças de banco sem arquivo (histórico perdido)

- "1.244 das 1.354 migrations já aplicadas no banco não têm arquivo correspondente aqui" (15/09). A RLS nova de
  `clientes` (23/09), `cliente_ficha_para_visualizacao`, `colaborador_vinculado_ao_cliente` e a criação de
  `cliente_setor_responsavel` não estão em arquivo. Em 19/08 e 20/08 também foram RPCs para produção sem arquivo.
  Consequência direta: o item 7 só foi entendido 12 dias depois.

### 16. Falhas silenciosas ("diz que fez mas não fez")

- RLS barra e a consulta volta 0 linhas sem erro (ficha em branco, conversa vazia, contato que "salva" e não salva).
- `update` sem `.select()` mostra sucesso falso (regra de ouro nº 8 do `AGENTS.md`).
- Aplicar modelo mostrava "sucesso" quando a RPC criava 0 tarefas (`784288a8`).
- `catch` silencioso escondeu um erro por horas ("nenhuma etiqueta criada ainda" com 6 gravadas, 08/09).
- Vínculo automático YOU↔Realizze por CNPJ "100% silencioso, sem tela; CNPJ digitado errado = vínculo nunca
  acontece, sem erro visível".
- Escopo de empresa "fail-open": "~1/3 dos clientes nao tem empresa identificavel ... 'nao sei a empresa' sempre
  passa" (`20260817220000`).

### 17. Dez cópias da mesma tela

- Cada departamento tinha seu `WaConversa.jsx`, `WhatsAppPage.jsx` e `useClienteForm.js`. Correção feita numa cópia e
  esquecida nas outras: checagem de CNPJ duplicado nunca rodava para colaborador nas 4 cópias de `useClienteForm.js`
  (01/09); campos de Identificação corrigidos só no Fiscal em 03/08 e portados para Legal/Pessoal/Societário em 21/08;
  "mensagem fora de ordem" portada em 3 levas. Existem dois `WaListaFiscal.jsx` (`whatsapp/components/` e
  `whatsapp/fiscal/`).
- Legal/Pessoal/Societário tinham tabelas e RPCs próprias "100% desconectado do front".

### 18. Identificadores fixos e nomes comparados por texto

- UUID do setor Fiscal fixo dentro das funções (`c_fiscal constant uuid := '85aa9f03-...'`); `setor_id` do
  Societário fixo no corpo da função de modelos ("se esse setor for recriado ... para de achar modelos
  silenciosamente").
- Setor comparado por nome no front ("Diretorria" com 2 R em 7 pontos de 5 arquivos, 21/08).
- O botão "Atender" do Legal checava `atribuido_a`, mas o Legal grava `atendente_atual` (19/08).

### 19. Contradição na documentação antiga (registrar, não resolver)

- `06-clientes-e-departamentos.md` diz: "Reatribuir responsável do Fiscal reatribui automaticamente conversas de
  WhatsApp LIVRES ... via cadeia de triggers → `wa_fiscal_reatribuir_por_cliente`". A migração `20260911125256`
  diz que, lendo as funções vivas em 11/09, "nenhuma toca em wa_conversas, e nao ha gatilho fazendo isso". Não dá
  para saber, pelo repositório, qual era verdade em cada data.

---

## (b) Modelo de dados antigo (tabelas e chaves)

| Assunto | Tabela / coluna | Observação |
|---|---|---|
| Cliente (PJ) | `clientes` (id, cnpj único, codigo único, `setor_id`, `responsavel_id` → `usuarios_internos.id`, `empresa_id`, `contato_operacional_whatsapp`, `responsavel_legal_whatsapp`) | Uma base da YOU; `setor_id` forçado para Fiscal em 31/08 |
| Carteira nova | `cliente_setor_responsavel` (cliente_id, setor_id, colaborador_id) | Sem `CREATE` no repositório; 994 de 1.005 linhas do Fiscal |
| Histórico de carteira | `transferencias_cliente`, `carteira_revisao`, `solicitacao_carteira_criar` (RPC), `cliente_alteracoes` | Trava `trg_bloqueia_transf_colaborador` |
| Pessoa por empresa | `cliente_pessoas` (cliente_id, nome, cpf, whatsapp, telefone, flags de papel, `pessoa_fisica_id`) | Pessoa copiada por empresa |
| Perfil da pessoa | `cliente_pessoas_fisicas` (+ `telefones text[]`, `origens text[]`), `cliente_pessoa_fisica_contatos`, `_login_segredos` | Criado em 02/09; em massa em 12/09 |
| Papel/assunto | `setor_assuntos` (setor_id vazio desde 03/09), `cliente_assunto_vinculos` (removido_em/removido_por) | Modelo antigo de "quem trata" |
| Tags | `tags_registro` (pai_id = categoria), `cliente_pessoa_tags`, `cliente_tags_registro`, `tags_registro_bloqueios` | Tag ligada a assunto por nome |
| Outros telefones | `cliente_whatsapps`, `clientes_contatos`, `clientes_contatos_financeiros` (N por CNPJ) | Mais 2 colunas em `clientes` |
| Conversa | `wa_conversas` (setor_id, instancia_id, cliente_id, telefone, `atribuido_a`, `atendente_atual`, `transferida_para`, `fiscal_estado`, `nome_contato`, `nome_salvo`) | Dono em 3 colunas |
| Rastro de atendimento | `wa_atendimento_eventos` (tipo `dono_anterior`), `wa_mensagens.enviado_por` | |
| Setor | `setores` (`eh_departamento`, `caixa_compartilhada`, `acesso_por_empresa`, `fluxo_suporte`), `usuario_setores`, `usuario_empresa_nivel` | |
| Bases paralelas | `you_clientes_v2*`, `<empresa>_clientes_v2*` (36 tabelas) | Criadas em 12/09 |

Funções-chave: `wa_receber_mensagem` (283 linhas), `wa_achar_cliente_por_telefone`, `wa_abrir_conversa`,
`wa_escolher_colaborador_carteira`, `wa_fiscal_transferir`, `wa_fiscal_finalizar(_varias)`, `transferir_cliente`,
`transferir_clientes_em_lote`, `atribuir_cliente(s_em_lote)`, `desatribuir_cliente`, `carteira_limpar`,
`cliente_arvore_contatos`, `pessoas_setor_carteira`, `mapa_setor_filtrado` (só nível colaborador),
`normalizar_telefone` e `wa_norm_fone`.

---

## (c) Regras que ficavam no front e deveriam estar no banco

1. **Filtro "minha carteira"** por `responsavel_id` em cima da RLS (`ApuracaoClaro.jsx`, `PuxarTarefaModal.jsx`,
   `EditarDemandaClienteModal.jsx`, `MinhasPendenciasFiscal.jsx`, `AplicarModeloLoteModal.jsx`, hooks do dashboard).
   Cada tela decidia a carteira de um jeito.
2. **Teto de 200 clientes** e filtro de carteira feito no navegador (`useClientes`, `PAGE_LIMIT`).
3. **Lista de departamentos com carteira** escrita à mão no front (`useSetoresOperacionais.js`) e copiada no banco.
4. **Quem é "dono da carteira" para credenciais** calculado na tela (`CredenciaisTicketClaro.jsx:54`,
   `PainelTicketColuna3.jsx:595`).
5. **QSA obrigatório com substituto** garantido só pelo botão Salvar do modal.
6. **Histórico do QSA** gravado pela tela em `cliente_alteracoes` com nome de campo em texto.
7. **Pessoa física consolidada** no navegador (`montarCadastro`) e status Ativo/Inativo calculado depois.
8. **Busca de pessoa existente** carregando 20.000 linhas e filtrando no cliente; deduplicação por telefone feita na
   tela.
9. **Casamento conversa ↔ cliente** por sufixo de 8 dígitos (`PainelWppColuna3.jsx`) e normalização de telefone em
   104 arquivos.
10. **"Caixa compartilhada"** e "sem carteira" decididos por prop da tela (`ocultarAcoesCarteira`) enquanto o banco
    atribuía dono.
11. **Escopo da empresa** de um vínculo de cliente decidido pelo front ("front decide o escopo", 17/08), com o banco
    em modo "fail-open".
12. **Visão por nível** (colaborador/assistente/gerente/diretor/CEO) testada em dezenas de telas por texto; ao criar o
    nível "assistente", "~150 arquivos que checam os 3 níveis antigos por string exata não foram revisados".

---

## (d) Lições objetivas para o desenho novo

1. **Uma só fonte para "quem atende o cliente".** Uma tabela de carteira (cliente, departamento, usuário), sem
   coluna espelho em `clientes`. Toda RPC, política e tela lê dela por uma única função.
2. **O dono da conversa é derivado da carteira, nunca gravado à parte.** Se precisar de dono provisório, ele tem
   prazo e volta sozinho, e a carteira nunca é reescrita por "finalizar".
3. **Uma única porta de escrita** para carteira e para dono (uma RPC por ação, com trava no banco). Limpar dado sem
   fechar a porta não resolve: foram 926 conversas limpas e o problema voltou no mesmo dia.
4. **Departamento sem carteira é um dado** (`setor.tem_carteira`), lido pelo banco e pela tela. Nada de lista
   copiada nem UUID fixo no corpo da função.
5. **Regra de visão em um lugar só**, a mesma para lista e para ficha, para conversa e para mensagem (uma função
   chamada pelas duas políticas).
6. **Transferir é uma operação só** (cliente + conversa + histórico, na mesma transação), com quem transferiu
   gravado.
7. **Papel do contato (QSA, quem trata, sócio, terceiro) é um dado por id**, numa tabela de vínculo, com histórico no
   banco. Nunca por nome de tag, nunca com dois mecanismos de mesmo nome.
8. **Pessoa é entidade própria desde o início**, com ponteiro do contato para ela; nunca juntar pessoas por nome, e
   telefone compartilhado (escritório, contador) não junta ninguém.
9. **Telefone com uma regra de chave no banco** (coluna gerada, com índice), e a tela não normaliza nada por conta
   própria.
10. **Conversa única por (departamento, telefone)**, com índice único desde o primeiro dia; nunca procurar por conexão,
    nunca `LIMIT 1` sem ordem.
11. **Negação tem que aparecer.** Se a permissão bloqueia, a função devolve erro claro; toda escrita confere linhas
    afetadas; proibido `catch` silencioso e "sucesso" sem conferir o retorno.
12. **Toda mudança de banco vira arquivo versionado na mesma hora**, incluindo políticas e funções.
13. **Sem bases de cliente paralelas** (nada de `clientes_v2` por empresa); o app do Fiscal guarda só o ponteiro.
14. **Sem conta de teste em dado real**; grupos e contatos internos nunca presos a uma pessoa.
15. **Um módulo só para todos os departamentos**, com o departamento como dado, para não corrigir 10 vezes.
16. **Rastro de atendimento próprio** (quem atendeu, quando), nunca depender do campo de dono para saber o histórico.
