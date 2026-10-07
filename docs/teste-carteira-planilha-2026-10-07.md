# Carteira por planilha — testes (07/10/2026)

## Segurança (banco vvohwixeokxydmbhqklu, tudo desfeito no fim do teste)
- Sem login (anon): conferir e gravar → "permission denied".
- Logado sem cadastro no Fiscal: "so gestor do Fiscal".
- Colaborador: conferir e gravar → "so gestor do Fiscal"; inserir direto na tabela → barrado pela regra de linha (RLS).
- Gestor com empresa falsa no meio do lote: lote inteiro recusado ("sem vinculo ativo com a YOU ou inativo: 1").
- Gestor tentando pôr na carteira de outro um CNPJ que já tem dono, sem confirmar: recusado.
- Com confirmação de transferência: 1 transferido, empresa ficou com 1 dono ativo só.
- Servidor: continua funcionando.

## Leitura da planilha (Chrome sem janela, dados de exemplo)
Planilha: cabeçalho "CNPJ", número 12345678000190, texto formatado, "abc123", linha vazia, repetido, número com 13 dígitos, CNPJ inexistente.
- Cabeçalho pulado; número veio inteiro; linha vazia ignorada; números de linha batem com a planilha.
- Gravação mandou só: prontos + transferido marcado + o corrigido na hora. Repetido e descartado ficaram fora.

## Diferenças para o legado (ERP YOU)
- Legado gravava cliente por cliente sem transação (falha no meio = metade gravada). Agora é tudo ou nada.
- Legado não filtrava empresa inativa. Agora é conferido na conferência e de novo na gravação.
- Legado perdia zeros à esquerda e não aceitava CSV. Agora completa zeros e aceita CSV/TXT.
- Legado sumia com repetidos sem avisar. Agora aparecem marcados.
