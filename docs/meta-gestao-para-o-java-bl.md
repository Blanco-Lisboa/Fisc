# Módulo "IA & Meta" — como o Java BL usa os mesmos dados (09/10/2026)

O Java do Fiscal (aba Meta do módulo IA & Meta) e o Java BL olham o MESMO lugar: o banco do Fiscal
(`vvohwixeokxydmbhqklu`). Nada é copiado para o banco da BL. Os dois veem a mesma coisa ao mesmo tempo.

## Onde estão os dados (banco do Fiscal)
- `wa_numero_meta`: situação do número e da conta na Meta (nome exibido, qualidade, limite de conversas,
  análise da conta, selo oficial). Atualizado pela ação "sincronizar" e pelos avisos da Meta.
- `wa_modelo`: modelos de mensagem (situação, categoria, qualidade, em uso, motivo da recusa, conta `waba_id`).
- `wa_meta_evento`: avisos da Meta para gestor (gravidade, título, explicação, quem marcou como visto).
- `wa_modelo_acao`: histórico (quem pediu modelo, ligou/desligou uso, recusa da Meta).
- `wa_saude`: envio liberado/bloqueado, chave recusada.
Todas em tempo real (publicação `supabase_realtime`).

## Leitura e ações
- Leitura: `wa_meta_painel()` devolve tudo numa chamada. Exige `fiscal_pode('wa_conta_ver')`.
- Marcar aviso como visto: `wa_meta_evento_ciente(p_evento)`.
- Ligar/desligar uso de um modelo: `wa_modelo_usar(p_modelo, p_em_uso)` (`wa_modelo_gerir`).
- Conferir um modelo antes de pedir: `wa_modelo_validar(p)` (regras da Meta, no banco).
- Edge `wa-meta-gestao`:
  - `{acao:'sincronizar'}` — lê da Meta (só leitura) o número, a conta e os modelos.
  - `{acao:'pedir_modelo', modelo:{nome,categoria,idioma,cabecalho,corpo,exemplos,rodape,botoes}}` — pede um
    modelo novo à Meta. Só quando um gestor clica.
- Quem pode: `wa_conta_ver` (ver) e `wa_modelo_gerir` (agir), hoje assistente e gerente do Fiscal, no banco.

## O que falta para o Java BL
- Entrar no banco do Fiscal com o login BL do usuário (a edge `fiscal-entrar` troca o login da BL por uma sessão
  do Fiscal) ou, para CEO/diretor que não são usuários do Fiscal, a regra de acesso desses níveis no banco.
  A decidir com o William e o Agent BL.
- A tela no Java BL: lugar e visual definidos pelo William.

## Limites atuais
- Cabeçalho de modelo só texto (PDF, imagem e vídeo exigem enviar arquivo de exemplo à Meta: próximo passo).
- Editar modelo já aprovado não existe de propósito: a Meta manda de volta para análise.
- A conta ligada hoje é a de TESTE; os modelos do Fiscal estão na conta oficial. Cada modelo guarda de qual conta é.
