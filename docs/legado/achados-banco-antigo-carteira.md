# Achados — banco antigo (legado `uvmcfnghdsmpzhijqlos`): carteira do Fiscal e vínculos

Data: 09/10/2026. Leitura feita só com SELECT. Nenhum dado pessoal copiado: só contagens.
Setor Fiscal no legado = `85aa9f03-b91d-4d25-9f6d-366c6fe2d813` (12 usuários; é o único setor com carteira preenchida).

---

## 1. Modelo de dados encontrado

### 1.1 Empresa (cliente PJ) e "dono na carteira" — DUAS fontes da mesma verdade

| Tabela | O que guarda | Chaves |
|---|---|---|
| `clientes` (1.545 linhas) | Empresa. **Dono = `responsavel_id` + `setor_id` direto na linha.** Também guarda em texto livre: `responsavel_legal_nome/cpf/whatsapp`, `contato_operacional_nome/whatsapp`, `contato_2_*`, `contato_financeiro_*`, `faturador_1/2`. Dois "ativos": `ativo` (bool) e `crm_status`. | PK id; UNIQUE `cnpj`, UNIQUE `codigo`; FK `responsavel_id → usuarios_internos` (ON DELETE SET NULL); FK `setor_id → setores`; CHECK uf/regime/crm_status |
| `cliente_setor_responsavel` (1.103) | Carteira "nova": um dono por (empresa, setor). | UNIQUE `(cliente_id, setor_id)`; FKs cliente (CASCADE), setor (RESTRICT), colaborador (CASCADE), atribuido_por |
| `transferencias_cliente` (3.150) | Histórico de troca de dono. | FKs; CHECK de consistência por tipo (atribuicao/desatribuicao/transferencia) |
| `carteira_revisao` (89) | Fila de revisão de carteira ("já tem responsável" / "não encontrado"). | FKs, CHECK status |
| `solicitacoes_carteira` + `_empresas` | Pedido de colaborador para pegar empresa (vindo de conversa). | FKs. **0 linhas — nunca usado.** |
| `cliente_permissao_setor` | Liberar empresa a um setor. | UNIQUE (cliente, setor). **0 linhas.** |
| `usuario_pasta_cliente` | Pasta local por usuário/empresa (3 linhas). | — |

Gatilhos que mexem no dono (`clientes`):
- `tg_cliente_sync_vinculo` → `trg_sincronizar_vinculo_cliente`: copia `clientes.responsavel_id/setor_id` para `cliente_setor_responsavel` com upsert. **Só vai num sentido e nunca apaga**: se o dono é removido em `clientes`, a linha da carteira nova fica. E grava `atribuido_por = responsavel_id` (o próprio dono como autor).
- `trg_registrar_transferencia` → grava histórico. Pula quando a empresa sem dono só troca de setor.
- `trg_bloqueia_transf_colaborador` → nível colaborador não troca dono/setor (único bloqueio de regra de carteira).
- `trg_fiscal_reatribuir_responsavel` → ao trocar dono/WhatsApp, re-atribui conversas do Fiscal (ver 1.4).

### 1.2 Pessoas, QSA, "quem trata", terceiros

| Tabela | O que guarda | Chaves |
|---|---|---|
| `cliente_pessoas` (3.266) | Pessoa **dentro de uma empresa** (uma linha por empresa — a pessoa é copiada). Tem nome, cpf, whatsapp, telefone, endereço e flags `eh_operacional`, `eh_representante_legal`, `apenas_representante_legal`, `eh_responsavel_operacional_geral`, `classificacao` (texto). Ponteiro opcional `pessoa_fisica_id`. | FK cliente (CASCADE), FK pessoa_fisica (SET NULL). **Sem UNIQUE nenhum** (nem cliente+cpf, nem cliente+pessoa_fisica). |
| `cliente_pessoas_fisicas` (2.010) | Cadastro "único" de pessoa física (CPF opcional, `telefones` em array). | UNIQUE parcial `cpf` (cpf cru, não normalizado) |
| `cliente_pessoa_fisica_contatos` | Contatos da PF. **0 linhas** (telefone ficou no array). | FK |
| `cliente_assunto_vinculos` (2.299; 1.748 ativos) | "Quem trata" = pessoa × empresa × assunto (`setor_assuntos`). Exclusão lógica por `removido_em`. | FKs; **sem UNIQUE** |
| `cliente_pessoa_tags` + `tags_registro` | Etiquetas da pessoa. Mistura dado derivado (DDD/DDI) com papel ("Responsável (Quem trata)", "Representante legal (QSA)", "Fiscal", "Financeiro"...). | FKs |
| `soc_socios` / `soc_processo_socios` | Sócios do Societário (CPF cifrado + hash). **3 linhas** — não é o QSA da carteira. | UNIQUE cpf_hash |
| Terceiros | **Não existe tabela de terceiro** (contador externo, procurador, funcionário) para o Fiscal. Só a `classificacao` em texto (7 linhas preenchidas: outro 5, familiar 2). `quarenta_vinculos`/`quarenta_loja_contato_papeis` são de outra empresa (40%). |

Tabelas cópia por marca (`beec_/irpf_/quarenta_/winny_/you_/gestao_lojas_/realizze_clientes_v2` e filhas): **todas com 0 linhas** — estrutura repetida 7 vezes, abandonada.

### 1.3 Telefones / WhatsApp — o mesmo número em 6 lugares

| Onde | Linhas |
|---|---|
| `cliente_pessoas.whatsapp` | 1.627 |
| `clientes.contato_operacional_whatsapp` (texto) | 999 |
| `clientes_contatos.numero` (+ `eh_whatsapp`, `setores` jsonb) | 439 |
| `clientes.responsavel_legal_whatsapp` (texto) | 222 |
| `cliente_pessoas.telefone` | 15 |
| `cliente_whatsapps` | 1 |
| `cliente_pessoas_fisicas.telefones` (array) | 1.309 PFs com algum |

Total ≈ 3.300 ocorrências para **789 números distintos**. Nenhum UNIQUE de telefone em nenhuma delas.
Chave de comparação = `normalizar_telefone()`: tira DDI 55, corta para os 11 últimos dígitos e **remove o 9º dígito** (fica com 10). Número estrangeiro vira lixo; dois números que diferem só no 9 colidem.

### 1.4 Conversa de WhatsApp e atribuição a usuário

| Tabela | O que guarda | Chaves |
|---|---|---|
| `wa_conversas` (3.779; Fiscal 732) | `cliente_id` (UM só), `atribuido_a`, `atendente_atual`, `assumido_por`, `transferida_para/de/por`, `finalizada_por`, `status` + `situacao` + `fiscal_estado` + `arquivada` (4 estados paralelos). | FK cliente (SET NULL), atribuido_a, assumido_por, setor, instancia. **Sem FK** em `atendente_atual`, `transferida_para/de/por`, `finalizada_por`, `nome_salvo_por`. UNIQUE parcial: 1 conversa aberta por (instância, telefone) e por (Fiscal, telefone). |
| `wa_vinculo_historico` (545) | Troca de cliente da conversa. | FKs conversa/cliente; sem FK usuario |
| `wa_atendimento_registros` | Atendimento por colaborador. | sem FK em conversa |
| `wa_contatos_internos` | Números internos (funcionários). `usuario_id` opcional. | UNIQUE (setor, telefone_norm) |
| `wa_transferencias_departamento` | Transferência entre setores. | FKs |
| `usuario_setores` | Usuário × setor (`principal`, `recebe_fila`). | PK (usuario, setor) |
| `usuarios_internos` | Usuários (nível colaborador/assistente/gerente/diretor/ceo). | UNIQUE cpf, UNIQUE email |

Como a conversa do Fiscal ganha cliente e dono (funções `wa_fiscal_reatribuir_por_telefone` e `wa_achar_cliente_por_telefone`):
- Procura o telefone em `clientes_contatos`, depois nos campos texto de `clientes`, depois `cliente_whatsapps` — **com `LIMIT 1`, sem desempate definido**. Se o número está em 2+ empresas, pega uma qualquer.
- **Não procura em `cliente_pessoas.whatsapp`**, que é a maior fonte (1.627 linhas).
- Grava `cliente_id = COALESCE(cliente_id, novo)`: nunca corrige um cliente errado já gravado.
- Só re-atribui conversa sem dono e não assumida.
- Gatilho `wa_dono_fora_do_fiscal_tem_que_ser_do_setor` valida que o dono pertence ao setor **em todos os setores menos no Fiscal**, e engole erro (`EXCEPTION WHEN OTHERS → RETURN NEW`).

### 1.5 RLS (resumo)
- `clientes`: RESTRICTIVE `is_interno()` + SELECT/UPDATE por nível; colaborador vê se é `responsavel_id`, se está em `cliente_setor_responsavel` (OU das duas fontes) ou se está em setor cujo **nome** é Financeiro/Legal/Pessoal/Societário (`col_ve_todos_clientes`, nome fixo no código).
- `cliente_setor_responsavel`: só diretor/assistente/gerente alteram.
- `cliente_pessoas`, `cliente_pessoas_fisicas`, `cliente_assunto_vinculos`: **qualquer interno insere e altera** (sem olhar carteira). PF não tem DELETE.
- `clientes_contatos`: qualquer interno que vê a empresa altera.
- `wa_conversas`: por nível e setor; colaborador por `atribuido_a`.

---

## 2. Problemas medidos

| # | Problema | Número | Consulta (resumo) |
|---|---|---|---|
| P1 | Empresas ativas **sem dono** (`clientes.responsavel_id` nulo) | **124 de 1.121 ativas** (73 delas também sem setor) | `select count(*) from clientes where responsavel_id is null and coalesce(ativo,true)` |
| P2 | Empresas ativas sem linha na carteira nova do Fiscal | **123** | `... not exists(select 1 from cliente_setor_responsavel r where r.cliente_id=c.id and r.setor_id=<fiscal>)` |
| P3 | **As duas fontes discordam**: carteira nova tem dono e `clientes` não | **27** | `clientes.responsavel_id is null and exists(csr fiscal)` |
| P3b | `clientes` tem dono e carteira nova não | 1 | `responsavel_id not null and setor=fiscal and not exists(csr)` |
| P3c | Donos diferentes nas duas fontes | 1 | `csr.colaborador_id <> clientes.responsavel_id` |
| P4 | Mais de um dono no mesmo departamento | **0 na tabela** (UNIQUE impede) — mas o problema real é P3: duas tabelas, cada uma com "o dono" | — |
| P5 | Empresas inativas que continuam com dono | **80** | `coalesce(ativo,true)=false and responsavel_id is not null` |
| P6 | `crm_status` inútil: **100% "inativo"** (1.545), inclusive as 1.121 com `ativo=true` | 1.545 | `group by ativo, crm_status` |
| P7 | Auditoria falsa: `atribuido_por` = o próprio dono | **928 de 1.103** | `cliente_setor_responsavel where atribuido_por = colaborador_id` |
| P8 | Rotatividade da carteira | 2.727 atribuições, 361 desatribuições, 62 transferências; 60 sem autor | `transferencias_cliente group by tipo` |
| P9 | Fila de revisão de carteira parada | 54 pendentes (27 "não encontrado", 27 "já tem responsável") | `carteira_revisao group by categoria,status` |
| P10 | CPF do responsável legal guardado **em texto em `clientes`** | **1.079 empresas**; 84 com tamanho ≠ 11 | `responsavel_legal_cpf` normalizado |
| P11 | Esse CPF texto **não existe como pessoa** ligada à empresa | **1.062** (e 1.048 nem existem em `cliente_pessoas_fisicas`) | `not exists(cliente_pessoas p where p.cliente_id=c.id and cpf igual)` |
| P12 | Mesmo CPF (texto) em 2+ empresas | 62 CPFs; **11 em carteiras de usuários diferentes** (empresas ativas) | `group by cpf having count(distinct responsavel_id)>1` |
| P13 | Pessoa física ligada a empresas de **donos diferentes** | **45 pessoas** (247 pessoas estão em 2+ empresas; uma está em 44 empresas) | `cliente_pessoas join clientes group by pessoa_fisica_id having count(distinct responsavel_id)>1` |
| P14 | Mesma pessoa física **repetida dentro da mesma empresa** | **456 pessoas** | `group by pessoa_fisica_id having count(*) > count(distinct cliente_id)` |
| P15 | Pessoa com CPF em `cliente_pessoas` mas sem cadastro único | 41 (de só 107 com CPF) | `cpf not null and pessoa_fisica_id is null` |
| P16 | Pessoa física sem CPF | **1.956 de 2.010** (97%); 44 nomes repetidos entre elas (possível duplicata) | `cpf is null`; `group by lower(nome)` |
| P17 | Pessoa física órfã (não ligada a nenhuma empresa) | 561 | `not exists(cliente_pessoas.pessoa_fisica_id)` |
| P18 | CPF gravado com máscara em `cliente_pessoas` | 38 (UNIQUE de CPF compara texto cru) | `cpf <> só dígitos` |
| P19 | Telefone em **2+ empresas** | **260 de 789 números**; 5 números em 10+ empresas; máx. 55 empresas | union das 5 fontes, `having count(distinct cliente_id)>1` |
| P20 | Telefone em empresas ativas de **donos diferentes** | **33** | idem, `count(distinct responsavel_id)>1` |
| P21 | Telefone em 2+ pessoas diferentes | 41 | idem por `pessoa_fisica_id` |
| P22 | Telefone com formato fora do padrão (≠10 dígitos após normalizar) | 50 | `length(normalizar_telefone(x))<>10` |
| P23 | **Conversas do Fiscal cujo número está em 2+ empresas** (o `cliente_id` único é um chute) | **251 de 732 (34%)** | `wa_conversas fiscal join mapa telefone→nº empresas where n>1` |
| P24 | Conversas do Fiscal sem cliente | 79 (todas abertas); 21 delas têm o número cadastrado em alguma empresa | `cliente_id is null` |
| P25 | Conversas ligadas a empresa inativa / empresa sem dono | 47 / 19 | join `clientes` |
| P26 | Conversa atribuída a usuário diferente do dono da carteira | 2 | `atribuido_a <> clientes.responsavel_id` |
| P27 | Conversa do Fiscal sem `atribuido_a` | 129 | `atribuido_a is null` |
| P28 | Conversa que trocou de cliente | 27 | `wa_vinculo_historico group by conversa having count(distinct cliente_id)>1` |
| P29 | Estado da conversa incoerente: `status='aberta'` em 731 de 732, enquanto `fiscal_estado` diz 495 finalizadas | 731 / 495 | `group by status`, `group by fiscal_estado` |
| P30 | Ponteiro para usuário inexistente (coluna sem FK) | `transferida_para` 13; `atendente_atual` 1; `cliente_pessoas.created_by` 1 | `not exists(usuarios_internos)` |
| P31 | Atendimento apontando conversa inexistente | 4 | `wa_atendimento_registros not exists(wa_conversas)` |
| P32 | "Quem trata": linha **exatamente duplicada** (mesma empresa+assunto+pessoa ativa) | **361** | `group by cliente_id,assunto_id,pessoa_id having count(*)>1` |
| P33 | "Quem trata" com 2+ pessoas no mesmo assunto | 364 combinações empresa×assunto (quase todas são P32) | `group by cliente_id,assunto_id` |
| P34 | "Quem trata" em assunto desativado | 174 | join `setor_assuntos where not ativo` |
| P35 | Papel duplicado em flag e etiqueta e discordando: QSA | flag `eh_representante_legal` 1.373 × etiqueta "Representante legal (QSA)" 47; 1.340 com flag sem etiqueta, 14 com etiqueta sem flag | joins `cliente_pessoa_tags` |
| P36 | Papel "quem trata" em etiqueta × tabela de assuntos discordando | etiqueta 547; 336 com etiqueta sem assunto; 693 com assunto sem etiqueta | idem |
| P37 | Empresas ativas sem representante legal / sem contato operacional cadastrado como pessoa | 163 / 219 | `not exists(cliente_pessoas ... eh_representante_legal / eh_operacional)` |
| P38 | Contatos em texto livre na empresa (deveriam ser pessoa/ID) | `responsavel_legal_nome` 1.360; `contato_operacional_nome` 1.320; `contato_financeiro_nome` 1.347; `contato_2_nome` 53; `faturador_1` 56 | `count(nullif(btrim(campo),''))` |
| P39 | `clientes_contatos.setores` (jsonb de setores) | 439 de 439 vazios `[]` — o "de que setor é o contato" nunca foi preenchido; a função trata vazio como "vale para todos" | `setores='[]'` |
| P40 | Empresa sem CNPJ / CNPJ com 11 dígitos (CPF no campo CNPJ) | 71 / 17 | normaliza `cnpj` |
| P41 | Duplicidade de empresa | 0 por CNPJ normalizado; 6 raízes de CNPJ repetidas (matriz/filial, pode ser legítimo); 8 razões sociais repetidas | `group by cnpj / left(cnpj,8) / lower(razao_social)` |
| P42 | Contatos internos sem usuário | 10 de 15 (`wa_contatos_internos.usuario_id` nulo) | `usuario_id is null` |

Consulta-base de telefones usada em P19–P23:
```sql
with tel as (
 select id cliente_id, null::uuid pessoa_id, normalizar_telefone(contato_operacional_whatsapp) t from clientes where nullif(btrim(contato_operacional_whatsapp),'') is not null
 union all select id, null, normalizar_telefone(responsavel_legal_whatsapp) from clientes where nullif(btrim(responsavel_legal_whatsapp),'') is not null
 union all select cliente_id, null, normalizar_telefone(numero) from clientes_contatos where nullif(btrim(numero),'') is not null
 union all select cliente_id, null, normalizar_telefone(whatsapp) from cliente_whatsapps
 union all select cliente_id, coalesce(pessoa_fisica_id,id), normalizar_telefone(whatsapp) from cliente_pessoas where nullif(btrim(whatsapp),'') is not null)
select count(*) from (select t from tel group by t having count(distinct cliente_id)>1) x;
```

Não medido / não achado:
- "Uma pessoa = um usuário" (cliente com login): `usuarios_clientes` existe mas não tem ligação com pessoa nem empresa; não há o que medir.
- Terceiros (contador externo, procurador): não há estrutura; só 7 textos em `classificacao`.
- `cupula_permissao_empresa_extra.empresa_id` (24 linhas) não aponta para `clientes`; parece ser empresa do grupo (`empresas`) — não confirmado.

---

## 3. Regras que existiam no banco × o que faltava

| Regra de negócio | Existia no banco? | Observação |
|---|---|---|
| Um dono por empresa por setor | **Parcial**: UNIQUE `(cliente_id, setor_id)` em `cliente_setor_responsavel` | Mas o dono também mora em `clientes.responsavel_id`, sincronizado num sentido só e sem apagar → 29 empresas divergentes |
| Toda empresa ativa tem dono | **Não** | 124 sem dono |
| Empresa inativa perde dono / sai da carteira | **Não** | 80 inativas com dono |
| Dono pertence ao setor | **Não** no Fiscal (gatilho exclui o Fiscal de propósito); nos outros setores zera em silêncio | Hoje 0 casos, mas sem trava |
| Colaborador não troca dono | **Sim** (`trg_bloqueia_transf_colaborador`) | Só por nível, e só em `clientes` |
| Histórico de troca de dono | **Sim** (`registrar_transferencia_cliente`) | Mas `atribuido_por` é falso em 928 linhas; troca de setor de órfão não registra |
| Um CPF = uma pessoa | **Parcial**: UNIQUE em `cliente_pessoas_fisicas.cpf` (texto cru, parcial) | `cliente_pessoas` copia a pessoa por empresa, sem UNIQUE; CPF do QSA mora em texto em `clientes` |
| Pessoa não repete na mesma empresa | **Não** | 456 casos |
| Um telefone = um contato | **Não** em nenhuma das 6 fontes | Só há UNIQUE de conversa aberta por telefone |
| De que empresa/assunto o número pode falar | **Não** | Conversa tem 1 `cliente_id`; número em 2+ empresas em 34% das conversas do Fiscal |
| "Quem trata" único por empresa+assunto+pessoa | **Não** | 361 duplicatas exatas |
| Papel (QSA, quem trata, terceiro) em um lugar só | **Não** | Flag + etiqueta + tabela de assunto + texto em `clientes`, discordando |
| Toda referência a usuário com FK | **Não** | `atendente_atual`, `transferida_*`, `finalizada_por` etc. sem FK |
| Estado da conversa único | **Não** | 4 colunas de estado paralelas |
| Quem pode editar pessoa/vínculo depende da carteira | **Não** | RLS de `cliente_pessoas`/`cliente_assunto_vinculos`: qualquer interno |
| Visibilidade por setor sem nome fixo | **Não** | `col_ve_todos_clientes` compara nome do setor em texto |

### Lições para o banco novo (derivadas dos números)
1. Dono da carteira em **uma tabela só** (empresa × departamento × usuário), sem coluna espelho na empresa; trava "dono é membro do departamento" e "empresa inativa não fica na carteira" por gatilho em todos os setores.
2. Pessoa **uma vez só** (ponteiro), vínculo pessoa↔empresa em tabela própria com UNIQUE (pessoa, empresa, papel); nada de nome/CPF/WhatsApp em texto na empresa.
3. Telefone **uma vez só** (contato normalizado com E.164 completo, sem tirar o 9), ligado a pessoa/empresa por vínculo, e o **alcance** (de que empresa/assunto fala) explícito — nunca `LIMIT 1`.
4. Papel em um lugar só (catálogo), etiqueta não substitui papel.
5. UNIQUE em todo vínculo ativo; FK em toda coluna que guarda id de usuário; um único campo de estado da conversa.
6. Auditoria (`atribuido_por`) vem de `auth.uid()`, nunca do próprio dono.
