# Teste real: arquivos pela Meta sem converter (08/10/2026)

Número de teste da Meta → WhatsApp do William.

| Arquivo | Como foi | Resultado |
|---|---|---|
| XML (164 B) | subir na Meta (upload) | RECUSADO: "Param file must be a file with one of the following types ... Received file of type 'application/xml'" |
| XML (164 B) | por link | chegou e abriu como XML |
| ZIP (351 B) | por link | chegou como ZIP |
| ZIP 100 MB (104.857.600 bytes) | por link | chegou |
| ZIP 200 MB | por link | Meta aceitou o pedido, mas NÃO entregou |

Conclusão: o Fiscal já envia arquivo por link (URL assinada do bucket wa-midia), então qualquer formato vai original,
até 100 MB para documento. Tirada a trava de XML/ZIP (tela + wa_meta_preparar_envio). Limites mantidos:
imagem 5 MB, áudio e vídeo 16 MB, documento 100 MB (o bucket também barra acima de 100 MB).
A documentação oficial lista só txt/pdf/office para documento, mas o envio por link entregou XML e ZIP.
