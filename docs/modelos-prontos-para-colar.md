# Modelos do Fiscal — prontos para colar no WhatsApp Manager (versão 2, com o nome do colaborador)
Conta: **Dep Fiscal You Contabilidade** (1054069641023968). Idioma: **Português (BR)**. Tipo de variável: **Número**.
Regra nova (William, 06/10): o cliente vê o nome de quem está falando. Em todos os modelos a lacuna {{1}} é o NOME DO
COLABORADOR (o sistema preenche sozinho). Exemplo de {{1}} em todos: **Larissa**.
Como colar: copie o "Corpo" inteiro; digite as lacunas exatamente como {{1}}, {{2}}... Depois preencha os exemplos.

---
## 1. fiscal_boas_vindas_cliente — Utilidade > Padrão
Cabeçalho: Departamento Fiscal
Corpo:
Olá. Sou {{1}}, do Departamento Fiscal da YOU Contabilidade, responsável pelas obrigações fiscais da empresa {{2}} (CNPJ {{3}}).

Para darmos início às apurações, precisamos confirmar três informações: os canais de venda utilizados, o sistema emissor das notas fiscais e o certificado digital da empresa.

Fico no aguardo do seu retorno.
Rodapé: Equipe Fiscal
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo Confecções Ltda · {{3}} 12.345.678/0001-90

## 2. fiscal_confirmacao_dados_apuracao — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Daremos início à apuração de {{2}} referente à empresa {{3}}. Poderia confirmar se houve alguma alteração ou inclusão no ERP, no faturador (emissor de nota) ou em outro dado relevante neste período?
Botões (Resposta rápida): Sem alterações | Tive alteração
Exemplos: {{1}} Larissa · {{2}} setembro/2026 · {{3}} Loja Exemplo

## 3. fiscal_confirmacao_movimento_mes — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Gostaríamos de confirmar: houve emissão de notas fiscais pela empresa {{2}} no mês de {{3}}?
Botões: Sim, tive notas | Não tive notas
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo · {{3}} setembro/2026

## 4. fiscal_solicitacao_xml — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Poderia nos encaminhar os arquivos XML da empresa {{2}} referentes a {{3}}?

Esses arquivos são necessários para darmos continuidade à apuração.
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo · {{3}} setembro/2026

## 5. fiscal_lembrete_urgente_xml — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Reforçamos a solicitação dos arquivos XML da empresa {{2}}, referentes a {{3}}. O não envio dentro do prazo pode resultar em multa para a empresa. Pedimos a gentileza de encaminhá-los ainda hoje.
Botões: Enviarei agora | Preciso de mais prazo
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo · {{3}} setembro/2026

## 6. fiscal_aviso_declaracao_zerada — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Informamos que, por não termos recebido os arquivos XML dentro do prazo, a competência de {{2}} da empresa {{3}} foi declarada como zerada perante a Receita Federal. Caso o XML seja enviado posteriormente, o imposto devido será apurado com juros e multa.
Exemplos: {{1}} Larissa · {{2}} junho/2026 · {{3}} Loja Exemplo

## 7. fiscal_entrega_apuracao_mensal — Utilidade > Padrão  (o mais usado)
Amostra de mídia / Cabeçalho: Documento — envie um PDF qualquer de exemplo
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Segue a apuração de {{2}} da empresa {{3}} (CNPJ {{4}}): {{5}}.

Vencimento do DAS: {{6}}. Qualquer dúvida, estamos à disposição.
Exemplos: {{1}} Larissa · {{2}} agosto/2026 · {{3}} Loja Exemplo Confecções Ltda · {{4}} 12.345.678/0001-90 · {{5}} DAS, Relatório de Apuração, DARE do ICMS DIFAL, Relatório de Entradas, Relatório de Saídas · {{6}} 21/09/2026

## 8. fiscal_difal_explicacao_decisao — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Na apuração da empresa {{2}}, identificamos um valor a pagar de ICMS DIFAL (diferencial de alíquota entre estados), no montante de {{3}}.

Recomendamos o pagamento para evitar eventuais problemas futuros, mas a decisão final cabe à empresa. Deseja que realizemos a declaração desse valor?
Botões: Sim, declarar | Não, por enquanto
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo · {{3}} R$ 18,32

## 9. fiscal_recibo_opcao_regime — Utilidade > Padrão
Amostra de mídia / Cabeçalho: Documento (PDF de exemplo)
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Conforme solicitado, realizamos a opção pelo regime híbrido do Simples Nacional para a empresa {{2}}. A partir de novembro, essa decisão poderá ser reavaliada, já com as alíquotas oficiais divulgadas. Segue o recibo para seu controle.
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo

## 10. fiscal_reforma_tributaria_comunicado — Utilidade > Padrão
Cabeçalho: Simples Nacional Híbrido
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Chegou o momento de uma decisão importante relacionada à Reforma Tributária (IBS/CBS) para a empresa {{2}}. É possível optar pelo regime híbrido do Simples Nacional, com possibilidade de cancelamento até {{3}}, já com a alíquota oficial conhecida.

Preparamos um vídeo explicativo sobre o assunto. Após assisti-lo, solicitamos seu retorno com a decisão.
Botões: "Visitar o site" com texto "Assistir vídeo" e o LINK DO VÍDEO | Resposta rápida: Quero o híbrido | Prefiro o regular
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo · {{3}} 30/11/2026

## 11. fiscal_reforma_tributaria_lembrete — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Lembramos que o prazo para definição do regime Simples Nacional (regular ou híbrido), referente à Reforma Tributária, encerra em {{2}}. Solicitamos seu retorno o quanto antes para a empresa {{3}}.
Botões: Quero o híbrido | Prefiro o regular
Exemplos: {{1}} Larissa · {{2}} 30/09/2026 · {{3}} Loja Exemplo

## 12. fiscal_aviso_alteracao_cadastral — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Reforçamos a importância de nos comunicar sempre que houver alguma alteração na empresa {{2}}, como novas plataformas de venda, troca de ERP ou novo tipo de emissão de nota fiscal.
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo

## 13. fiscal_atualizacao_rotina_erp — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Estamos realizando uma atualização cadastral de rotina. Poderia confirmar se a empresa {{2}} continua emitindo notas pelo sistema {{3}}? Caso tenha havido alguma mudança, pedimos a gentileza de nos informar.
Botões: Continua o mesmo | Mudou
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo · {{3}} Bling

## 14. fiscal_lembrete_certificado_digital — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. O certificado digital da empresa {{2}} está próximo do vencimento (ou pode já ter vencido). Trata-se de documento obrigatório para darmos continuidade à apuração. A renovação já foi providenciada?
Botões: Já renovei | Preciso de ajuda
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo

## 15. fiscal_pendencia_cadastral — Utilidade > Padrão
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Identificamos uma pendência cadastral na empresa {{2}}: {{3}}. Poderia nos auxiliar na resolução? Assim que possível, retorne para concluirmos a regularização.
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo · {{3}} inscrição estadual pendente de atualização

## 16. fiscal_codigo_verificacao — Autenticação > Código de acesso de uso único
Texto padrão da Meta (sem nome do colaborador — é regra da Meta para código). Marque o aviso de segurança,
botão "Copiar código", validade de 10 minutos.

## 17. fiscal_pesquisa_satisfacao — Marketing > Padrão (só se for usar)
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Concluímos o atendimento da empresa {{2}}. Em uma escala de 0 a 10, o quanto você recomendaria nosso atendimento fiscal?
Botões: 0 a 6 | 7 a 8 | 9 a 10 | Parar de receber (botão de descadastro)
Exemplos: {{1}} Larissa · {{2}} Loja Exemplo

## 18. fiscal_comunicado_institucional — Marketing > Padrão (só se for usar)
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Informamos: {{2}}. Permanecemos à disposição para eventuais dúvidas.
Botões: Parar de receber (descadastro)
Exemplos: {{1}} Larissa · {{2}} nosso atendimento fiscal agora é feito por este número oficial

## 19. fiscal_divulgacao_servicos_grupo — Marketing > Padrão (só se for usar)
Corpo:
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Também oferecemos suporte em {{2}} para empresas como a sua. Gostaria de receber mais informações?
Botões: Quero saber mais | Parar de receber (descadastro)
Exemplos: {{1}} Larissa · {{2}} abertura e alteração de empresas
