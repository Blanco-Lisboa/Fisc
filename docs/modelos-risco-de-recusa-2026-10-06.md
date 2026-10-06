# Risco de recusa/reclassificação dos modelos enviados (06/10/2026)

Regras conferidas (relatos de usuários e guias de provedores, 2025-2026):
- Utilidade só vale para algo específico do cliente (uma transação/obrigação real). Texto genérico ou com tom de
  propaganda vira Marketing automaticamente (desde 09/04/2025) e custa 5x a 7x mais.
- Pesquisa de satisfação genérica não é Utilidade (só se ligada a um atendimento específico).
- Lacuna não pode abrir nem fechar o texto (já corrigido no 3 e no 11).
- Proporção mínima de palavras: (nº de lacunas x 3) + 1. Todos os nossos passam.
- Texto acima de 550 caracteres, mais de 10 emojis ou modelo duplicado: recusa. Os nossos estão abaixo de 550 e sem emoji.
- Tom agressivo/ameaçador pode ser recusado.

## Por modelo
| # | Modelo | Risco | Por quê |
|---|---|---|---|
| 12 | fiscal_aviso_alteracao_cadastral | ALTO (virar Marketing) | genérico, não fala de nada específico do cliente |
| 17 | fiscal_comunicado_institucional | MÉDIO (recusa) | quase todo o conteúdo está na lacuna {{2}} ("Informamos: {{2}}") |
| 5 | fiscal_lembrete_urgente_xml | MÉDIO (recusa por tom) | "pode resultar em multa... ainda hoje" pode soar como pressão |
| 13 | fiscal_atualizacao_rotina_erp | BAIXO-MÉDIO | "atualização cadastral de rotina" é aceito, mas é genérico |
| 16 | fiscal_pesquisa_satisfacao | baixo | já foi como Marketing, com "Parar de receber" |
| 7, 9 | entrega/recibo com PDF | baixo | anexo deixa a análise mais lenta, não recusa |
| demais | — | baixo | específicos: empresa, mês, valor, prazo |

## Se acontecer
- Virou Marketing: refazer com nome novo e texto amarrado a um fato do cliente (como foi feito no certificado).
- Recusado: a Meta devolve o motivo; ajustar e reenviar (pode editar o recusado sem trocar o nome).

## Fontes
- https://www.spurnow.com/en/blogs/why-are-my-whatsapp-templates-getting-rejected
- https://asisteclick.com/en/blog/plantillas-whatsapp-rechazadas-meta-7-errores/
- https://learn.turn.io/l/en/article/hih36ejoqy-how-to-get-your-whats-app-template-reclassified-from-marketing-to-utility
- https://sdcsupport.syniverse.com/hc/en-us/articles/30569685832471-How-to-avoid-too-many-parameters-rejection-in-WhatsApp-Templates
- https://developers.facebook.com/docs/whatsapp/updates-to-pricing/new-template-guidelines/
- https://m.aisensy.com/blog/utility-whatsapp-templates-best-examples/
