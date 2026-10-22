# Tarefas — Experiência de Leitura Visual

- [x] T001 — Baixar Lora (Regular/Italic/SemiBold) + OFL em `assets/fonts/` e declarar `fonts:` no `pubspec.yaml`.
- [x] T002 — Criar `lib/tema.dart` (`construirTema`, `escalaDeTexto`, `razaoContraste`, estilos serifados).
- [x] T003 — `main.dart`: delegar tema, compor escala com o sistema (teto 2.0).
- [x] T004 — Criar `lib/widgets/cartao_versiculo_dia.dart` e consumir em `_montarTelaInicio`.
- [x] T005 — Redesenhar `_linhaVersiculo` (serifada) + `_abrirAcoesVersiculo` + `_copiarVersiculo`.
- [x] T006 — Modo foco: `CustomScrollView` + `SliverAppBar` + `_aoRolar` + nav/FAB reativos.
- [x] T007 — Aplicar `estiloCorpoEstudo` em `painel_estudos.dart` e `painel_contexto_historico.dart`.
- [x] T008 — Atualizar 8 testes existentes (rótulos curtos, folha de ações, `CustomScrollView`).
- [x] T009 — Criar `test/tema_test.dart`, `test/tipografia_test.dart`.
- [x] T010 — Criar `test/acoes_versiculo_widget_test.dart`, `test/modo_foco_leitura_test.dart`, `test/alvos_toque_test.dart`.
- [x] T011 — Registrar casos U1–U6 em `tool/QA_EDGE_CASES.md`.
- [x] T012 — `flutter analyze` (sem issues) + `flutter test` (152 verdes).

## Notas

- `webapp/` (Streamlit) e `lib/widgets/tela_contexto_historico.dart` ficam fora do
  escopo desta feature (o webapp usa CSS próprio; a tela de contexto já herda os
  estilos dos painéis).
- Regeneração do ícone do launcher (`tool/gerar_icone.py`, ainda índigo) fica como
  follow-up opcional de branding, fora desta feature.
