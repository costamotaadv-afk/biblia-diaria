<!--
  Sync Impact Report (tasks)
  - Creates the Phase 2 task list for feature 001-biblia-diaria-baseline
    (/speckit-tasks command output).
  - Nature: the feature code already exists and is green; tasks are therefore
    tests-first VALIDATION & HARDENING of the current code end-to-end, closing
    the open cases of tool/QA_EDGE_CASES.md and the contract/architecture
    conformance audits — not net-new screens or features.
  - Constitution Check: tasks honor gates I–V (pure logic in lib/, tests
    referencing QA cases, matrix updated per change, analyze+test green).
-->

# Tasks: Bíblia Diária — Validação e Refino da Linha de Base (Pontas a Ponta)

**Input**: Design documents from `specs/001-biblia-diaria-baseline/`

**Prerequisites**: [spec.md](spec.md) (user stories US1–US8 e FR-001…FR-016),
[plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md),
contratos (`contracts/README.md`, `module-apis.md`, `storage.md`,
`platform.md`), [quickstart.md](quickstart.md), matriz
`tool/QA_EDGE_CASES.md` e constituição `.specify/memory/constitution.md`
(v1.0.0).

**Tests**: os testes são parte obrigatória deste feature (validação). Cada
tarefa segue TDD: escrever o teste que referencia o caso da matriz, ver vermelho
(ou confirmar a lacuna), implementar o refino, ver verde, atualizar matriz e
contratos.

**Organization**: tarefas agrupadas por user story para permitir validação
independente de cada história, precedidas de uma fase de ambiente/contratos
(fundacional). Escopo do feature = linha de base existente: **nenhuma tela ou
feature nova**.

**Escopo do refino (lacunas conhecidas da matriz a fechar)**:

| Lacuna | O que falta | Tarefa |
| :--- | :--- | :--- |
| E16 (novo) | Crash latente: favorito resolve capítulo/versículo não-mapeável dentro de lista (`as Map` em `_buscarTextoVersiculo`/`_buscarTextoCapitulo`) | T007 |
| C6 | Estresse: expandir os 66 livros (memória/estado) | T013 |
| C7 | Guard `mounted` ao trocar de aba durante carregamento — sem teste de regressão | T018 |
| C8 | Rotação/tamanho durante TTS + banner — sem teste | T030 |
| C12 | Retomada com `_tts.speak('')` pode derrubar o TTS da sessão inteira | T022 |
| E11 | Referência cruzada malformada de 4 dígitos ("Salmos 1190:12") sem teste/decisão | T020 |
| E12 | Capítulo gigante (Salmos 119) pode ser truncado pelo engine | T021 |
| B10 | Aviso anti-fraude implementado mas sem teste de regressão | T027 |
| Grid de telas/escalas | Overflow só testado em 320 px × 1.18 | T026 |

## Formato

- `[ID] [P?] [Story] Descrição`
- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência).
- **[Story]**: user story correspondente (US1…US8 da spec).
- Caminhos de arquivo exatos do repositório único (raiz do projeto Flutter).

---

## Phase 1: Baseline e Ambiente (Setup)

**Purpose**: reproduzir o estado atual e registrar a linha de base antes de
qualquer refino.

- [x] T001 [P] [US8] Rodar `flutter analyze` e registrar o baseline: zero
      issues novas em `lib/`, `test/` (sem correção nesta fase). — Executado:
      apenas 87 infos pré-existentes em arquivos de diagnóstico na raiz; zero
      em `lib/`/`test/`.
- [x] T002 [P] [US8] Rodar `flutter test` completo e registrar a contagem de
      testes verdes; conferir que os casos marcados como "Coberto" na matriz
      passam (SC-007). — Executado: 58/58 na baseline; 60/60 após E16.
- [ ] T003 [P] [US8] Executar o roteiro manual do `quickstart.md` em `-d
      windows` e `-d chrome`; anotar divergências (TTS desabilitado na web é
      esperado — C11). — PARCIAL: tentativas registradas; **bloqueado por
      ambiente**: Windows desktop sem Visual Studio toolchain; `flutter run`
      web no Windows falha por bug do frontend server (dartdevc +
      `--initialize-from-dill`); `flutter build web` (release) VALIDADO
      (HTTP 200 + bootstrap). Walkthrough interativo final fica para humano
      quando o toolchain for resolvido.

**Checkpoint**: baseline conhecido; qualquer divergência vira débito
explicitado nas fases seguintes (nunca silencioso — constituição).

---

## Phase 2: Fundacional — Conformidade com Contratos e Constituição

**Purpose**: os contratos (`contracts/`) são a fronteira estável; validar o
código contra eles e fechar riscos de crash latente antes das validações por
user story.

**CRITICAL**: nenhuma validação por história começa antes desta fase concluir.

- [x] T004 [US8] Auditoria de conformidade com `contracts/storage.md`: confirmar
      que `lib/main.dart`/`lib/config.dart` leem e gravam somente as chaves
      documentadas (`favoritos_versiculos`, `favoritos_capitulos`, `tema_escuro`,
      `fonte_grande`, `voz_tts_id`) com os tipos/padrões da tabela; corrigir
      desvios encontrados e ajustar testes que referenciarem o caso.
      — CONFORME: único acesso a prefs em `lib/main.dart`; 5 chaves oficiais,
      tipos e padrões idênticos à tabela de `storage.md`.
- [x] T005 [P] [US8] Auditoria de conformidade com `contracts/module-apis.md`:
      assinaturas públicas de `lib/dados_seguros.dart`, `lib/config.dart`,
      `lib/leitura_natural.dart`, `lib/cache_livros.dart` e
      `lib/platform_support.dart` presentes e com o comportamento documentado
      (mesmo input → mesmo output); registrar aderência ou desvio.
      — Desvio corrigido: `BannerAnuncio` documentado como `StatelessWidget`,
      implementação é `StatefulWidget`; contrato atualizado + funções E16
      documentadas. Demais módulos CONFORMES.
- [x] T006 [P] [US8] Auditoria de conformidade com `contracts/platform.md`: todos
      os pontos de ativação de voz e anúncios (Início, Bíblia, Salvos, Ajustes,
      `BannerAnuncio`) respeitam os gates `suportaTts`/`suportaAdMob` e os
      try/catch de degradação; corrigir ativação fora de gate se houver.
      — CONFORME: gate `suportaTts` + `_ttsDisponivel` desabilitam botões
      (C11/B1); banner com try/catch em `load()`/tamanho (C9/C10/B8); Pix com
      try/catch + aviso anti-fraude (B2/B10).
- [x] T007 [US3] Caso **E16** (novo, registrado na matriz): teste vermelho em
      `test/robustez_e16_test.dart`; guardiões puros `mapasSeguros`,
      `textoDeVersiculoEmLivros`, `textoDeCapituloEmLivros` adicionados em
      `lib/dados_seguros.dart` e delegados em `_buscarTextoVersiculo`/
      `_buscarTextoCapitulo` de `lib/main.dart` (sem cast direto `as Map`;
      ausência → null → UI mostra "Conteúdo não encontrado.").
- [ ] T008 [US2] Substituir os casts diretos restantes de dados externos em
      `lib/main.dart` pelo guardião `comoLista` (ex.: parsing do `indice.json`
      com `as List`) — constituição II, consistente com `dados_seguros.dart`;
      manter testes E1–E9 verdes.
- [ ] T009 [US8] Varredura de constituição I: confirmar que nenhuma regra de
      negócio/parsing vive dentro de widget (`lib/widgets/` e trechos de
      `lib/main.dart`); extrair para `lib/` qualquer regra testável que ainda
      esteja na árvore de UI.

**Checkpoint**: contratos sem desvio e risco de crash latente fechado — as
validações por história podem começar.

---

## Phase 3: User Story 1 — Versículo do Dia (Priority: P1) — Validar

**Goal**: determinismo (mesma data → mesmo conteúdo), fallbacks amigáveis e
virada do dia com app aberto.

**Independent Test**: abrir sem rede em datas distintas; na mesma data o
conteúdo é idêntico; relógio injetável cruza a meia-noite e o conteúdo muda.


- [x] T010 [P] [US1] Revisar `test/limites_dados_test.dart`/`test/dados_biblicos_test.dart`
      para os casos E1–E9, E13 e B5; preencher lacunas de entrada (ex.: livro do
      dia com capítulo como objeto — E3 no fluxo da Home) com testes que


      referenciem o caso. — Revisão: cobertura E1–E5/E8/E9/E13/B5 já existia;
      adicionado `T010/E3: capítulo SORTEADO do dia não-Map → fallback` em
      `test/limites_dados_test.dart`.
- [x] T011 [P] [US1] Estender `test/virada_dia_b4_test.dart`: após a meia-noite o
      próximo `build`/interação recalcula o conteúdo (B4) e o `setState`


      posterior ao `_cacheLivros.assegurar` respeita `mounted`. — Extensão com
      2ª virada (dia 2 → Levítico 1:1) SEM sair do Início: rolagem + toque em
      "Salvar versículo" disparam o rebuild; `takeException` null (guard
      `mounted` exercitado no carregamento sob demanda).
- [x] T012 [US1] Validar o fluxo diário quando o capítulo sorteado tem
      `versiculos` vazio (E4): `selecionarVersiculoDoDia` em
      `lib/dados_seguros.dart` retorna fallback `"Sem conteúdo bíblico
      disponível."` e os botões "Ouvir"/"Salvar" ficam desabilitados; ajustar se

      houver regressão no caso de livro já carregado no cache. — Adicionado
      `T012/E4: capítulo sorteado (≠1º) com versículos vazios → fallback +
      referência '' (botões desabilitados)`; sem regressão.

**Checkpoint**: US1 validada — determinística, sem crash e com fallback
correto.

---

## Phase 4: User Story 2 — Bíblia Completa Offline (Priority: P1) — Validar

**Goal**: 66 livros navegáveis sob demanda, sem travar, com conteúdo corrompido
tratado graciosamente.

**Independent Test**: expandir livros com prefixo numérico/composto e abrir
capítulos em sequência sem rede.

- [x] T013 [US2] Caso **C6**: criar `test/estresse_c6_test.dart` (um único
      `testWidgets` — regra do `runAsync`) que expande os 66 livros com os
      assets reais de forma sequencial, percorre versículos e rola a lista, sem
      exceção nem estado preso; atualizar a matriz C6 → Coberto. **Feito**:
      teste criado e lista de livros tornada lazy (`lib/main.dart`) — C6 passou
      de travar (~10 min) para ~54 s.
- [ ] T014 [P] [US2] Estender `test/cache_livros_test.dart` (C5): falha
      transiente durante navegação entre livros (não só no primeiro acesso) e
      deduplicação de futuros concorrentes ao expandir abas em sequência rápida.
- [ ] T015 [P] [US2] Blindar a montagem de chave de capítulo/versículo em
      `_conteudoLivroWidgets` (`lib/main.dart`) contra `numero` inválido
      (E6/E7): número ausente/`"abc"`/`>999` não gera crash nem TTS absurdo;
      adicionar cobertura em `test/limites_dados_test.dart`/`test/edge_cases_e10_test.dart`.

**Checkpoint**: US2 validada — conteúdo sob demanda, resiliente e sem OOM.

---

## Phase 5: User Story 3 — Favoritos (Priority: P1) — Validar

**Goal**: favoritos persistentes entre sessões, seguros sob toques rápidos,
órfãos tratados.

**Independent Test**: salvar/remover com reinício simulado e 200+ itens.

- [ ] T016 [P] [US3] Estender `test/concurrency_c4_test.dart` (C4): duplo-toque
      em "salvar capítulo" e alternância rápida versículo↔capítulo — fila
      serializada last-write-wins por chave; estado final em disco igual ao da
      memória após reinício simulado.
- [ ] T017 [P] [US3] Estender `test/estresse_e15_test.dart` (E15): carga mista
      (capítulos + versículos, 200+ itens), ordenação lexicográfica e remoção no
      meio da lista sem perda nem jank.
- [ ] T018 [P] [US3] Caso **C7**: teste de troca de aba durante carregamento —
      mock de carregamento lento (`rootBundle` sem completar) + navegação
      Bíblia→Salvos antes do `FutureBuilder` resolver; assert de ausência de
- [ ] T019 [US3] Confirmar E14 (favorito órfão → `"Conteúdo não encontrado."`)
      e B11 (prefixos numéricos/"1 João 3") com cobertura em `test/widget_test.dart`
      ou `test/limites_dados_test.dart`; preencher lacunas se houver.

**Checkpoint**: US3 validada — zero perda de favorito em qualquer cenário.

---

## Phase 6: User Story 4 — Leitura em Voz Alta (Priority: P1) — Validar/Refinar

**Goal**: leitura manual e não contínua, correta (prefixos numéricos, capítulos
gigantes) e resiliente a falhas de engine/plataforma.

**Independent Test**: voz pt-BR lendo versículo e capítulo com pausa/continuação;
plataforma sem TTS mostra botões desabilitados.

- [ ] T020 [P] [US4] Caso **E11**: ampliar `test/edge_cases_e10_test.dart` para
      referência cruzada malformada com 4 dígitos (`"Salmos 1190:12"`); decidir e
      documentar na matriz o comportamento esperado de `textoParaLeituraNatural`
      em `lib/leitura_natural.dart` (ler literalmente sem soar como horário, sem
      crash, sem engolir prefixo de `"1 Co 2:3"`); ajustar a função se a saída
      ficar incoerente.
- [ ] T021 [P] [US4] Caso **E12**: extrair função pura de divisão de fala em
      `lib/leitura_natural.dart` (ex.: `dividirTextoParaFala(String, {int
      maxCaracteres})` — corta em pontuação, não quebra palavras) com testes
      unitários usando o texto real de Salmos 119 (~4.000 caracteres); aplicar
      em `_iniciarLeitura`/`_falarCapitulo` de `lib/main.dart` com fala
      sequencial por segmento (um áudio por vez; o trecho continua manual e não
      contínuo); atualizar matriz E12 → Coberto.
- [ ] T022 [P] [US4] Caso **C12**: teste em `test/tts_concorrencia_test.dart`
      com mock que lança erro em `_tts.speak('')` ao retomar; refinar
      `_alternarPlayPause` (`lib/main.dart`) para que a falha de retomada
      encerre o trecho com aviso e volte ao estado ocioso — sem derrubar
      `_ttsDisponivel` para a sessão inteira (rever nota de `contracts/platform.md`);
      atualizar matriz C12 → Coberto.
- [ ] T023 [US4] Revisar a máquina de estados `_falando/_pausado/_leituraAtiva`
      e os handlers (start/completion/cancel/pause/continue) em `lib/main.dart`
      para C1/C3: um único áudio e `stop` antes de novo trecho; estender
      `test/tts_concorrencia_test.dart` para "iniciar capítulo durante versículo"
      se a cobertura atual não exercitar C3.
- [ ] T024 [US4] Estender `test/tts_qualidade_test.dart` (B6/B7): seleção manual
      por gênero (masculina/feminina), reescrita de `voz_tts_id` quando a voz
      salva é removida e persistência da escolha.

**Checkpoint**: US4 validada — voz correta e resiliente em todas as
plataformas suportadas.

---

## Phase 7: User Story 5 — Tema e Fonte (Priority: P2) — Validar

**Goal**: preferências persistidas e layout sem overflow para o público idoso.

**Independent Test**: alternar tema/fonte, reiniciar e percorrer as abas em tela
estreita com fonte grande.

- [ ] T025 [P] [US5] Revisar em `test/widget_test.dart` a persistência de
      `tema_escuro`/`fonte_grande` com reinício simulado (aplicar → reiniciar →
      conferir valor lido) — FR-011.
- [ ] T026 [P] [US5] Estender `test/overflow_b12_test.dart` (B12) para grade de
      telas 320/360/411 px × escalas 1.0, 1.18 e 2.0 nas 4 abas com texto longo
      (Salmos 119:176); sem overflow nem texto cortado (SC-006).

**Checkpoint**: US5 validada — preferências persistem e layout não estoura.

---

## Phase 8: User Story 6 — Doação via Pix (Priority: P2) — Validar

**Goal**: chave copiável com feedback claro, instruções numeradas e aviso
anti-fraude.

**Independent Test**: copiar com sucesso e com permissão negada; conferir aviso
de verificação do recebedor.

- [ ] T027 [P] [US6] Caso **B10**: teste de regressão de texto/Semantics
      (novo arquivo ou `test/widget_test.dart`) garantindo que a aba Ajustes
      exibe o aviso "confira no banco o nome de quem receberá" e que o rótulo
      Semantics da chave Pix está presente; atualizar matriz B10 → Coberto.
- [ ] T028 [P] [US6] Estender `test/clipboard_b2_test.dart` (B2): falha e sucesso
      da cópia também a partir do diálogo "Ver como fazer a doação" (segundo
      ponto de `Clipboard.setData` em `_mostrarComoDoar`), com feedback correto
      em cada caminho.
- [ ] T029 [US6] Confirmar cobertura de B3 (`chavePix`/`chavePixValida` em
      `test/config_negocio_test.dart`) e C13 (duplo-toque em copiar em
      `test/tts_concorrencia_test.dart`).

**Checkpoint**: US6 validada — doação resiliente e anti-fraude garantida.

---

## Phase 9: User Story 7 — Anúncios em Banner (Priority: P2) — Validar/Refinar

**Goal**: banner em Android/iOS com degradação graciosa (nunca bloqueia o app).

**Independent Test**: navegar entre abas em plataforma sem suporte → app estável,
sem anúncios e sem erro.

- [ ] T030 [P] [US7] Caso **C8**: teste (estender `test/banner_c9_test.dart` ou
      novo arquivo) simulando mudança de tamanho/orientação com leitura TTS
      ativa e banner carregado (canais mockados): sem exceção, banner recarregado
      com dispose do anterior e estado de TTS preservado; corrigir
      `lib/widgets/banner_anuncio.dart`/`lib/main.dart` se houver vazamento;
      atualizar matriz C8 → Coberto.
- [ ] T031 [P] [US7] Estender `test/banner_c9_test.dart` (C9): `load()` do banner
      que nunca completa (timeout) — sem estado preso nem exceção assíncrona.
- [ ] T032 [US7] Confirmar C10 (`inicializarAdMob` sem GMS → nunca lança) em
      `test/platform_c10_c11_test.dart` e B8 (ID de teste bloqueado em release)
      em `test/config_negocio_test.dart`.

**Checkpoint**: US7 validada — banner nunca impede o uso do app.

---

## Phase 10: User Story 8 — Estrutura para Evolução e Publicação (P3)

**Purpose**: fechar o ciclo — documentação, matriz, contratos e release
readiness.

- [ ] T033 [P] [US8] Executar o roteiro completo do `quickstart.md` (validação
      manual + suíte automatizada) após os refinamentos das fases anteriores;
      registrar resultado por FR-001…FR-016 e divergências.
- [ ] T034 [US8] Atualizar `tool/QA_EDGE_CASES.md`: status de C6, C7, C8, C12,
      E11, E12, B10 → Coberto, inclusão do caso E16 e atualização do resumo de
      prioridade e da lista de cobertura automatizada.
- [ ] T035 [P] [US8] Atualizar `contracts/module-apis.md`, `contracts/storage.md`,
      `contracts/platform.md` e `data-model.md` com as mudanças de assinatura,
      chave ou estado introduzidas (ex.: `dividirTextoParaFala`, comportamento de
      retomada do TTS, caso E16 na resolução de favoritos).
- [ ] T036 [P] [US8] Rodada final de qualidade: `flutter analyze` e `flutter
      test` 100% verdes; conferir que todos os casos marcados como Coberto na
      matriz passam (SC-007).
- [ ] T037 [US8] (Bloqueado externamente — conta AdMob) Trocar IDs de anúncio de
      teste pelos reais: `android/app/src/main/AndroidManifest.xml`
      (`APPLICATION_ID`) e `lib/widgets/banner_anuncio.dart` (`_bannerAdUnitId`);
      manter bloqueado até existir conta (B8/FR-015).
- [ ] T038 [P] [US8] (Bloqueado por ambiente — Android SDK não instalado) Gerar
      `flutter build appbundle` e conferir que nenhum ID de teste está no
      artefato final.
- [ ] T039 [P] [US8] Limpeza final: remover código morto/docstrings duplicados
      (ex.: comentários repetidos em `lib/main.dart`), garantir pt-BR e rodar
      `dart format`; commit por tarefa ou grupo lógico.

**Checkpoint**: feature fechada — código verde, matriz e contratos atualizados,
pronto para release quando os bloqueios externos forem resolvidos.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Baseline)**: sem dependências — pode começar imediatamente.
- **Phase 2 (Fundacional/Contratos)**: depende da Phase 1 — **bloqueia** todas
  as validações por user story.
- **Phases 3–9 (US1–US7)**: dependem da Phase 2 concluída; podem rodar em
  paralelo (equipes diferentes) ou em sequência de prioridade P1 → P2.
- **Phase 10 (US8/Publicação)**: depende de todas as fases anteriores.

### Ordem recomendada (equipe única)

Phase 1 → Phase 2 → US1 → US2 → US3 → US4 → US5 → US6 → US7 → Phase 10,
validando cada história com checkpoint antes de avançar (estratégia de entrega
incremental da spec).

### Dentro de cada história (regras)

- Teste primeiro (vermelho) referenciando o caso da matriz (ex.:
  `test/estresse_c6_test.dart` → C6); só então refinar o código.
- Depois de cada mudança: rodar os testes afetados e `flutter analyze`;
  atualizar a matriz (`tool/QA_EDGE_CASES.md`) e os contratos afetados na mesma
  tarefa ou na T035.
- Um arquivo de cada vez: tarefas marcadas [P] tocam arquivos diferentes; as
  demais são sequenciais (evitar conflito em `lib/main.dart`, que é tocado por
  T007, T008, T015, T021, T022 e T023 — em fases distintas, fora de paralelismo).
- Testes de UI que carregam assets: **um único `testWidgets` por arquivo**
  (regra do `runAsync` — ver `quickstart.md`).
- Commit após cada tarefa ou grupo lógico; nunca deixar matriz e código
  divergentes.

### Paralelismo [P] seguro

- Audits somente-leitura de arquivos distintos (T005/T006).
- Adições a arquivos de teste diferentes (ex.: T010/T011, T016/T017/T018).
- Tarefas de documentação independentes (T033, T035, T036, T038, T039).

---

## Notas

- [P] = arquivos diferentes, sem dependência; [Story] = rastreabilidade à user
  story da spec.
- Todas as tarefas preservam os gates da constituição v1.0.0: nenhuma regressão
  de acessibilidade (320 px × 1.18) nem de caso "Coberto" da matriz; lógica pura
  em `lib/`, widgets sem regra de negócio; mensagens e testes em pt-BR.
- Tarefas T037/T038 dependem de recursos externos (conta AdMob; Android SDK) e
  ficam **explícitas e bloqueadas**, não silenciosas (governança da constituição).
