# Teste da regra da Entrada (06/10/2026) — banco vvohwixeokxydmbhqklu, tudo em transação desfeita (rollback)

Regra (William): todos do Fiscal veem a Entrada; colaborador só envia/assume se o contato estiver vinculado
(por assistente/gerente/diretor/ceo) a um CNPJ da carteira dele; assistente pra cima responde tudo.

| Caso | Resultado |
|---|---|
| anon lista conversas | 0 |
| anon chama fiscal_pode_enviar_contato | permission denied |
| logado sem cadastro no Fiscal vê conversa | 0 |
| colaborador B (empresa fora da carteira) vê conversa | 1 (vê) |
| colaborador B pode enviar | false |
| colaborador B assumir | 0 linhas (recusado) |
| colaborador B preparar envio | "Contato nao vinculado a uma empresa da sua carteira." |
| colaborador B vincular contato | ERRO so assistente, gerente, diretor ou ceo vincula contato |
| colaborador A (empresa na carteira) pode enviar | true |
| colaborador A assumir | 1 linha |
| colaborador A preparar envio | passou a permissão; parou na janela de 24h (esperado) |
| assistente pode enviar | true |
| assistente vincular em nome de outro usuário | ERRO (recusado) |
| assistente vincular em nome próprio | gravou |
| servidor | true |

Atenção: fiscal_carteira está vazia (0 linhas) → hoje nenhum colaborador consegue enviar até a carteira ser preenchida.

## Achados da checagem de segurança, corrigidos e testados
| Caso | Resultado |
|---|---|
| anon chama fiscal_empresas_da_you (antes devolvia a lista de ids) | permission denied |
| colaborador desfaz vínculo | ERRO (recusado) |
| assistente desfaz em nome de outro | ERRO (recusado) |
| assistente desfaz em nome próprio | true |
| colaborador continua lendo fiscal_empresas_da_you | true |

## Nível vem da BL por aviso (não mais só no login)
- BL: gatilhos em usuarios_internos (nivel/ativo/nome/email) e usuario_setores avisam a função fiscal-usuario-mudou.
- Fiscal: fiscal-usuario-mudou relê a BL (fiscal_acesso_bl) e grava em fiscal_usuario; fiscal_nivel() lê dessa tabela.
  A função não precisa de senha: ela só manda reler a fonte (BL), não aceita nível de quem chama.
- Java: lê o nível de fiscal_usuario ao abrir e escuta mudanças (realtime) — menu muda na hora; desligado = sai.

| Caso | Resultado |
|---|---|
| BL muda teste 2 para colaborador | Fiscal gravou colaborador (aviso chegou) |
| BL volta teste 2 para assistente | Fiscal gravou assistente |
| chamada com id inválido | 400 |
| anon lê fiscal_usuario | 0 |
| anon / logado chama fiscal_usuario_sincronizar | permission denied |
| logado fora do Fiscal com JWT falso "gerente" | nível null, vê 0 usuários |
| colaborador com JWT antigo "gerente" | nível real = colaborador; vê só a própria linha |
| colaborador tenta se promover | 0 linhas |
| teste 2 (assistente) | nível assistente; vê os 12 |
