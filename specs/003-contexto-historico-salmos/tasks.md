# Tasks: Contextualização Histórica dos 150 Salmos

## Phase 1 — Lógica pura e dados
- [x] T001 Criar `lib/contexto_historico.dart` (modelo, parsing, certeza, busca, análise de referência).
- [x] T002 Criar `lib/cache_contexto.dart` (`CacheDeContexto`).
- [x] T003 Autorar `assets/data/contexto/Salmos.json` (150 registros) e declarar em `pubspec.yaml`.
- [x] T004 Criar `tool/validar_contexto.py`.
- [x] T005 Criar `test/contexto_historico_test.dart` (CTX1–CTX7).

## Phase 2 — Widgets
- [x] T006 Criar `lib/widgets/painel_contexto_historico.dart`.
- [x] T007 Criar `lib/widgets/tela_contexto_historico.dart`.

## Phase 3 — Integração
- [x] T008 `main.dart`: cache + loader de contexto; botão "Contexto Histórico" no
  cabeçalho de Salmos; painel; TTS (`_falarContexto`); tela de busca na aba Estudos;
  navegação de referência cruzada (`_irParaReferencia`) com ancoragem.

## Phase 4 — Qualidade
- [x] T009 Atualizar `tool/QA_EDGE_CASES.md` (CTX1–CTX7) e `.specify/feature.json`.
- [x] T010 Rodar `flutter analyze lib test` (No issues) e testes verdes.

## Validação
- `flutter analyze lib test` → "No issues found!".
- `flutter test test/contexto_historico_test.dart` → 17 verdes.
- `flutter test test/widget_test.dart test/catalogo_estudos_test.dart test/platform_c10_c11_test.dart` → 24 verdes.
