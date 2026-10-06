# Modelos do Fiscal — campo por campo, na ordem da tela da Meta (versão 3)

Conta: Dep Fiscal You Contabilidade. Em todos: Idioma = Português (BR); Tipo de variável = Número; Período de validade = não mexer.
{{1}} é sempre o nome do colaborador (o sistema preenche sozinho).
Lacunas: digite {{1}}, {{2}}... no texto. Depois de colar o corpo aparecem as caixas de 'Amostra': preencha com os exemplos indicados.

---
## Modelo 1 — fiscal_boas_vindas_cliente

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_boas_vindas_cliente
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: Departamento Fiscal
- Corpo (copie tudo entre as linhas):
```
Olá. Sou {{1}}, do Departamento Fiscal da YOU Contabilidade, responsável pelas obrigações fiscais da empresa {{2}} (CNPJ {{3}}).

Para darmos início às apurações, precisamos confirmar três informações: os canais de venda utilizados, o sistema emissor das notas fiscais e o certificado digital da empresa.

Fico no aguardo do seu retorno.
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo Confecções Ltda · {{3}} = 12.345.678/0001-90
- Rodapé: Equipe Fiscal
- Botões: (nenhum)
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 2 — fiscal_confirmacao_dados_apuracao

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_confirmacao_dados_apuracao
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Daremos início à apuração de {{2}} referente à empresa {{3}}. Poderia confirmar se houve alguma alteração ou inclusão no ERP, no faturador (emissor de nota) ou em outro dado relevante neste período?
```
- Amostras: {{1}} = Larissa · {{2}} = setembro/2026 · {{3}} = Loja Exemplo
- Rodapé: (deixar vazio)
- Botões: Resposta rápida: Sem alterações | Resposta rápida: Tive alteração
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 3 — fiscal_confirmacao_movimento_mes

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_confirmacao_movimento_mes
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Gostaríamos de confirmar: houve emissão de notas fiscais pela empresa {{2}} no mês de {{3}}?
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo · {{3}} = setembro/2026
- Rodapé: (deixar vazio)
- Botões: Resposta rápida: Sim, tive notas | Resposta rápida: Não tive notas
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 4 — fiscal_solicitacao_xml

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_solicitacao_xml
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Poderia nos encaminhar os arquivos XML da empresa {{2}} referentes a {{3}}?

Esses arquivos são necessários para darmos continuidade à apuração.
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo · {{3}} = setembro/2026
- Rodapé: (deixar vazio)
- Botões: (nenhum)
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 5 — fiscal_lembrete_urgente_xml

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_lembrete_urgente_xml
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Reforçamos a solicitação dos arquivos XML da empresa {{2}}, referentes a {{3}}. O não envio dentro do prazo pode resultar em multa para a empresa. Pedimos a gentileza de encaminhá-los ainda hoje.
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo · {{3}} = setembro/2026
- Rodapé: (deixar vazio)
- Botões: Resposta rápida: Enviarei agora | Resposta rápida: Preciso de mais prazo
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 6 — fiscal_aviso_declaracao_zerada

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_aviso_declaracao_zerada
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Informamos que, por não termos recebido os arquivos XML dentro do prazo, a competência de {{2}} da empresa {{3}} foi declarada como zerada perante a Receita Federal. Caso o XML seja enviado posteriormente, o imposto devido será apurado com juros e multa.
```
- Amostras: {{1}} = Larissa · {{2}} = junho/2026 · {{3}} = Loja Exemplo
- Rodapé: (deixar vazio)
- Botões: (nenhum)
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 7 — fiscal_entrega_apuracao_mensal

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_entrega_apuracao_mensal
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Documento (anexe um PDF qualquer de exemplo)
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Segue a apuração de {{2}} da empresa {{3}} (CNPJ {{4}}): {{5}}.

Vencimento do DAS: {{6}}. Qualquer dúvida, estamos à disposição.
```
- Amostras: {{1}} = Larissa · {{2}} = agosto/2026 · {{3}} = Loja Exemplo Confecções Ltda · {{4}} = 12.345.678/0001-90 · {{5}} = DAS, Relatório de Apuração, DARE do ICMS DIFAL, Relatório de Entradas, Relatório de Saídas · {{6}} = 21/09/2026
- Rodapé: (deixar vazio)
- Botões: (nenhum)
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 8 — fiscal_difal_explicacao_decisao

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_difal_explicacao_decisao
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Na apuração da empresa {{2}}, identificamos um valor a pagar de ICMS DIFAL (diferencial de alíquota entre estados), no montante de {{3}}.

Recomendamos o pagamento para evitar eventuais problemas futuros, mas a decisão final cabe à empresa. Deseja que realizemos a declaração desse valor?
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo · {{3}} = R$ 18,32
- Rodapé: (deixar vazio)
- Botões: Resposta rápida: Sim, declarar | Resposta rápida: Não, por enquanto
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 9 — fiscal_recibo_opcao_regime

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_recibo_opcao_regime
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Documento (anexe um PDF qualquer de exemplo)
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Conforme solicitado, realizamos a opção pelo regime híbrido do Simples Nacional para a empresa {{2}}. A partir de novembro, essa decisão poderá ser reavaliada, já com as alíquotas oficiais divulgadas. Segue o recibo para seu controle.
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo
- Rodapé: (deixar vazio)
- Botões: (nenhum)
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 10 — fiscal_reforma_tributaria_comunicado

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_reforma_tributaria_comunicado
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: Simples Nacional Híbrido
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Chegou o momento de uma decisão importante relacionada à Reforma Tributária (IBS/CBS) para a empresa {{2}}. É possível optar pelo regime híbrido do Simples Nacional, com possibilidade de cancelamento até {{3}}, já com a alíquota oficial conhecida.

Preparamos um vídeo explicativo sobre o assunto. Após assisti-lo, solicitamos seu retorno com a decisão.
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo · {{3}} = 30/11/2026
- Rodapé: (deixar vazio)
- Botões: [Visitar o site] 'Assistir vídeo' com o LINK DO VÍDEO | Resposta rápida: Quero o híbrido | Resposta rápida: Prefiro o regular
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 11 — fiscal_reforma_tributaria_lembrete

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_reforma_tributaria_lembrete
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Lembramos que o prazo para definição do regime Simples Nacional (regular ou híbrido), referente à Reforma Tributária, encerra em {{2}}. Solicitamos seu retorno o quanto antes para a empresa {{3}}.
```
- Amostras: {{1}} = Larissa · {{2}} = 30/09/2026 · {{3}} = Loja Exemplo
- Rodapé: (deixar vazio)
- Botões: Resposta rápida: Quero o híbrido | Resposta rápida: Prefiro o regular
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 12 — fiscal_aviso_alteracao_cadastral

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_aviso_alteracao_cadastral
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Reforçamos a importância de nos comunicar sempre que houver alguma alteração na empresa {{2}}, como novas plataformas de venda, troca de ERP ou novo tipo de emissão de nota fiscal.
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo
- Rodapé: (deixar vazio)
- Botões: (nenhum)
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 13 — fiscal_atualizacao_rotina_erp

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_atualizacao_rotina_erp
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Estamos realizando uma atualização cadastral de rotina. Poderia confirmar se a empresa {{2}} continua emitindo notas pelo sistema {{3}}? Caso tenha havido alguma mudança, pedimos a gentileza de nos informar.
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo · {{3}} = Bling
- Rodapé: (deixar vazio)
- Botões: Resposta rápida: Continua o mesmo | Resposta rápida: Mudou
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 14 — fiscal_lembrete_certificado_digital

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_lembrete_certificado_digital
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. O certificado digital da empresa {{2}} está próximo do vencimento (ou pode já ter vencido). Trata-se de documento obrigatório para darmos continuidade à apuração. A renovação já foi providenciada?
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo
- Rodapé: (deixar vazio)
- Botões: Resposta rápida: Já renovei | Resposta rápida: Preciso de ajuda
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 15 — fiscal_pendencia_cadastral

TELA 1 (Configurar modelo)
- Categoria: Utilidade
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_pendencia_cadastral
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Identificamos uma pendência cadastral na empresa {{2}}: {{3}}. Poderia nos auxiliar na resolução? Assim que possível, retorne para concluirmos a regularização.
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo · {{3}} = inscrição estadual pendente de atualização
- Rodapé: (deixar vazio)
- Botões: (nenhum)
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 16 — fiscal_pesquisa_satisfacao

TELA 1 (Configurar modelo)
- Categoria: Marketing
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_pesquisa_satisfacao
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Concluímos o atendimento da empresa {{2}}. Em uma escala de 0 a 10, o quanto você recomendaria nosso atendimento fiscal?
```
- Amostras: {{1}} = Larissa · {{2}} = Loja Exemplo
- Rodapé: (deixar vazio)
- Botões: Resposta rápida: 0 a 6 | Resposta rápida: 7 a 8 | Resposta rápida: 9 a 10 | [Descadastro de marketing] Parar de receber
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 17 — fiscal_comunicado_institucional

TELA 1 (Configurar modelo)
- Categoria: Marketing
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_comunicado_institucional
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Informamos: {{2}}. Permanecemos à disposição para eventuais dúvidas.
```
- Amostras: {{1}} = Larissa · {{2}} = nosso atendimento fiscal agora é feito por este número oficial
- Rodapé: (deixar vazio)
- Botões: [Descadastro de marketing] Parar de receber
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 18 — fiscal_divulgacao_servicos_grupo

TELA 1 (Configurar modelo)
- Categoria: Marketing
- Tipo: Padrão
- Avançar

TELA 2 (Editar modelo)
- Nome do modelo: fiscal_divulgacao_servicos_grupo
- Idioma: Português (BR)
- Tipo de variável: Número
- Amostra de mídia: Nenhum
- Cabeçalho: (deixar vazio)
- Corpo (copie tudo entre as linhas):
```
Olá, aqui é {{1}}, do Departamento Fiscal da YOU Contabilidade. Também oferecemos suporte em {{2}} para empresas como a sua. Gostaria de receber mais informações?
```
- Amostras: {{1}} = Larissa · {{2}} = abertura e alteração de empresas
- Rodapé: (deixar vazio)
- Botões: Resposta rápida: Quero saber mais | [Descadastro de marketing] Parar de receber
- Período de validade: não mexer
- Enviar para análise

---
## Modelo 20 — fiscal_codigo_verificacao (Autenticação)
TELA 1: Categoria Autenticação > Código de acesso de uso único > Avançar.
TELA 2: nome fiscal_codigo_verificacao; idioma Português (BR); marcar 'Adicionar aviso de segurança'; botão 'Copiar código'; validade 10 minutos; Enviar para análise. (O texto é padrão da Meta.)