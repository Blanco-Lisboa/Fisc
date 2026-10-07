import json, sys
A = "Olá, aqui é {{1}}, do Departamento Societário da YOU Contabilidade.\n\n"
DOC = "DOC"
LINK = "[link] Preencher dados"
M = [
 ("societario_boas_vindas_cliente","Utilidade",None,
  A+"Estou dando andamento à sua solicitação referente a {{2}}, da empresa {{3}}.\n\nFico à disposição para qualquer dúvida.",
  ["Tenho uma dúvida","Tudo certo, obrigado"],["João","alteração do quadro societário","Loja Exemplo"],None),
 ("societario_link_formulario","Utilidade",None,
  A+"Para darmos andamento em {{2}}, pedimos que preencha os dados pelo botão abaixo. O link é válido por {{3}} minutos; caso expire, geramos outro.",
  [LINK],["João","abertura de empresa","60"],"Falta o endereço real do formulário (o antigo era localhost). Sem ele o botão de link não pode ser enviado à Meta."),
 ("societario_pedido_assinatura_govbr","Utilidade",None,
  A+"Para prosseguirmos com {{2}} da empresa {{3}}, é necessária a assinatura eletrônica pelo gov.br do responsável. Por gentileza, nos avise um horário em que ele possa nos acompanhar por alguns minutos.",
  ["Posso agora","Combinar horário"],["João","a assinatura do contrato social","Loja Exemplo"],
  "Reescrito: pedir que o cliente envie código recebido do gov.br é recusado pela Meta (mesmo motivo do 2FA da Legalização) e é arriscado. O código é combinado na conversa livre."),
 ("societario_entrega_contrato_social","Utilidade",DOC,
  A+"Segue em anexo o contrato social {{2}} da empresa {{3}}.\n\nQualquer dúvida, estamos à disposição.",
  ["Recebido, obrigado","Tenho dúvidas"],["João","registrado","Loja Exemplo"],None),
 ("societario_pedido_pagamento_guia_junta","Utilidade",DOC,
  A+"Para darmos andamento a {{2}} da empresa {{3}}, é necessário o pagamento da guia (DARE) em anexo, referente à Junta Comercial. Poderia nos enviar o comprovante assim que possível?",
  ["Vou pagar e enviar","Tenho dúvidas"],["João","baixa da filial","Loja Exemplo"],None),
 ("societario_pedido_codigo_viabilidade","Utilidade",None,
  A+"Assim que a consulta de viabilidade da empresa {{2}} for respondida pela prefeitura, por gentileza nos encaminhe o número do protocolo, para darmos continuidade ao processo.",
  ["Vou enviar agora","Ainda não tenho"],["João","Loja Exemplo"],None),
 ("societario_andamento_processo","Utilidade",None,
  A+"Informamos o andamento do processo de {{2}} da empresa {{3}}: a etapa atual é {{4}}.\n\nSeguimos acompanhando e avisaremos sobre os próximos passos.",
  ["Recebido, obrigado","Tenho dúvidas"],["João","alteração contratual","Loja Exemplo","atualização da inscrição municipal"],"Substitui societario_atualizacao_status_processo, que a Meta passou para Marketing."),
 ("societario_pesquisa_satisfacao","Marketing",None,
  "Obrigado pelo contato. Concluímos o atendimento da empresa {{1}}, realizado por {{2}}.\n\nSua opinião é importante para nós: em uma escala de 0 a 10, o quanto você recomendaria o atendimento do Departamento Societário da YOU Contabilidade?",
  ["0 a 6","7 a 8","9 a 10","Parar de receber"],["Loja Exemplo","João"],None),
 ("societario_comunicado_institucional","Marketing",None,
  "Prezado(a) cliente,\n\ninformamos: {{1}}.\n\nO Departamento Societário da YOU Contabilidade permanece à disposição para eventuais dúvidas.",
  ["Parar de receber"],["nosso atendimento Societário agora é feito por este número oficial"],None),
 ("societario_divulgacao_servicos_grupo","Marketing",None,
  "Prezado(a) cliente,\n\nalém dos serviços societários, a YOU Contabilidade também oferece suporte em {{1}} para empresas como a sua.\n\nGostaria de receber mais informações?",
  ["Quero saber mais","Parar de receber"],["apuração fiscal de e-commerce"],None),
]
H, F = "Departamento Societário", "Equipe Societário"
api = []
for nome, cat, doc, corpo, bot, ex, obs in M:
    assert not corpo.rstrip().endswith("}}"), nome
    assert len(corpo) <= 550, (nome, len(corpo))
    assert all(len(b.replace("[link] ","")) <= 25 for b in bot), nome
    if LINK in bot: continue
    comp = [{"type":"HEADER","format":"DOCUMENT","example":{"header_handle":["__H__"]}} if doc else {"type":"HEADER","format":"TEXT","text":H},
            {"type":"BODY","text":corpo,"example":{"body_text":[ex]}},
            {"type":"FOOTER","text":F},
            {"type":"BUTTONS","buttons":[{"type":"QUICK_REPLY","text":b} for b in bot]}]
    api.append({"name":nome,"language":"pt_BR","category":{"Utilidade":"UTILITY","Marketing":"MARKETING"}[cat],"components":comp})
api.append({"name":"societario_codigo_verificacao","language":"pt_BR","category":"AUTHENTICATION","components":[{"type":"BODY","add_security_recommendation":True},{"type":"FOOTER","code_expiration_minutes":10},{"type":"BUTTONS","buttons":[{"type":"OTP","otp_type":"COPY_CODE"}]}]})
json.dump(api, open(sys.argv[1],"w",encoding="utf-8"), ensure_ascii=False)
js = []
for i,(nome,cat,doc,corpo,bot,ex,obs) in enumerate(M,1):
    o = obs or ("Topo com o PDF anexado (a Meta não deixa título junto com anexo)." if doc else None)
    js.append({"n":i,"nome":nome,"cat":cat,"st":"NAO_ENVIADO","cab":None if doc else H,"doc":"Documento.pdf" if doc else None,"rod":F,"corpo":corpo,"ex":ex,
               "bt":[b.replace("[link] ","▸ ") for b in bot],"obs":o})
js.append({"n":11,"nome":"societario_codigo_verificacao","cat":"Autenticação","st":"NAO_ENVIADO","cab":None,"doc":None,"rod":"Expira em 10 minutos.","corpo":"Seu código de verificação é *{{1}}*. Para sua segurança, não o compartilhe.","ex":["123456"],"bt":["Copiar código"],"obs":"Texto padrão da Meta (não é editável)."})
json.dump(js, open(sys.argv[2],"w",encoding="utf-8"), ensure_ascii=False)
print("ok api", len(api), "pagina", len(js))
