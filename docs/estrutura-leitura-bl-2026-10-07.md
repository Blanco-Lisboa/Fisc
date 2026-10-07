# Como o Fiscal deve ler os dados da BL — estudo pela Base de Conhecimento (07/10/2026)

## O problema medido
- Aba Clientes: 6 perguntas à BL, uma atrás da outra, ~0,5 s cada (ida e volta pela rede) = ~4,7 s. Central: ~1,7 s.
- Dentro da BL, montar tudo junto leva ~0,3 s (medido com EXPLAIN ANALYZE: 1450 empresas + 1444 pessoas).
- Conclusão: o tempo não está no banco, está no número de idas e voltas.

## O que a Base diz (fontes em C:\Projetos\Conhecimento\Agent-s-Conhecimento-main\agentes_kb_pronto)
1. Menos idas e voltas — "O ideal é que esse número de round trips seja 1, ou no máximo uma constante pequena" e "DTO para adequar a granularidade do serviço, almejando um único round trip" (Introdução à Arquitetura e Design de Software, arquitetura-de-software__doc_01561). Session Facade: interface "de granularidade mais grossa" (doc_01592). Caso Netflix: reduzir round trips (doc_01601).
2. Uma função no banco no lugar de várias chamadas — "only one round trip ... rather than 5 or 6" (What Goes Around Comes Around, database__doc_00566).
3. Dono único dos dados expõe API própria do caso de uso — "services expose an application-specific API ... This restriction provides a degree of encapsulation" (DDIA, entrevistas-e-preparacao__doc_00866); sem estado compartilhado entre serviços (doc_01227).
4. Cópia local (réplica/espelho) é "derived data": duplica e exige manter sincronizado (DDIA doc_01120, doc_01208, doc_01225). Já é proibido pela nossa regra "uma base de clientes só".
5. Paralelo ajuda pouco: "still needs to wait for the slowest of the parallel calls" (DDIA doc_00750).
6. Estado na tela é um cache; mantê-lo fresco por aviso (push), não por consulta repetida (DDIA doc_01246, doc_01242).

## Estrutura recomendada (3 peças)
1. **BL: uma função de leitura por tela** (ex.: `fiscal_painel_clientes()` e `fiscal_central_base()`), que já devolve tudo junto e só os campos usados: empresa (id, CNPJ, nome, ativa), titular/quem trata (id, nome, CPF). Só lê, só empresas com vínculo ativo à YOU, só a chave de servidor do Fiscal pode chamar. Devolve um único bloco, sem o corte de 1000 linhas.
2. **Fiscal: troca as 6 perguntas por 1.** Nada é guardado no banco do Fiscal; continua só o ID. Estimativa: ~0,8 s em vez de ~4,7 s (confirmar medindo depois).
3. **Atualização por aviso:** quando cliente, vínculo ou quem trata mudar na BL, um gatilho avisa o Fiscal (mesmo padrão já usado em `fiscal-usuario-mudou`), e a tela recarrega sozinha. Some a necessidade de reconsultar a cada abertura de aba.

## Descartado
- Cópia/espelho no Fiscal: proibido pela regra e a Base aponta o custo de sincronizar.
- Só paralelizar: continua preso à chamada mais lenta e aumenta a carga na BL.

## Quem faz o quê
- Agent BL: as 2 funções e o gatilho de aviso no banco da BL.
- Zap: trocar as chamadas no Fiscal, medir antes/depois, ligar o aviso na tela.
