# Ponto de retomada — Bíblia Diária

**Última atualização:** 2026-11-05
**Branch:** `master` — HEAD `78a64f8` (voz de leitura pt-BR)

Este arquivo é o "salvar e continuar depois": descreve onde o projeto parou e
como retomar. Ele pode ser apagado quando a feature 002 for concluída e commitada.

---

## 1. O que foi feito na última sessão

- **Feature 002 commitada** (`fffe5a6`): `feat(estudos): recursos de estudo do texto bíblico` (40 arquivos).
- **Caso C6 da feature 001 corrigido** — a aba Bíblia (`_montarTelaLeitura`/
  `_conteudoLivroWidgets` em `lib/main.dart`) montava todos os capítulos/versículos
  de um livro **num único frame** (`Column` não-lazy + `maintainState: true`);
  Salmos chegava a ~2.400 `ListTile` vivos → travamento. Troquei por **linhas planas
  e lazy** (`ListView.builder` + estado `_livrosExpandidos`): cada versículo só monta
  quando entra na viewport. O C6 passou de travar (~10 min) para **~54 s**;
  `test/estresse_c6_test.dart` ganhou uma rolagem para revelar o conteúdo lazy do
  último livro (Apocalipse).
- **Fechada a Fase 4 da feature 002** (T013–T016) e **corrigido o teste C4**.
- **Fechadas as pendências da feature 001 (T014+)** — commit `ccd2687`: casos
  **C5** (retry), **E6/E7** (números inválidos), **E15** (estresse Salvos),
  **C7** (troca de aba), **C8** (rotação), **C12** (retomada TTS), **E11/E12**
  (referência 4 dígitos + capítulo gigante) e **B10** (anti-fraude Pix).
  Novos testes: `troca_aba_c7`, `tts_retomada_c12`, `rotacao_c8` + extensões.
- **Feature 001 concluída (menos bloqueios)** — commit `601ad5a`: T008/T009
  (fase fundacional), T016 (C4), T019 (E14/B11), T023–T026 (TTS/tema/fonte),
  T028/T029 (Pix), T031/T032 (banner), T034/T035 (matriz/contratos) e
  T039 (dart format). Restam só **T037/T038** (bloqueados: conta AdMob / SDK).
- **Validação final:** `flutter analyze lib test` → "No issues found!";
  `flutter test` → **94 testes verdes**, em ~2 min.

- **Sessão seguinte (pipeline, publicação e evolução da 002):**
  - **CI/CD**: `.github/workflows/ci.yml` — `flutter analyze` + `flutter test` em
    cada push/PR (GitHub Actions, `subosito/flutter-action@v2`).
  - **Publicação (preparação)**: assinatura de release em
    `android/app/build.gradle.kts` (lê `android/key.properties`), modelo
    `android/key.properties.example`, roteiro `docs/PUBLISHING.md` e exclusões de
    chave no `.gitignore`. **T037/T038 seguem bloqueadas** (conta AdMob + SDK +
    keystore).
  - **Acessibilidade/UX**: `test/acessibilidade_semantics_test.dart` (Semantics da
    chave Pix) + grade de resoluções já coberta (B12).
  - **Evolução da 002 — US4**: busca por palavra-chave (`filtrarPorBusca` em
    `lib/catalogo_estudos.dart` + campo na aba Estudos) + caso **EST7** + testes.
  - **Docs**: `contracts/module-apis.md` (módulos da 002: catálogo, cache, painel)
    e `contracts/platform.md` (C12/E12) atualizados.

---

## 2. Como rodar o Flutter (não está no PATH desta sessão)

O SDK está em:

```
C:\Users\Keynes\.puro\envs\stable\flutter\bin\flutter.bat
```

Use o caminho completo, por exemplo:

```powershell
& "$env:USERPROFILE\.puro\envs\stable\flutter\bin\flutter.bat" analyze lib test
& "$env:USERPROFILE\.puro\envs\stable\flutter\bin\flutter.bat" test test/catalogo_estudos_test.dart
```

> Observação: a **suíte completa** `flutter test` passa de 2 minutos (o caso C6
> tem `timeout` de 10 min). Em sessões curtas prefira rodar por arquivo ou em
> segundo plano.

---

## 3. Estado atual do projeto

### Arquivos novos (feature 002 — Recursos de Estudo)

- `lib/catalogo_estudos.dart` — lógica pura (modelo, parsing, casamento, filtros)
- `lib/cache_estudos.dart` — cache sob demanda (deduplicação + retry)
- `lib/widgets/painel_estudos.dart` — painel reutilizável
- `assets/data/estudos_indice.json` + `assets/data/estudos/*.json`
  (6 livros: Gênesis, Êxodo, Salmos, Mateus, João, Apocalipse)
- `test/catalogo_estudos_test.dart` — casos EST1–EST6
- `test/estresse_c6_test.dart` — caso C6 (teste real, completo)
- `test/robustez_e16_test.dart` — caso E16
- `specs/002-recursos-de-estudo/` — spec, plan, tasks, data-model, quickstart, contracts

### Arquivos modificados (não commitados)

- `lib/main.dart` — aba "Estudos", indicador na leitura, painel, salvos e TTS do recurso
- `lib/dados_seguros.dart` — guardiões E16 (`mapasSeguros`, `textoDeVersiculoEmLivros`, `textoDeCapituloEmLivros`)
- `pubspec.yaml` — assets `assets/data/estudos/`
- `tool/QA_EDGE_CASES.md` — matriz restaurada + casos EST1–EST6
- `specs/001-biblia-diaria-baseline/contracts/storage.md` + `data-model.md` — chave `favoritos_estudos`
- `README.md` — passo de adicionar recursos de estudo
- `test/concurrency_c4_test.dart` — mensagem de estado vazio atualizada
- `test/estresse_e15_test.dart`, `test/limites_dados_test.dart`, `test/virada_dia_b4_test.dart`

---

## 4. Onde parou — o que ainda FALTA

### Feature 002 — Fase 4 (Documentação e Qualidade)

- [x] **T013–T016** concluídos; feature 002 **commitada** (`fffe5a6`).
- [x] **C6** (feature 001) **corrigido**: lista lazy + teste ajustado; suíte 75/75 verde.

### Feature 001 — Validação/hardening

Ver `specs/001-biblia-diaria-baseline/tasks.md`. **Concluída** (commit `601ad5a`),
exceto os bloqueios externos **T037** (conta AdMob → trocar IDs de teste) e
**T038** (Android SDK → gerar `appbundle`), que ficam explícitos e bloqueados.

---

## 5. Como continuar (passo a passo)

1. **Release**: resolver os bloqueios externos — T037 (trocar IDs de anúncio de
   teste pelos reais após criar a conta AdMob) e T038 (gerar `flutter build
   appbundle` com o Android SDK instalado).
2. A feature 001 está validada e verde (88 testes + analyze limpo); a feature 002
   está commitada (`fffe5a6`).

---

## 6. Rascunhos na raiz que podem ser limpos depois (opcional)

Estes arquivos não fazem parte do app nem da suíte de testes e geram ~5.900
"infos" no `flutter analyze` global (por isso analise com `analyze lib test`):

- `test_cfe_check.dart`, `test_hybrid_filesystem.dart`, `test_link_check.dart`,
  `test_prova_final.dart`, `test_resolution.dart`, `test_uribase.dart`
- `dom_check.html`, `web_build_log.txt`
- `fix_puro_symlink.ps1`, `materialize_sdk.ps1`
- `meu-novo-projeto/` (projeto separado)

> Não foram removidos por não terem sido pedidos; trate-os numa limpeza dedicada.

---

## 7. Base de dados histórica (Theographic) — ponto de retomada

**Status:** pipeline **construído e validado** (banco SQLite gerado e conferido
contra o repositório aberto), **consultas de demonstração conferidas** e
**integração ao porte web concluída** (aba Bíblia → botão 🔎 Cruzamentos).

### O que foi feito

- `webapp/core/metadados_biblia.py` — módulo **puro** (só stdlib: `sqlite3`,
  `json`, `os`, `unicodedata`) com o schema normalizado, a construção do banco
  e as funções de cruzamento (versículo ↔ pessoas/lugares/eventos/grupos).
- `tool/construir_metadados.py` — CLI que baixa os JSONs brutos de
  `robertrouse/theographic-bible-metadata` (cache em `tool/theographic/raw/`),
  popula `tool/theographic/biblia_metadados.db`, cria os índices pedidos
  (`idx_verse_metadata_ref`, `idx_verse_people_verse`, `idx_verse_places_verse`)
  + índices de apoio, e consulta (`--consulta`, `--pessoa`, `--lugar`,
  `--cronologia`, `--resumo`).
- `webapp/tests/test_metadados_biblia.py` — **9 testes** das funções puras (verdes).
- `.gitignore` — `tool/theographic/` (gerado, não versionado).
- `webapp/core/cruzamentos.py` — fachada fina para o app (localiza o banco,
  consulta por referência e degrada graciosamente sem ele).
- `webapp/ui/painel_cruzamentos.py` — painel de exibição (pessoas/lugares/
  eventos/grupos) com crédito da fonte.
- `webapp/ui/aba_biblia.py` — botão **🔎 Cruzamentos** no versículo selecionado.
- `webapp/tests/test_cruzamentos.py` — 3 testes (agregação + degradação).

### Validação (já executada)

- `python tool/construir_metadados.py` →
  66 livros · 1189 capítulos · 31102 versículos · 3067 pessoas · 1298 lugares ·
  450 eventos · 23 grupos · 6519 easton.
  Junções: `verse_people` 28240 · `verse_places` 7534 · `verse_events` 17570.
  Saída: `[VERIFICAR] OK — contagens e cruzamentos de exemplo consistentes.`
- `python tool/construir_metadados.py --consulta "João 3:16"` →
  Pessoas: God, Jesus · Evento: "Jesus and Nicodemus" (27 d.C.).

### Validação (consultas restantes — conferidas em 2026-11-05)

- `--consulta "Gênesis 2:8"` → Pessoas: God · Lugares: Eden · Evento: "Creation of Adam and Eve".
- `--pessoa "David"` → 896 versículos citados (mostra os 50 primeiros).
- `--lugar "Jerusalem"` → 754 versículos citados (mostra os 50 primeiros).
- `--cronologia 6` → Creation → "God curses Cain" (4004–3875 a.C.).
- `python -m pytest webapp/tests/` → **85 testes verdes** (inclui 3 novos de
  cruzamentos).

### Como continuar (próximos passos)

1. (Opcional) Portar o cruzamento para o app Flutter (hoje usa JSON, sem
   SQLite; exigiria embutir o banco ou pré-gerar JSON por versículo).

