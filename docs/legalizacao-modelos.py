import json, sys
A = "Olá, aqui é {{1}}, do Departamento de Legalização da YOU Contabilidade.\n\n"
DOC = "DOC"
M = [
 ("legal_boas_vindas_cliente","Utilidade",None,
  A+"Estou à disposição para auxiliar em dúvidas ou necessidades referentes a este departamento, relacionadas à empresa {{2}}.\n\nFico no aguardo do seu retorno.",
  ["Tenho uma dúvida","Tudo certo, obrigado"],["Bruna","Loja Exemplo Confecções Ltda"]),
 ("legal_entrega_parcela_acordo","Utilidade",DOC,
  A+"Segue em anexo a parcela referente ao parcelamento de {{2}} da empresa {{3}} (CNPJ {{4}}).\n\nValor: {{5}}\nParcela: {{6}}\nVencimento: {{7}}\n\nQualquer dúvida, estamos à disposição.",
  ["Recebido, obrigado","Tenho dúvidas"],["Bruna","Simples Nacional - Dívida Ativa","Loja Exemplo Confecções Ltda","12.345.678/0001-90","R$ 58,63","15/57","30/06/2026"]),
 ("legal_entrega_tfe_anual","Utilidade",DOC,
  A+"Segue em anexo a Taxa de Fiscalização do Estabelecimento (TFE) da empresa {{2}}, obrigação anual estipulada pela prefeitura, com vencimento em {{3}}. Pedimos atenção ao prazo, para evitar riscos como a exclusão do Simples Nacional.",
  ["Recebido, obrigado","Tenho dúvidas"],["Bruna","Loja Exemplo","10/03/2027"]),
 ("legal_aviso_prazo_simples_nacional","Utilidade",None,
  A+"O prazo para solicitar o enquadramento da empresa {{2}} no Simples Nacional está se encerrando. Caso haja pendências ou débitos, é necessário regularizá-los até {{3}} para viabilizar a opção. Podemos auxiliar com a consulta e o parcelamento necessário.",
  ["Quero regularizar","Não se aplica"],["Bruna","Loja Exemplo","28/01/2027"]),
 ("legal_pedido_procuracao","Utilidade",None,
  A+"Para darmos continuidade ao processo da empresa {{2}}, precisamos que seja feita a procuração {{3}}. Pedimos que seja providenciada o quanto antes, para evitar atrasos ou eventuais multas.",
  ["Vou providenciar","Preciso de ajuda"],["Bruna","Loja Exemplo","no portal e-CAC"]),
 ("legal_pedido_desabilitar_verificacao_2fa","Utilidade",None,
  A+"Para prosseguirmos com a procuração da empresa {{2}}, pedimos a gentileza de desabilitar temporariamente a verificação em duas etapas do acesso gov.br do responsável, para que possamos concluir o procedimento.",
  ["Já desabilitei","Preciso de ajuda"],["Bruna","Loja Exemplo"]),
 ("legal_aviso_pendencia_financeira","Utilidade",None,
  A+"Identificamos, junto ao {{2}}, uma pendência financeira em nome da empresa {{3}}, no valor de {{4}}, referente a {{5}}. Podemos auxiliar na regularização.",
  ["Quero regularizar","Tenho dúvidas"],["Bruna","SERASA","Loja Exemplo","R$ 242,32","conta de telefonia"]),
 ("legal_confirmacao_protocolo_concluido","Utilidade",None,
  A+"Informamos que o protocolo da empresa {{2}} referente a {{3}} já consta como concluído. Permanecemos à disposição.",
  ["Recebido, obrigado","Tenho dúvidas"],["Bruna","Loja Exemplo","alteração de endereço"]),
 ("legal_pesquisa_satisfacao","Marketing",None,
  "Obrigado pelo contato. Concluímos o atendimento da empresa {{1}}, realizado por {{2}}.\n\nSua opinião é importante para nós: em uma escala de 0 a 10, o quanto você recomendaria o atendimento do Departamento de Legalização da YOU Contabilidade?",
  ["0 a 6","7 a 8","9 a 10","Parar de receber"],["Loja Exemplo","Bruna"]),
 ("legal_comunicado_institucional","Marketing",None,
  "Prezado(a) cliente,\n\ninformamos: {{1}}.\n\nO Departamento de Legalização da YOU Contabilidade permanece à disposição para eventuais dúvidas.",
  ["Parar de receber"],["nosso atendimento de Legalização agora é feito por este número oficial"]),
 ("legal_divulgacao_servicos_grupo","Marketing",None,
  "Prezado(a) cliente,\n\nalém dos serviços de Legalização, a YOU Contabilidade também oferece suporte em {{1}} para empresas como a sua.\n\nGostaria de receber mais informações?",
  ["Quero saber mais","Parar de receber"],["abertura e alteração de empresas"]),
]
H, F = "Departamento de Legalização", "Equipe de Legalização"
api = []
for nome, cat, doc, corpo, bot, ex in M:
    assert not corpo.rstrip().endswith("}}"), nome
    assert len(corpo) <= 550, (nome, len(corpo))
    assert all(len(b) <= 25 for b in bot), nome
    comp = [{"type":"HEADER","format":"DOCUMENT","example":{"header_handle":["__H__"]}} if doc else {"type":"HEADER","format":"TEXT","text":H},
            {"type":"BODY","text":corpo,"example":{"body_text":[ex]}},
            {"type":"FOOTER","text":F},
            {"type":"BUTTONS","buttons":[{"type":"QUICK_REPLY","text":b} for b in bot]}]
    api.append({"name":nome,"language":"pt_BR","category":{"Utilidade":"UTILITY","Marketing":"MARKETING"}[cat],"components":comp})
api.append({"name":"legal_codigo_verificacao","language":"pt_BR","category":"AUTHENTICATION","components":[{"type":"BODY","add_security_recommendation":True},{"type":"FOOTER","code_expiration_minutes":10},{"type":"BUTTONS","buttons":[{"type":"OTP","otp_type":"COPY_CODE"}]}]})
json.dump(api, open(sys.argv[1],"w",encoding="utf-8"), ensure_ascii=False)
js = []
for i,(nome,cat,doc,corpo,bot,ex) in enumerate(M,1):
    js.append({"n":i,"nome":nome,"cat":cat,"st":"NAO_ENVIADO","cab":None if doc else H,"doc":"Guia.pdf" if doc else None,"rod":F,"corpo":corpo,"ex":ex,"bt":bot,
               "obs":"Topo com o PDF anexado (a Meta não deixa título junto com anexo)." if doc else None})
js.append({"n":12,"nome":"legal_codigo_verificacao","cat":"Autenticação","st":"NAO_ENVIADO","cab":None,"doc":None,"rod":"Expira em 10 minutos.","corpo":"Seu código de verificação é *{{1}}*. Para sua segurança, não o compartilhe.","ex":["123456"],"bt":["Copiar código"],"obs":"Texto padrão da Meta (não é editável)."})
json.dump(js, open(sys.argv[2],"w",encoding="utf-8"), ensure_ascii=False)
print("ok", len(api))
