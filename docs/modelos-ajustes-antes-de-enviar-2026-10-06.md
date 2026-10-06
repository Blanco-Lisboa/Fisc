# Modelos do Fiscal (artifact do William, 19 modelos) — ajustes antes de mandar à Meta (06/10/2026)

Fonte dos modelos: https://claude.ai/artifact/VKwWztmdLPFNzEtis3nnNY (15 utilidade, 1 autenticação, 3 marketing).

## Ajustes necessários (regras da Meta)
1. fiscal_entrega_apuracao_mensal: termina com a lacuna {{5}} ("Vencimento do DAS: {{5}}"). A Meta recusa modelo
   que começa ou termina com lacuna → acrescentar uma frase final fixa, ex.: "Qualquer dúvida, estamos à disposição."
2. fiscal_entrega_apuracao_mensal: a lacuna {{4}} (lista de documentos) NÃO pode ter quebra de linha na hora do envio
   (a Meta recusa valor com quebra de linha/tab). O sistema vai enviar a lista separada por vírgula
   ("DAS, Relatório de Apuração, DARE do ICMS DIFAL...").
3. fiscal_pendencia_cadastral: texto curto com 2 lacunas — risco de "muitas lacunas para pouco texto".
   Sugestão: acrescentar uma frase fixa (ex.: "Assim que possível, retorne para concluirmos a regularização.").
4. fiscal_reforma_tributaria_comunicado: o botão "Assistir vídeo" precisa do link real do vídeo.
5. fiscal_codigo_verificacao (autenticação): a Meta usa texto padrão dela; só escolhemos o tipo de botão
   (copiar código) e a validade. O texto do artifact serve só de referência.
6. Os 3 de marketing: a Meta exige opção de descadastro (botão "Parar de receber"). Só aprovar se forem usar.
7. Cada lacuna precisa de um exemplo (vou usar os exemplos fictícios do próprio artifact).

## Para enviar
Precisa da chave definitiva (Usuário do Sistema) com acesso à conta do WhatsApp DA YOU (não a de teste).
Com ela, envio os modelos pela API de uma vez; as aprovações/recusas chegam sozinhas no sistema (wa_modelo).
