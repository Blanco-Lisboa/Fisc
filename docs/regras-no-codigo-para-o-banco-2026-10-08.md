# Regras que estão no código e deveriam estar no banco (Fiscal) — 08/10/2026

## 1. Quem é "gestor" (o mais importante)
A lista `assistente, gerente` está escrita à mão em muitos lugares:
- Banco: 16 funções (fiscal_bl_tudo, fiscal_central_gestor, fiscal_clientes_painel, fiscal_mapa_departamento,
  fiscal_carteira_analisar/detalhe/vincular, fiscal_exigir_acesso_vinculo, wa_contato_marcar/desmarcar,
  wa_ficha_conversa, fiscal_minhas_empresas, fiscal_pode_ver_empresa, fiscal_pode_enviar_contato,
  fiscal_pessoas_da_empresa, wa_meta_acao_preparar).
- Banco: 3 travas de tabela (fiscal_carteira, fiscal_usuario, fiscal_copia_legado).
- Servidor: wa-meta-acao (criar grupo).
- Tela: eGestor()/eColab() em ~15 pontos (menu, tela inicial, Painel do Gestor, ações do WhatsApp).

Proposta (pronta, não aplicada — pedir OK):
- `fiscal_nivel_def` (nível, nome, perfil colaborador/gestor, tela inicial)
- `fiscal_permissao` (catálogo: central_colaborador, painel_gestor, departamento_ver, carteira_gerir,
  contato_vincular, wa_entrada_responder, wa_conversa_qualquer, wa_grupo_criar, wa_grupo_gerir)
- `fiscal_nivel_permissao` (qual nível tem qual permissão) — começa idêntico ao de hoje
- `fiscal_pode('permissao')` e `fiscal_minhas_permissoes()`; as 16 funções, 3 travas, o servidor e a tela
  passam a perguntar só para elas. Mudar permissão vira trocar uma linha da tabela.
- Teste de invasão completo depois (sem login, sem cadastro, colaborador, gestor, servidor, escrita).

## 2. Regras que hoje só a tela segura (o servidor deixa)
- Colaborador não responde conversa sem dono: a tela esconde a caixa, mas o banco aceita o envio se o
  contato for da carteira dele.
- Colaborador só organiza (fixar etc.) conversa que é dele: só a tela confere.
Decidir se o banco deve travar igual.

## 3. Limites de arquivo do WhatsApp
Imagem 5 MB, vídeo/áudio 16 MB, documento 100 MB, formatos aceitos: só na tela. Levar para uma tabela
lida pela tela e conferida no envio.

## 4. Textos e catálogos fixos na tela
- Nomes e "quando usar" dos modelos da Meta (MOD_TITULO, TPL_USO, TPL_FISCAL, MODELOS_REAIS).
- Níveis de alcance e natureza do contato (WA_NIVEIS, WA_NATUREZA) — já existem no banco (wa_vinculo_tag), a tela tem cópia.
- Limites da IA (IA_LIMITES), alertas do gestor (ALERTAS_GESTOR), Radar e etapas da Apuração (ainda demonstração).
- Tradução de nível da BL para o Fiscal dentro de fiscal_acesso_bl (colaborador/assistente/senão gerente).

## 5. Pode ficar no código
Rótulos de tela (meses, nomes de status, cores, ícones) — é aparência, não regra.
