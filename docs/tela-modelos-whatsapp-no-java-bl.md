# Tela "Modelos de WhatsApp" no Java BL — o que precisa ter

Para: Agent BL. De: Zap (WhatsApp Fiscal). Data: 06/10/2026.

## O que é
Modelo = mensagem pré-aprovada pela Meta. É o único jeito de a empresa puxar conversa com o cliente
(ou falar depois de 24h sem resposta dele). Cada modelo passa por análise da Meta antes de poder ser usado.
Hoje o Fiscal tem 19 modelos (18 enviados à Meta, 1 aguardando link de vídeo).

## Onde moram os dados
- Os modelos ficam no banco do Fiscal (vvohwixeokxydmbhqklu), tabela wa_modelo. Nada é copiado para o banco da BL.
- O Java BL lê e altera por uma API do Fiscal (função "wa-modelos"), entrando com o login normal da BL.
- Quem pode usar a tela: CEO e diretor (nível na BL). Colaborador não vê esta tela.
- Pensada para vários departamentos: todo modelo tem o campo "departamento" (hoje só Fiscal).

## 1. Lista de modelos (tela principal)
Uma linha/cartão por modelo, com:
- Nome do modelo (ex.: fiscal_solicitacao_xml)
- Departamento (Fiscal)
- Categoria: Utilidade / Marketing / Autenticação
- Situação na Meta: Em análise / Aprovado / Recusado / Pausado / Desativado
- Em uso: sim/não (chave liga/desliga — decide se o time pode escolher esse modelo na conversa)
- Qualidade dada pela Meta: Alta / Média / Baixa / Sem nota
- Idioma (Português BR)
- Última atualização (data/hora) e quem mexeu por último
Filtros: departamento, categoria, situação, em uso. Busca por nome ou por texto.
Botão "Novo modelo". Botão "Atualizar da Meta" (puxa a situação atual na hora).

## 2. Detalhe do modelo (ao abrir um)
- Tudo da lista, mais:
- Prévia igual ao celular (cabeçalho, texto com os exemplos preenchidos, rodapé, botões)
- Texto completo com as lacunas {{1}}, {{2}}...
- Lista das lacunas com o que cada uma significa e o exemplo (ex.: {{1}} = nome do colaborador, exemplo "Larissa")
- Cabeçalho: tipo (nenhum / texto / PDF / imagem / vídeo) e conteúdo
- Rodapé
- Botões: tipo (resposta rápida / abrir link / copiar código) e texto de cada um; para link, o endereço
- Motivo da recusa (quando a Meta recusar), em português
- Histórico: quem criou, quem editou, quem ligou/desligou o uso, quem apagou, com data/hora e resultado
- Quantas vezes foi enviado e quantas respostas teve (quando o envio estiver ligado)
Ações: Editar, Duplicar (criar parecido), Ligar/Desligar uso, Apagar.

## 3. Criar / editar modelo (formulário)
Campos, na ordem da Meta:
- Departamento (lista)
- Nome do modelo (só minúsculas, números e _ ; até 512; ex.: fiscal_lembrete_das)
- Categoria: Utilidade / Marketing / Autenticação
- Idioma: Português (BR)
- Cabeçalho (opcional): nenhum / texto (até 60) / PDF / imagem / vídeo
  - se for PDF/imagem/vídeo: anexar um arquivo de exemplo (a Meta exige)
- Texto (corpo): até 1024 caracteres, com botão "Inserir lacuna" ({{1}}, {{2}}...)
- Exemplo de cada lacuna (uma caixa por lacuna — a Meta exige)
- Rodapé (opcional, até 60)
- Botões (opcional, até 10):
  - Resposta rápida: texto (até 25)
  - Abrir link: texto (até 25) + endereço (pode ter parte variável no fim)
  - Ligar: texto + telefone
  - Parar de receber (obrigatório em Marketing)
- Prévia ao lado, atualizando enquanto digita
- Botão "Enviar para análise"
Padrão do Fiscal já combinado (pode vir preenchido): cabeçalho "Departamento Fiscal", rodapé "Equipe Fiscal",
{{1}} sempre = nome do colaborador, sempre com botão de resposta.
Validações antes de enviar (para não ser recusado):
- texto não pode começar nem terminar com lacuna
- lacunas em sequência ({{1}}, {{2}}, {{3}}), sem pular
- toda lacuna com exemplo
- Marketing precisa do botão "Parar de receber"
- nome não pode repetir um que já existe

## 4. Vídeo do comunicado (o modelo da Reforma)
Duas versões do mesmo comunicado, a pessoa escolhe na hora de enviar:
- Com link: campo "Link do vídeo" (YouTube, Drive...). O sistema cria um link curto da YOU que leva ao vídeo.
  Dá para trocar o vídeo sem pedir nova aprovação.
- Com vídeo: anexar o vídeo (até 16 MB) que vai dentro da mensagem.
Na tela de modelos: mostrar as duas versões como um par ("comunicado da Reforma — link / vídeo").

## 5. Situação que muda sozinha
A Meta avisa quando aprova, recusa, pausa ou muda a categoria. O Fiscal grava na hora e a tela do Java BL
deve se atualizar sozinha (aviso do banco, sem ficar perguntando de tempo em tempo).

## 6. O que o Zap entrega (lado do Fiscal)
- API "wa-modelos" com as ações: listar, detalhe, criar, editar, apagar, ligar/desligar uso, atualizar da Meta,
  histórico. Entrada com o login da BL; só CEO/diretor.
- Link curto do vídeo e as duas versões do comunicado da Reforma.
- Envio no Java do Fiscal só oferece modelos Aprovados E "em uso".

## 7. O que o Agent BL precisa decidir com o William
- Em que lugar do Java BL a tela fica (menu, aba, dentro de qual módulo).
- O desenho da tela (o William manda o gabarito; não inventar visual).
