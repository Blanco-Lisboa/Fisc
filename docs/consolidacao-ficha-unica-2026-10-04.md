# WhatsApp Fiscal — consolidação na ficha única do cliente (04/10/2026)

Ordem do William: o número de WhatsApp é da FICHA do cliente (banco central BL), desde o lead.
Nada de base paralela no Fiscal. O Fiscal guarda só identificadores e lê o resto por API.

## O que a BL já tem (conferido no banco wfqcoocfastgsfgegpcm)
- `cliente` = a ficha (737 fichas; 733 com `whatsapp` preenchido, 1 número por ficha).
- `contato` (cliente_id, empresa_id, tipo, valor, principal) — existe e está VAZIA.
- `cliente_empresa.papel` (1.444, todos "titular") = de quem é / que papel tem na empresa.
- `cliente_empresa_assunto` + `cliente_assunto` = de que assunto a pessoa trata por empresa
  (ex.: "RESPONSÁVEL DO XML", "RESPONSÁVEL POR RECEBIMENTO DE APURAÇÃO") — é exatamente o "alcance".
- `lead` (cliente_id, pessoa_whatsapp) — o começo da ficha.

## Cruzamento com o Fiscal
Dos 645 números que o Fiscal tem hoje (cópia do legado): 505 batem exato com `cliente.whatsapp`,
mais 15 batem só pelos 8 últimos dígitos (provável 9º dígito), 125 não têm ficha.

## Como fica
### Lado BL (Agent BL)
1. Número mora na ficha: `contato` com tipo='whatsapp', valor = telefone só dígitos com 55,
   + coluna `bsuid` (cliente que esconde o número). Único por (tipo, valor) e por bsuid.
   `cliente.whatsapp` continua como o principal (ou vira um contato principal — decisão do BL).
2. Papel = `cliente_empresa.papel`; alcance = `cliente_empresa_assunto`. Nada disso fica no Fiscal.
3. Funções para o Fiscal (só service_role):
   - `ficha_por_whatsapp(telefone, bsuid)` → cliente_id, nome, empresas [{empresa_id, papel, assuntos}] ou vazio.
   - `ficha_ligar_whatsapp(cliente_id, telefone, bsuid, por)` → pendura o número numa ficha existente.
   - `ficha_criar_lead_whatsapp(telefone, bsuid, nome, companhia, por)` → cria a ficha como lead + lead + contato.
4. Aviso (push) quando um número/vínculo/empresa da ficha mudar → Fiscal atualiza a conversa. Sem relógio.

### Lado Fiscal (eu)
1. `wa_conversa.cliente_id` (já existe) = ponteiro para a ficha. `empresa_ids` (só ids) para a trava de
   acesso, atualizado pelo aviso da BL.
2. O número fica só como ENDEREÇO da conversa (para responder e para casar o aviso da Meta), não como cadastro.
3. Sai do Fiscal: wa_contato, wa_pessoa_vinculo, wa_vinculo_alcance, wa_vinculo_evento, wa_vinculo_tag,
   as funções wa_contato_*, wa_vinculo_promover_dono, wa_meta_contato; `wa_conversa.contato_id`.
   Funções de cópia do legado reescritas sem wa_contato.
4. Trava de acesso: conversa visível se alguma empresa da ficha (empresa_ids) estiver na carteira do usuário
   (ou assistente/gerente); conversa sem ficha = só assistente/gerente.
5. Ordem: só apago depois que as funções da BL existirem; guardo cópia antes de apagar.

## Decisão pendente do William
Número desconhecido que chega pela Meta: (a) cria lead sozinho, ou (b) a conversa fica "sem ficha" até o
atendente ligar a uma ficha ou criar o lead com um clique. Recomendo (b) para não encher a base de lead de spam.
Os 125 números antigos sem ficha seguem a mesma regra.
