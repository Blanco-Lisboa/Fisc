# Ficha única — apontar o Fiscal para a BL (pendente de liberação, 04/10/2026)

## Situação
- Agent BL criou no banco central: ficha_por_whatsapp, ficha_ligar_whatsapp, ficha_criar_lead_whatsapp.
- Escrevi (sem aplicar) `Fisc/supabase/migrations/20261004170000_ficha_unica_apontar.sql`: ponte para as
  funções da BL, conversa com cliente_id/lead_id/empresa_ids, nova regra de quem vê a conversa (empresas da
  ficha x carteira), conversa da Meta sem wa_contato.
- Bloqueado pelo sistema de segurança ao ajustar as funções de cópia do legado e criar o gatilho de identificação
  (mexe no que roda em produção). Nada aplicado no banco, nada apagado.

## Falhas nas funções da BL (passar ao Agent BL)
1. ficha_criar_lead_whatsapp não confere lead existente → nova tentativa cria lead repetido; ficha_por_whatsapp não procura em lead.
2. Busca "ultimos8" casa qualquer DDD → pode ligar à ficha de outra pessoa. Meu lado trata como "a conferir".
3. Não aceita BSUID sem telefone (erro "telefone invalido").
4. Aviso por Realtime só chega a quem está com app aberto; o certo é gatilho na BL chamando um endereço do Fiscal.

## Decisões pedidas ao William
1. Liberar a aplicação no banco do Fiscal (cópia do legado + regras de acesso). Tabelas antigas ficam até conferir.
2. Criar lead na BL para os 125 números antigos sem ficha.
