# Carteira e vínculos — desenho final (09/10/2026)

Base: investigação do app antigo (código + changelog, 19 problemas) e do banco antigo `uvmcfnghdsmpzhijqlos`
(só leitura, 42 problemas medidos). Arquivos em `docs/legado/`. Regras do William de 08/10.

## 1. O que deu errado no antigo (o que este desenho impede)
| # | Problema no antigo | Medido | Como o novo impede |
|---|---|---|---|
| 1 | Dono da empresa/conversa guardado em 3 lugares, sem nada que os mantivesse iguais; 7 caminhos gravavam o dono | 29 empresas com donos divergentes; 9 correções; "limpou 926 conversas e sempre voltou" | Dono existe em UM lugar (carteira). A conversa não tem dono próprio: o dono é calculado da carteira |
| 2 | "Finalizar atendimento" copiava o dono da conversa para a carteira | apagava decisão do gestor | Nada escreve na carteira a não ser a função de atribuir |
| 3 | Mesmo telefone em 6 lugares; número em várias empresas; conversa escolhia "a primeira" empresa | 260 números em 2+ empresas (um em 55); 251 de 732 conversas ambíguas | Um número pertence a UMA pessoa (único no banco). A pessoa liga às empresas pelos papéis |
| 4 | Pessoa copiada uma vez por empresa, 97% sem CPF, montada na tela | 456 repetidas; 45 em donos diferentes | Pessoa única com CPF único; papel por empresa em outra tabela |
| 5 | Quem trata / QSA de 3 jeitos, ligados por texto; CPF do representante em texto solto | 361 quem trata repetidos; 1.062 CPFs sem pessoa | Papel é linha com id de pessoa e id de empresa; 1 quem trata ativo por empresa |
| 6 | Sem lugar para terceiro (contador externo, procurador) | — | Terceiro é pessoa + empresa + classificação (tag) |
| 7 | Empresa ativa sem dono; inativa com dono | 124 / 80 | Lista "sem dono" no painel do gestor; empresa inativa sai da carteira por gatilho |
| 8 | Regra de quem vê cliente na tela, mudou 6 vezes; bloqueio falhava calado | — | Regra só no banco (`fiscal_pode` + carteira); erro sempre explícito |
| 9 | Transferência não entregava a conversa e não guardava quem transferiu | 4 correções | Transferir = mudar carteira por função única, com histórico (quem, quando, motivo) |
| 10 | Telefone com 2 regras de limpeza; 9º dígito apagado na comparação | 99% fora do padrão | Número guardado num formato só (55 + DDD + número), conferido pelo banco; nunca compara por pedaço |
| 11 | 1.244 de 1.354 mudanças de banco sem arquivo | — | Toda mudança é migração versionada no GitHub |

## 2. Onde mora cada coisa
**BL (dona do cadastro, fonte única)**
- Pessoa (`cliente`): CPF único (já existe).
- Empresa (`empresa`): CNPJ único (já existe).
- Papel da pessoa na empresa (`cliente_empresa`): quem trata, sócio/QSA, titular, responsável; 1 quem trata ativo
  por empresa (já existe). Terceiro (`cliente_terceiro`): pessoa + empresa + classificação (já existe).
- WhatsApp da pessoa (`contato` tipo whatsapp): número único e bsuid único (já existe). **Ajustar**: guardar no
  formato único e conferir; tirar a cópia em `cliente.whatsapp` (dois lugares = problema 3).
- **Carteira** (`carteira_usuario_empresa`): empresa + departamento + usuário. **Ajustar** (ver 3).

**Fiscal (só identificadores)**
- `wa_contato`: o número/bsuid como o WhatsApp manda.
- `wa_roteamento` (mapa de entrega, NOVO): contato → id da pessoa na BL → ids das empresas → id do dono no Fiscal.
  Sem nome, sem CPF, sem cadastro. Refeito por aviso da BL.
- Conversas e mensagens apontam para o contato. O dono da conversa vem do mapa (não é campo editável).
- Sai: `wa_pessoa_vinculo`, `wa_vinculo_alcance`, `wa_vinculo_evento`, `wa_vinculo_tag` (vazias) e `fiscal_carteira`.

## 3. Regras no banco (BL)
1. **Um dono por empresa por departamento**: único (empresa, departamento) entre as linhas ativas.
2. **Histórico**: linha nunca é apagada; tem início, fim, quem mudou e motivo.
3. **Dono tem que ser do departamento** (usuário ligado ao setor).
4. **Uma pessoa = um usuário por departamento**: todas as empresas em que a pessoa é quem trata, sócio ou terceiro
   ficam com o mesmo dono. Conferido no fim da transação; se quebrar, o banco recusa e devolve a lista de empresas
   que precisam ir junto. Vale também quando se acrescenta papel/terceiro numa empresa de outro dono.
5. **Porta única**: carteira só muda pela função `carteira_atribuir(empresas, departamento, usuário, motivo)`, que
   move o grupo inteiro de uma vez. Tela não grava direto na tabela.
6. **Empresa inativa sai da carteira** (gatilho, com histórico).

## 4. Fluxo da mensagem
1. Chega mensagem. O Fiscal olha o mapa de entrega daquele número.
2. Achou → conversa aparece só para o dono do CNPJ (e para os gestores).
3. Não achou → pergunta à BL uma vez (`whatsapp_destino(número, bsuid)`, número exato, sem chute) e grava no mapa.
4. Continua sem dono → fila do gestor. O gestor escolhe o CNPJ; a BL grava como quem trata (se a empresa não tem)
   ou como terceiro classificado (se já tem). A BL avisa, o mapa se refaz, a conversa vai para o dono.

## 5. Como o mapa fica certo sem relógio
- Gatilhos na BL em `contato`, `cliente_empresa`, `cliente_terceiro` e na carteira avisam o Fiscal (aviso assinado)
  com os ids que mudaram. O Fiscal refaz só aquelas linhas.
- Cada aviso tem número sequencial. Se o Fiscal notar um número pulado (aviso perdido), refaz o mapa inteiro.
- Cadastros apagados e refeitos na BL disparam os mesmos avisos: o mapa se religa sozinho.

## 6. Quem faz
- Agent BL: ajustes da carteira (regras 1–6), formato único do número, tirar `cliente.whatsapp`, gatilhos de aviso,
  `whatsapp_destino` com terceiros e sem chute, função do gestor para gravar número novo.
- Zap (Fiscal): mapa de entrega, receber aviso, dono da conversa pelo mapa, fila e tela do gestor, Painel do Gestor
  gravando a carteira pela função da BL, retirar as tabelas antigas.
- Teste de invasão e teste das regras com casos reais antes de dizer pronto.
