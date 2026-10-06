# 19 modelos do Fiscal — prontos para colar no WhatsApp Manager
Conta: **Dep Fiscal You Contabilidade** (1054069641023968). Idioma de todos: **Português (BR)**.
Lacunas: digite {{1}}, {{2}}... exatamente assim. Em cada lacuna a Meta pede um EXEMPLO — use o da linha "Exemplos".
Ajustes já aplicados: nenhum termina com lacuna; sem emoji; textos de marketing com "Parar de receber".

---
## 1. fiscal_boas_vindas_cliente — Utilidade
Cabeçalho (texto): Departamento Fiscal
Corpo:
Olá. Sou {{1}}, do Departamento Fiscal, responsável pelas obrigações fiscais da empresa {{2}} (CNPJ {{3}}).

Para darmos início às apurações, precisamos confirmar três informações: os canais de venda utilizados, o sistema emissor das notas fiscais e o certificado digital da empresa.

Fico no aguardo do seu retorno.
Rodapé: Equipe Fiscal
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo Confecções Ltda · {{3}} 12.345.678/0001-90

## 2. fiscal_confirmacao_dados_apuracao — Utilidade
Corpo:
Olá. Daremos início à apuração de {{1}} referente à empresa {{2}}. Poderia confirmar se houve alguma alteração ou inclusão no ERP, no faturador (emissor de nota) ou em outro dado relevante neste período?
Botões (resposta rápida): Sem alterações | Tive alteração
Exemplos: {{1}} setembro/2026 · {{2}} Loja Exemplo

## 3. fiscal_confirmacao_movimento_mes — Utilidade
Corpo:
Olá. Gostaríamos de confirmar: houve emissão de notas fiscais pela empresa {{1}} no mês de {{2}}?
Botões: Sim, tive notas | Não tive notas
Exemplos: {{1}} Loja Exemplo · {{2}} setembro/2026

## 4. fiscal_solicitacao_xml — Utilidade
Corpo:
Olá. Poderia nos encaminhar os arquivos XML da empresa {{1}} referentes a {{2}}?

Esses arquivos são necessários para darmos continuidade à apuração.
Exemplos: {{1}} Loja Exemplo · {{2}} setembro/2026

## 5. fiscal_lembrete_urgente_xml — Utilidade
Corpo:
Olá. Reforçamos a solicitação dos arquivos XML da empresa {{1}}, referentes a {{2}}. O não envio dentro do prazo pode resultar em multa para a empresa. Pedimos a gentileza de encaminhá-los ainda hoje.
Botões: Enviarei agora | Preciso de mais prazo
Exemplos: {{1}} Loja Exemplo · {{2}} setembro/2026

## 6. fiscal_aviso_declaracao_zerada — Utilidade
Corpo:
Prezado(a) cliente, informamos que, por não termos recebido os arquivos XML dentro do prazo, a competência de {{2}} da empresa {{1}} foi declarada como zerada perante a Receita Federal. Caso o XML seja enviado posteriormente, o imposto devido será apurado com juros e multa.
Exemplos: {{1}} Loja Exemplo · {{2}} junho/2026
(Atenção: a Meta exige as lacunas em ordem no texto. Se reclamar, troque para "...a competência de {{1}} da empresa {{2}}..." e os exemplos {{1}} junho/2026 · {{2}} Loja Exemplo.)

## 7. fiscal_entrega_apuracao_mensal — Utilidade  (o mais usado)
Cabeçalho: Documento (PDF) — envie um PDF de exemplo
Corpo:
Olá. Segue a apuração de {{1}} da empresa {{2}} (CNPJ {{3}}): {{4}}.

Vencimento do DAS: {{5}}. Qualquer dúvida, estamos à disposição.
Exemplos: {{1}} agosto/2026 · {{2}} Loja Exemplo Confecções Ltda · {{3}} 12.345.678/0001-90 · {{4}} DAS, Relatório de Apuração, DARE do ICMS DIFAL, Relatório de Entradas, Relatório de Saídas · {{5}} 21/09/2026

## 8. fiscal_difal_explicacao_decisao — Utilidade
Corpo:
Olá. Na apuração da empresa {{1}}, identificamos um valor a pagar de ICMS DIFAL (diferencial de alíquota entre estados), no montante de {{2}}.

Recomendamos o pagamento para evitar eventuais problemas futuros, mas a decisão final cabe à empresa. Deseja que realizemos a declaração desse valor?
Botões: Sim, declarar | Não, por enquanto
Exemplos: {{1}} Loja Exemplo · {{2}} R$ 18,32

## 9. fiscal_recibo_opcao_regime — Utilidade
Cabeçalho: Documento (PDF)
Corpo:
Olá. Conforme solicitado, realizamos a opção pelo regime híbrido do Simples Nacional para a empresa {{1}}. A partir de novembro, essa decisão poderá ser reavaliada, já com as alíquotas oficiais divulgadas. Segue o recibo para seu controle.
Exemplos: {{1}} Loja Exemplo

## 10. fiscal_reforma_tributaria_comunicado — Utilidade
Cabeçalho (texto): Simples Nacional Híbrido
Corpo:
Olá. Chegou o momento de uma decisão importante relacionada à Reforma Tributária (IBS/CBS) para a empresa {{1}}. É possível optar pelo regime híbrido do Simples Nacional, com possibilidade de cancelamento até {{2}}, já com a alíquota oficial conhecida.

Preparamos um vídeo explicativo sobre o assunto. Após assisti-lo, solicitamos seu retorno com a decisão.
Botões: Visitar site "Assistir vídeo" (LINK DO VÍDEO — precisa do endereço real) | Quero o híbrido | Prefiro o regular
Exemplos: {{1}} Loja Exemplo · {{2}} 30/11/2026

## 11. fiscal_reforma_tributaria_lembrete — Utilidade
Corpo:
Olá. Lembramos que o prazo para definição do regime Simples Nacional (regular ou híbrido), referente à Reforma Tributária, encerra em {{1}}. Solicitamos seu retorno o quanto antes para a empresa {{2}}.
Botões: Quero o híbrido | Prefiro o regular
Exemplos: {{1}} 30/09/2026 · {{2}} Loja Exemplo

## 12. fiscal_aviso_alteracao_cadastral — Utilidade
Corpo:
Olá. Reforçamos a importância de nos comunicar sempre que houver alguma alteração na empresa {{1}}, como novas plataformas de venda, troca de ERP ou novo tipo de emissão de nota fiscal.
Exemplos: {{1}} Loja Exemplo

## 13. fiscal_atualizacao_rotina_erp — Utilidade
Corpo:
Olá. Estamos realizando uma atualização cadastral de rotina. Poderia confirmar se a empresa {{1}} continua emitindo notas pelo sistema {{2}}? Caso tenha havido alguma mudança, pedimos a gentileza de nos informar.
Botões: Continua o mesmo | Mudou
Exemplos: {{1}} Loja Exemplo · {{2}} Bling

## 14. fiscal_lembrete_certificado_digital — Utilidade
Corpo:
Olá. O certificado digital da empresa {{1}} está próximo do vencimento (ou pode já ter vencido). Trata-se de documento obrigatório para darmos continuidade à apuração. A renovação já foi providenciada?
Botões: Já renovei | Preciso de ajuda
Exemplos: {{1}} Loja Exemplo

## 15. fiscal_pendencia_cadastral — Utilidade
Corpo:
Olá. Identificamos uma pendência cadastral na empresa {{1}}: {{2}}. Poderia nos auxiliar na resolução? Assim que possível, retorne para concluirmos a regularização.
Exemplos: {{1}} Loja Exemplo · {{2}} inscrição estadual pendente de atualização

## 16. fiscal_codigo_verificacao — Autenticação
Na Meta, escolha a categoria Autenticação: o texto é padrão dela. Marque "Adicionar aviso de segurança",
escolha o botão "Copiar código" e validade de 10 minutos.

## 17. fiscal_pesquisa_satisfacao — Marketing (só se for usar)
Corpo:
Olá. Concluímos o atendimento da empresa {{1}}. Em uma escala de 0 a 10, o quanto você recomendaria nosso atendimento fiscal?
Botões: 0 a 6 | 7 a 8 | 9 a 10 | Parar de receber
Exemplos: {{1}} Loja Exemplo

## 18. fiscal_comunicado_institucional — Marketing (só se for usar)
Corpo:
Prezado(a) cliente, informamos: {{1}}. Permanecemos à disposição para eventuais dúvidas.
Botões: Parar de receber
Exemplos: {{1}} nosso atendimento fiscal agora é feito por este número oficial

## 19. fiscal_divulgacao_servicos_grupo — Marketing (só se for usar)
Corpo:
Olá. Também oferecemos suporte em {{1}} para empresas como a sua. Gostaria de receber mais informações?
Botões: Quero saber mais | Parar de receber
Exemplos: {{1}} abertura e alteração de empresas
