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

## Regras aplicadas no envio (conferidas com a tabela da Meta que o William trouxe)
- Imagem: só JPEG/PNG até 5 MB vão como imagem. Imagem maior ou de outro tipo (WebP, GIF, HEIC) vai como documento, original.
- Vídeo: só MP4/3GP com H.264 (o sistema confere "avc1" dentro do arquivo) e até 16 MB vai como vídeo. H.265 ou maior vai como documento, original.
- Áudio: até 16 MB; OGG só vai como áudio se for Opus (confere "OpusHead"). Senão vai como documento, original. A gravação do próprio Fiscal já é OGG/Opus.
- Documento: qualquer formato até 100 MB.
- Acima de 100 MB: não envia e abre a janela "Arquivo acima do limite" com o nome e o tamanho de cada arquivo.
- Sticker (WebP 100 KB): o Fiscal não envia figurinha.

## Teste real 2 (08/10, 10:22) — conferindo a tabela do outro agente
| Envio | Mandado como | Chegou? |
|---|---|---|
| T1 foto JPEG 11,6 MB | foto | NÃO (acima de 5 MB) |
| T2 vídeo H.264 1 MB | vídeo | SIM, toca |
| T3 vídeo H.264 30 MB | vídeo | NÃO (acima de 16 MB) |
| T4 vídeo H.265 1 MB | vídeo | NÃO (formato de vídeo errado) |
| T5 áudio OGG Vorbis | áudio | NÃO (OGG precisa ser Opus) |
| T6 foto 11,6 MB | arquivo | SIM |
| T7 vídeo 30 MB | arquivo | SIM |
| T8 vídeo H.265 | arquivo | SIM |
| T9 áudio OGG Vorbis | arquivo | SIM |

Em todos os casos a Meta respondeu "aceito" (200) e simplesmente não entregou — por isso o sistema decide ANTES de enviar.
Confirma as regras aplicadas no Fiscal (commit 46c706c): o que sai do padrão vai como arquivo original e chega.
