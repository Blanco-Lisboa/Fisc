# Modelos do Fiscal — o que mudou na edição de 08/10/2026

Cabeçalho ("Departamento Fiscal"), rodapé ("Equipe Fiscal") e botões NÃO mudaram em nenhum. Só o texto do meio.

## Grupo 1 — 12 modelos: só a linha em branco depois da apresentação (palavras iguais)

Antes: `Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Estamos realizando...`
Depois: `Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade.` + linha em branco + `Estamos realizando...`

Vale para: atualizacao_rotina_erp, aviso_alteracao_cadastral, aviso_declaracao_zerada, aviso_vencimento_certificado,
confirmacao_dados_apuracao, confirmacao_movimento_mes, difal_explicacao_decisao, lembrete_urgente_xml,
pendencia_cadastral, recibo_opcao_regime.

solicitacao_xml — também tirei a quebra antes da última frase:
- Antes: "...referentes a {{3}}?" [linha em branco] "Esses arquivos são necessários para darmos continuidade à apuração."
- Depois: "...referentes a {{3}}? Esses arquivos são necessários para darmos continuidade à apuração."

## Grupo 2 — mudou palavra

**entrega_apuracao_mensal**
- Antes: "Segue a apuração de {{2}} da empresa {{3}} (CNPJ {{4}}): {{5}}. [linha] Vencimento do DAS: {{6}}. Qualquer dúvida, estamos à disposição."
- Depois: "Segue a apuração de {{2}} da empresa {{3}} (CNPJ {{4}}), com os documentos: {{5}}. [linha] O vencimento do DAS é em {{6}}. Qualquer dúvida, estamos à disposição."

**reforma_tributaria_lembrete** ("retorno" repetido)
- Antes: "Lembramos que o prazo para definição do regime Simples Nacional (regular ou híbrido), referente à Reforma Tributária, encerra em {{2}}. Solicitamos seu retorno o quanto antes para a empresa {{3}}. Aguardamos seu retorno."
- Depois: "Lembramos que o prazo para definição do regime do Simples Nacional (regular ou híbrido), referente à Reforma Tributária, encerra em {{2}}. Precisamos da decisão da empresa {{3}} o quanto antes. Aguardamos seu retorno."

## Grupo 3 — os 3 de propaganda: tirei a apresentação pessoal (muda os campos)

**comunicado_institucional**
- Antes: "Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Informamos: {{2}}. Permanecemos à disposição para eventuais dúvidas."
- Depois: "A YOU Contabilidade informa: {{1}}. [linha] O Departamento Fiscal permanece à disposição para eventuais dúvidas."

**divulgacao_servicos_grupo**
- Antes: "Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Também oferecemos suporte em {{2}} para empresas como a sua. Gostaria de receber mais informações?"
- Depois: "O Departamento Fiscal da YOU Contabilidade também oferece suporte em {{1}} para empresas como a sua. [linha] Gostaria de receber mais informações?"

**pesquisa_satisfacao**
- Antes: "Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Concluímos o atendimento da empresa {{2}}. Em uma escala de 0 a 10, o quanto você recomendaria nosso atendimento fiscal?"
- Depois: "O atendimento da empresa {{1}}, realizado por {{2}}, do Departamento Fiscal da YOU Contabilidade, foi concluído. [linha] Em uma escala de 0 a 10, o quanto você recomendaria nosso atendimento?"

## Não mexi
boas_vindas_cliente, codigo_verificacao (continuam aprovados).
