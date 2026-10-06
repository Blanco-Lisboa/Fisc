# Importar o histórico do WhatsApp do celular do Fiscal

## Antes da troca do número (no celular Android)
1. WhatsApp Business → Configurações → Conversas → Backup de conversas → Backup criptografado de ponta a ponta →
   ativar com **chave de 64 dígitos**. Anotar a chave (é segredo; não mandar em chat).
2. Fazer o backup (botão "Fazer backup").
3. Ligar o celular no computador (cabo USB, modo "Transferir arquivos") e copiar para uma pasta, ex. C:\backup-fiscal:
   - Android\media\com.whatsapp.w4b\WhatsApp Business\Databases\msgstore.db.crypt15
   - a pasta inteira Android\media\com.whatsapp.w4b\WhatsApp Business (tem as fotos, áudios e documentos).

## Depois que o número estiver ligado na Meta
No computador (uma vez): `python -m pip install wa-crypt-tools`

Rodar:
```
python importar.py --backup C:\backup-fiscal\msgstore.db.crypt15 --midias "C:\backup-fiscal\WhatsApp Business" --numero 55DDNUMERO --usuario CPF_OU_EMAIL --desde 2026-10-02
```
- O programa pede a senha da BL e a chave de 64 dígitos (nada fica salvo).
- Precisa ser um usuário do departamento Fiscal com nível assistente ou gerente.
- `--desde`: só traz mensagens a partir dessa data (o que é anterior a 02/10 já está no banco).
- Pode rodar de novo: o que já foi importado não duplica.
- Grupos não são importados (a API não usa os grupos do celular).
