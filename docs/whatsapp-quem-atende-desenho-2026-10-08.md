# WhatsApp do Fiscal — quem atende cada conversa (desenho, 08/10/2026)

## Regras do William
1. A carteira do usuário do Fiscal é de **CNPJ** (empresa), nunca de pessoa.
2. Qualquer pessoa cadastrada dentro daquele CNPJ na BL (quem trata, sócio/QSA, terceiro) que chamar no WhatsApp
   cai direto no dono da carteira daquele CNPJ.
3. A mesma pessoa só pode falar com UM usuário do Fiscal. Logo, todas as empresas em que ela aparece têm que estar
   na mesma carteira. O banco recusa montar carteira que quebre isso (mostra quais empresas precisam ir junto).
4. Número que não está na BL cai para o gestor. Ele liga o número a um CNPJ: se a empresa ainda não tem quem trata,
   a pessoa entra como quem trata; se já tem, entra como terceiro, com a classificação certa. Isso é gravado NA BL.
5. Nada de copiar cadastro de cliente para o Fiscal.

## Como fica (ideia do William: já deixar pronto em vez de perguntar a cada mensagem)
- **BL é a dona do cadastro**: pessoa, empresa, papel da pessoa na empresa (quem trata, QSA, terceiro +
  classificação) e o WhatsApp de cada pessoa (tabela `contato`, com número e bsuid).
- **Fiscal guarda um "mapa de entrega"** (`wa_roteamento`): número/bsuid → id da pessoa na BL → ids das empresas.
  Só identificadores, nenhum nome ou dado de cadastro. É como o endereço numa etiqueta, não a ficha do cliente.
- **Quem mantém o mapa é a BL, por aviso**: quando um WhatsApp, papel ou terceiro muda na BL, ela avisa o Fiscal,
  que refaz só aquela linha. Se os cadastros forem apagados e refeitos, o mapa se refaz sozinho.
- **Dono da conversa** = mapa de entrega × carteira (CNPJ → usuário). Instantâneo, sem perguntar à BL na hora.
  Se o Gustavo perde o CNPJ, a conversa passa para o novo dono na mesma hora.
- Nome e dados aparecem na tela lidos da BL quando a ficha abre (como já é hoje). O nome que a pessoa usa no
  próprio WhatsApp continua no Fiscal, porque é dado do WhatsApp, não do cadastro.

## O que muda no Fiscal
- Sai o modelo próprio de "este número é de fulano" (wa_pessoa_vinculo, wa_vinculo_alcance, wa_vinculo_evento,
  wa_vinculo_tag — vazios) e as 10 funções passam a usar o mapa de entrega.
- Trava da regra 3 na montagem de carteira.
- Tela do gestor para número desconhecido: escolher CNPJ → quem trata ou terceiro + classificação → grava na BL.

## O que precisa do Agent BL
- Aviso ao Fiscal quando `contato` (WhatsApp), `cliente_empresa` (papéis) ou `cliente_terceiro` mudarem.
- Função "de quem é este número" que inclua terceiros e não chute pelos últimos 8 dígitos.
- Função para o gestor do Fiscal gravar número novo como quem trata ou terceiro classificado.

## Ponto em aberto
Existem duas carteiras: `fiscal_carteira` (Fiscal) e `carteira_usuario_empresa` (BL, com departamento). Usar uma só.
Pela base única, a da BL com departamento = Fiscal; o Fiscal lê. Precisa decisão.
