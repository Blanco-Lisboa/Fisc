# Banco do Fiscal (vvohwixeokxydmbhqklu) — o que já existe (04/10/2026, só leitura)

## Resumo
Não está vazio. Tem a estrutura do WhatsApp do Fiscal pronta (feita em 28-29/09) e uma CÓPIA
das conversas do WhatsApp antigo (WhatsGW), que chega do legado. Não tem nada da Meta ainda.

## Dados (contagem exata)
| Tabela | Linhas | O que é |
|---|---|---|
| wa_mensagem | 39.360 | mensagens copiadas do legado, de 27/06/2026 a 02/10/2026 (15.862 recebidas) |
| wa_midia | 13.535 | anexos: 13.064 com arquivo guardado, 471 sem arquivo |
| wa_contato / wa_conversa | 645 / 645 | números e conversas |
| wa_numero | 1 | "Fiscal", provedor **whatsgw** |
| wa_vinculo_tag | 9 | etiquetas da tela (catálogo) |
| fiscal_usuario | 11 | equipe do Fiscal |
| fiscal_copia_legado | 696 | registro de cada cópia do legado (última hoje 04:00, 0 erros) |
| fiscal_config / fiscal_legado_config | 1 / 1 | configuração |
| fiscal_carteira, wa_pessoa_vinculo, wa_vinculo_alcance, wa_vinculo_evento | 0 | modelo de contato em 3 camadas: estrutura pronta, sem uso |
| wa_etiqueta, wa_conversa_etiqueta, wa_conversa_evento, wa_fila_saida, wa_saude, wa_webhook_evento | 0 | vazias |

## Funções / automações
- Funções do WhatsApp: wa_contato_achar_ou_criar, wa_contato_marcar/desmarcar, wa_contato_pode,
  wa_contato_alcance, wa_contato_pendencias, wa_vinculo_promover_dono.
- Funções do Fiscal: permissões por nível/carteira, leitura da BL na hora (sem cópia de cliente),
  cópia do legado (fiscal_copiar_legado/periodo/responsaveis, fiscal_receber_do_legado),
  central_enviar (envia pelo legado).
- Gatilhos: travas de acesso em wa_pessoa_vinculo e wa_vinculo_alcance.
- Tarefa agendada: `fiscal-copiar-legado` todo dia às 04:00 (rede de segurança; o recebimento
  "na hora" existe via fiscal_receber_do_legado).
- Todas as tabelas com RLS ligado. 45 migrações registradas (28/09 a 29/09).
- Funções na nuvem (Edge Functions): nenhuma. Webhook da Meta: não existe.

## Pontos de atenção para o app novo
- Tudo que está lá é espelho do WhatsGW. A Meta entra como provedor novo em wa_numero.
- wa_mensagem já separa id_local / id_provedor / id_whatsapp (lições 10-12) — dá pra reaproveitar.
- A tarefa diária das 04:00 é relógio; avaliar com o William se fica (só enquanto o legado existir).
