# WhatsApp Fiscal (Meta) — o que foi feito e o que falta do lado da BL (04/10/2026)

## Feito no Fiscal (vvohwixeokxydmbhqklu) — testado, código em Blanco-Lisboa/Fisc (commit ef350f6)
- O Fiscal NÃO guarda chave. `fiscal_meta_segredo(slot)` (só servidor) chama `integracao_segredo_ler`
  da BL usando a chave da BL que o Fiscal já tinha no cofre (`bl_service_key`). Não precisa de ponte nova.
- Assinatura HMAC-SHA256 conferida dentro do banco (o app secret nunca sai do banco do Fiscal).
- Recebedor: https://vvohwixeokxydmbhqklu.supabase.co/functions/v1/wa-meta-webhook (campo "messages").
  Dedup por wamid e por corpo repetido; status fora de ordem não regride (lida não volta a entregue);
  mídia baixada em 2 passos, sha256 conferido, guardada no bucket privado `wa-midia`; nova tentativa
  acontece no próximo aviso (sem relógio).
- Envio: edge `wa-meta-enviar` (exige login). Id nasce no cliente; só vira "enviada" quando a Meta
  confirma pelo webhook; janela de 24h; recusa XML/ZIP e arquivo acima do limite.

## Testes (rodados e desfeitos, nada ficou no banco)
HMAC certo=true / errado=false / sem=false · número não cadastrado = erro · 2 mensagens novas ·
repetido ignorado · reação gravada · mídia na fila e falha com nova tentativa marcada · envio preparado ·
envio repetido devolve o mesmo · XML recusado · imagem 6MB recusada · "lida" depois "entregue" fica "lida" ·
erro 131047 gravado · fora da janela recusado.
Chamadas reais publicadas: GET sem modo 400 · token curto 403 · POST sem assinatura 401 ·
assinatura falsa 500 (ainda sem integração ligada) · envio sem login 401.

## Pedido ao Agent BL
1. A integração "WhatsApp Cloud API" ainda NÃO existe na tabela `integracao` do banco BL (só há Conexa).
   Ela nasce quando o William preencher a tela Integrações — ou criar o registro.
2. `integracao_segredo_ler`: hoje qualquer slot diferente de 'app_secret' devolve o TOKEN.
   Pedir: (a) slot 'verify_token' guardado no cofre e editável na tela; (b) slot desconhecido = erro.
3. `cabecalho_extra` com estas chaves: phone_number_id, waba_id, numero, versao (atual: v26.0).
4. Mandar o id da integração → eu rodo `fiscal_meta_ligar(id)` (cadastra o número no Fiscal).

## Falta do meu lado
- XML da nota → PDF (DANFE) antes de enviar.
- Catálogo de modelos (templates) puxado da conta da Meta.
- Ligar a tela do Java do Fiscal a isso (envio de arquivo pelo app, leitura de mídia por link assinado).

## Atualização 04/10 (tarde) — conferido com a documentação da Meta
- O zip enviado tinha só a página inicial; conferi direto no site da Meta.
- Ajustado no Fiscal (commit 76d49b0, testado): cliente sem telefone (BSUID, campos `from_user_id`/
  `contacts[].user_id`, envio por `recipient`), catálogo `wa_modelo` atualizado pelo aviso de aprovação,
  limite diário do número em `wa_saude`, categoria/cobrança por mensagem em `wa_mensagem`.
- Campos a assinar no painel da Meta: messages, message_template_status_update, template_category_update,
  phone_number_quality_update, account_update.
- Pedido enviado ao Agent BL pelo Maestri. Ele já criou a integração (id b68fbaad-f484-4598-a26c-046989cb0700)
  e está corrigindo o leitor de segredos (slot verify_token + slot desconhecido = erro).

## Regra anotada (William, 04/10) — para a tela e os testes
O prefixo "*Nome do colaborador:*" do legado não vai mais dentro da mensagem (nem template, nem texto livre).
Quem falou vira rótulo visual na tela de atendimento, a partir de wa_mensagem.autor_id (já gravado no envio).
