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
