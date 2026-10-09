# Feature Specification: Contextualização Histórica dos 150 Salmos

**Feature Branch**: `003-contexto-historico-salmos`

**Status**: Implemented

## Resumo

Módulo de contextualização histórica que permite ao usuário acessar, para cada um
dos 150 Salmos, informações sobre autoria tradicional, período histórico, contexto
político e social, acontecimentos relacionados, localização geográfica, referências
bíblicas cruzadas (navegáveis internamente), grau de certeza histórica, explicação
acessível e fontes. Todo o conteúdo é **pré-produzido, revisado e embutido no app**,
funcionando **100% offline** — sem APIs externas, IA em tempo real, GitHub ou internet.

## User Stories

1. **US1 — Contexto na leitura (P1):** ao ler um Salmo, o usuário toca em
   "Contexto Histórico" no cabeçalho do capítulo e vê, sem sair da leitura, a
   contextualização completa daquele Salmo (10 campos + selo de certeza).
2. **US2 — Consulta e busca (P1):** pela aba Estudos, o usuário abre a tela
   "Contexto histórico dos Salmos" e busca por personagem, evento, lugar ou
   período, localizando qualquer Salmo.
3. **US3 — Navegação por referências cruzadas (P1):** cada referência cruzada
   leva o usuário, de forma offline, até o livro/capítulo correspondente na aba
   Bíblia.

## Requisitos Funcionais (resumo)

- FR-001: 150 Salmos possuem registro histórico individual, em `assets/data/contexto/Salmos.json`.
- FR-002: Cada registro contém: identificação (número, título, classificação
  literária), autoria tradicional + origem + incerteza, período (associado,
  retratado e composição), contexto político/social, acontecimentos, localização,
  referências cruzadas, grau de certeza, explicação e fontes.
- FR-003: Quando não há base para autoria/data/evento/local, registra-se
  expressamente a indeterminação; nunca se inventam dados.
- FR-004: A classificação de certeza usa quatro níveis: documentado, tradicional,
  hipotese, indeterminado — exibidos de forma clara ao usuário.
- FR-005: Referências cruzadas navegam internamente (offline) para o livro/capítulo.
- FR-006: A pesquisa textual localiza Salmos por personagens, acontecimentos,
  lugares e períodos.
- FR-007: A superfície "Contexto Histórico" fica na tela de leitura (painel) e em
  uma tela de busca acessível pela aba Estudos (sem 6ª aba inferior — decisão de UX
  para público idoso).

## Critérios de Aceitação

- 150 Salmos com contextualização individual; nenhum omitido.
- Todos os campos preenchidos com informação fundamentada ou indicação de
  indeterminação.
- Referências cruzadas funcionam por navegação interna offline.
- Grau de certeza visível; conteúdo consultável sem internet.
- Dados carregados da base interna; conteúdo atualizável sem reestruturar a leitura.

## Assumptions

- Conteúdo histórico é texto próprio/domínio público, com fonte declarada (uso
  comercial do SaaS respeitado).
- O texto bíblico não é duplicado (vem de `assets/data/livros/Salmos.json`).
- A navegação de referência é "melhor esforço" (ancoragem aproximada na lista
  preguiçosa), com destaque visual do capítulo-alvo.
