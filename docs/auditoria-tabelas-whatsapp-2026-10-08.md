# Auditoria das tabelas do WhatsApp no banco do Fiscal — 08/10/2026

Banco `vvohwixeokxydmbhqklu`. Números medidos hoje.

## Como a mensagem chega no cliente (desenho)
mensagem (`wa_mensagem`, 39.360) → conversa (`wa_conversa`, 646) → contato (`wa_contato`, 645, telefone + bsuid)
→ vínculo (`wa_pessoa_vinculo`: id da PESSOA na BL ou id da EMPRESA na BL) → alcance (`wa_vinculo_alcance`: de que
empresa ele pode falar). Tudo por id, com chave estrangeira dentro do Fiscal; o id da BL é ponteiro (não há cópia
de cliente). Desenho está certo: o cliente é achado pelo id da BL, não pelo número.

## O que está errado ou incompleto
1. **Nenhum contato está ligado a ninguém da BL**: 0 vínculos e 0 alcances para 645 contatos. Na prática, hoje
   nenhuma mensagem está ligada a cliente, sócio ou terceiro. Falta fazer a ligação (manual pela etiqueta, ou em
   lote pelo legado/BL).
2. `wa_conversa.cliente_id`: coluna sem uso (0 preenchidas), de antes do modelo de 3 camadas. Confunde; remover.
3. `wa_conversa.contato_telefone / contato_nome / contato_bsuid`: repetem o que já está em `wa_contato`. Pode
   divergir. Ler de `wa_contato` e remover.
4. `wa_pessoa_vinculo.pessoa_nome` e `cargo`: guardam nome em texto para quem não tem cadastro na BL. Pela regra
   da base única, terceiro (contador externo, funcionário, familiar) deve ser cadastrado na BL e aqui só o id.
5. Apagar uma conversa apaga todas as mensagens junto (`on delete cascade`). Histórico de cliente não deve sumir
   assim; trocar para bloquear.
6. Ponteiro para a BL não tem como ter chave estrangeira (são bancos diferentes): a conferência é feita na hora
   de vincular (`wa_contato_marcar` pergunta à BL). Está certo, mas falta uma rotina que avise quando a pessoa ou
   empresa sumir/inativar na BL (por aviso, não por relógio).

## O que a Meta oferece e já guardamos
Mensagens: texto, imagem, áudio, vídeo, documento, figurinha, localização, contato, botões, listas, respostas de
Flow, reação, sistema, não suportada, encaminhada, resposta a mensagem. Status: enviada, entregue, lida, falhou,
preço/categoria cobrada. Modelos: status e mudança de categoria. Número: qualidade e limite. Conta: atualizações.
Grupos: criação, participantes, configurações, status. Mídia baixada para bucket privado com conferência de sha256.

## O que a Meta oferece e NÃO guardamos
- Chamadas (Calling API): não há tabela nem tratamento.
- Preferência do usuário (pediu para não receber marketing — `user_preferences`): não guardado. Importante para
  não mandar modelo de marketing a quem pediu para sair.
- Registro de opt-in (quando e como o cliente aceitou receber mensagem): não existe.
- Qualidade do modelo (`message_template_quality_update`): não tratado.
- Origem por anúncio (`referral`, clique em anúncio que abre conversa): não guardado.
- Coexistência / histórico / eco de mensagens do app (`history`, `smb_message_echoes`): não tratado (só importa se
  o número for usado também no aplicativo WhatsApp Business).
