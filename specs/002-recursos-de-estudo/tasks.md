<!--
  Sync Impact Report (tasks)
  - Creates the task list for feature 002-recursos-de-estudo.
  - Tests-first where practical; each change updates the QA matrix (cases EST1–EST6).
  - Constitution Check: tasks honor gates I–V.
-->

# Tasks: Recursos de Estudo do Texto Bíblico

**Input**: Design documents from `specs/002-recursos-de-estudo/`

**Prerequisites**: [spec.md](spec.md) (US1–US5, FR-001…FR-016, NFR-001…NFR-010),
[plan.md](plan.md), [data-model.md](data-model.md),
[contracts/estudos.md](contracts/estudos.md), [quickstart.md](quickstart.md),
`tool/QA_EDGE_CASES.md` e constituição `.specify/memory/constitution.md` (v1.0.0).

**Tests**: os novos casos da matriz (`EST1`…`EST6`) ganham testes unitários do
módulo puro; a suíte existente deve permanecer verde.

## Formato

- `[ID] [P?] [Story] Descrição`
- **[P]**: arquivos diferentes, sem dependência.
- Caminhos reais da raiz do projeto Flutter.

---

## Phase 1: Fundacional — Lógica Pura e Dados

- [x] T001 [P] Criar `lib/catalogo_estudos.dart`: modelo `RecursoEstudo`/
      `FonteEstudo`, parsing defensivo (`recursoDeMapa`, `recursosDeJson`),
      rótulos/tipos (`tiposConhecidos`, `rotuloTipo`, `agruparPorTipo`), casamento
      (`capituloDaReferencia`, `recursoAplicavel`, `recursosAplicaveis`) e filtros
      (`filtrarRecursos`, `tiposDisponiveis`, `livrosDisponiveis`).
- [x] T002 [P] Criar `lib/cache_estudos.dart` (`CacheDeEstudos`), espelhando
      `CacheDeLivros` (deduplicação + retry em falha transiente).
- [x] T003 [P] [US1] Criar dados curados iniciais: `assets/data/estudos_indice.json`
      e `assets/data/estudos/<Livro>.json` (Gênesis, Êxodo, Salmos, Mateus, João,
      Apocalipse) cobrindo os 6 tipos e casos de ref de versículo/capítulo/livro.
- [x] T004 [US1] Declarar os novos assets em `pubspec.yaml`
      (`assets/data/estudos_indice.json`, `assets/data/estudos/`).
- [x] T005 [P] [US1] Criar `test/catalogo_estudos_test.dart` (casos EST1–EST6):
      JSON ausente/corrompido, itens inválidos ignorados, casamento por
      versículo/capítulo/livro + prefixo numérico, corpo vazio, determinismo dos
      agrupamentos/filtros, rótulo genérico. Referenciar os códigos da matriz.

**Checkpoint**: catálogo puro testado e dados disponíveis; nada de UI ainda.

---

## Phase 2: Widget reutilizável

- [x] T006 [P] [US1] Criar `lib/widgets/painel_estudos.dart`
      (`PainelEstudos`): estado vazio amigável; recursos agrupados por tipo;
      corpo + crédito; ações Salvar/Remover e Ouvir (respeitando `ttsDisponivel`);
      `Semantics`; sem regra de negócio (usa a lógica pura); sem overflow.

**Checkpoint**: painel isolado, pronto para os dois pontos de uso.

---

## Phase 3: Integração na UI (US1–US5)

- [x] T007 [US1] `lib/main.dart`: carregar o índice de estudos na abertura e
      expô-lo no estado; injetar `CacheDeEstudos` (loader de
      `assets/data/estudos/<Livro>.json`), com nova chave de favoritos
      `favoritos_estudos` (fila last-write-wins) e helpers
      `_temEstudos`/`_carregarRecursosDe`.
- [x] T008 [US1] Indicador de estudo nos versículos e no cabeçalho do capítulo;
      abrir o painel via bottom sheet sem perder a posição de leitura.
- [x] T009 [US2] Garantir a apresentação por tipo e o crédito de fonte no painel
      (via `PainelEstudos`) — validar artigo/sermão/palestra/momento histórico.
- [x] T010 [US3] Criar a aba/seção **Estudos**: lista do índice com filtros por
      tipo e por livro; estado vazio claro; abrir recurso no painel.
- [x] T011 [US4] Recurso salvo: botão nos itens/painel; seção de recursos de
      estudo na aba **Salvos** (abrir/remover; `"Conteúdo não encontrado."` para
      id órfão).
- [x] T012 [US5] Ouvir recurso em voz alta reaproveitando `_iniciarLeitura`
      (manual e não contínuo; degradação sem voz).

**Checkpoint**: feature completa ponta a ponta na UI.

---

## Phase 4: Documentação e Qualidade (US8)

- [x] T013 [P] Atualizar `tool/QA_EDGE_CASES.md` com EST1–EST6 e status.
- [x] T014 [P] Atualizar `contracts` (novo `estudos.md` já criado; acrescentar a
      chave `favoritos_estudos` e os assets em `storage.md` da 001) e
      `data-model.md` se necessário.
- [x] T015 [P] Atualizar `README.md` (seção "Como editar o conteúdo") com o passo
      de adicionar recursos de estudo.
- [x] T016 Rodar `flutter analyze` e `flutter test`; todos verdes (SC-007).
      — `analyze` limpo; 74 testes verdes (todas as suítes exceto o estresse C6).
      O estresse `test/estresse_c6_test.dart` (C6) **trava** ao expandir os 66
      livros — pendência pré-existente da feature 001 (T013 da 001), fora do
      escopo da 002.

---

## Dependencies & Execution Order

- Phase 1 (T001–T005) não depende de nada; T004 depende dos arquivos de T003.
- Phase 2 (T006) depende de T001.
- Phase 3 (T007–T012) depende de T001, T004 e T006; toca `lib/main.dart`
  sequencialmente (T007→T012).
- Phase 4 (T013–T016) depende de todas.

## Paralelismo [P] seguro

- T001/T002/T003/T005: arquivos diferentes.
- T013/T014/T015: documentação independente.

## Notas

- Preservar os gates da constituição v1.0.0: lógica pura em `lib/`, widget sem
  regra de negócio, 320 px × 1.18 sem overflow, pt-BR, `setState` guardado por
  `mounted`, escritas serializadas.
- Nenhuma dependência nova.
- Rodar a suíte ao fim de cada fase afetada.
