<!--
  Sync Impact Report (plan)
  - Creates the implementation plan for feature 002-recursos-de-estudo.
  - Stack: Flutter (Dart) — per constitution v1.0.0 (Constraints Técnicas).
  - All Technical Context fields resolved; no NEEDS CLARIFICATION remains.
  - Constitution Check passes before Phase 0 and after Phase 1 (no violations).
-->

# Implementation Plan: Recursos de Estudo do Texto Bíblico

**Branch**: `002-recursos-de-estudo` | **Date**: 2026-09-03 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-recursos-de-estudo/spec.md`

## Summary

Enriquecer a leitura bíblica com **recursos de estudo** — notas de rodapé,
comentários, artigos, sermões, palestras e momentos históricos — disponíveis
**offline** e acessíveis tanto no ponto da leitura (painel por referência) quanto
em uma **seção própria "Estudos"** com filtros por tipo e por livro. O conteúdo é
**texto curado embutido no app** (FR-011), como um **conjunto inicial curado**
expansível por edição de dados (FR-012). Técnica e estruturalmente, a feature
espelha o padrão já consagrado da linha de base: **índice leve em assets +
detalhe carregado sob demanda com cache e retry**, **lógica pura em módulos
`lib/` testáveis**, **widget reutilizável** para o painel e **persistência local
last-write-wins** para os recursos salvos.

## Technical Context

**Language/Version**: Dart + Flutter (constraint em `pubspec.yaml`: SDK
`>=3.0.0 <4.0.0`; env Puro `stable`, Flutter 3.47.1 / Dart 3.13.1).

**Primary Dependencies**: reutiliza apenas as já existentes — `flutter`
(Material 3), `shared_preferences` (salvos), `intl`, `flutter_tts` (ouvir),
`google_mobile_ads`, `cupertino_icons`. **Nenhuma dependência nova** (constituição
— Constraints Técnicas).

**Storage**: conteúdo de estudo em assets JSON — índice leve
(`assets/data/estudos_indice.json`) + detalhe por livro
(`assets/data/estudos/<nome>.json`), carregado sob demanda; recursos salvos em
armazenamento chave-valor local (nova chave `favoritos_estudos`), com fila de
escrita serializada; cache de estudos em memória com deduplicação e retry.

**Testing**: `flutter_test` + `flutter_lints`. Testes unitários para o módulo
puro (`lib/catalogo_estudos.dart`) referenciando os casos novos da matriz de QA
(`tool/QA_EDGE_CASES.md`: `EST1`…`EST6`); testes de widget com um único
`testWidgets` por arquivo quando carregam assets. Meta: `flutter analyze` sem
novas issues e `flutter test` verde.

**Target Platform**: Android (principal), web e Windows (desenvolvimento); iOS
fora de escopo imediato.

**Project Type**: mobile-app Flutter (multiplataforma), projeto único.

**Performance Goals**: abrir os recursos de um trecho de forma perceptivelmente
imediata; jamais carregar a base de estudos inteira de uma vez; navegação fluida
(60 fps) mesmo com centenas/milhares de recursos; leitura nunca bloqueada pelo
carregamento dos estudos.

**Constraints**: 100% offline; dados externos tratados defensivamente (sem casts
inseguros); degradação graciosa de voz; 320 px × 1.18 sem overflow; `setState`
guardado por `mounted`; determinismo do conjunto/ordem de recursos por referência;
pt-BR em UI/comentários/testes; aderência à constituição v1.0.0.

**Scale/Scope**: conjunto inicial curado de recursos distribuído por alguns
livros (ex.: Gênesis, Êxodo, Salmos, João, Mateus, Apocalipse); estrutura pronta
para crescer a milhares de recursos sem mudança de código. Uma nova aba/seção
("Estudos") + painel reutilizável + indicador na leitura.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Código limpo/componentização**: modelagem, parsing e casamento
  referência↔recurso em módulo **puro** (`lib/catalogo_estudos.dart`); painel em
  **widget reutilizável** (`lib/widgets/painel_estudos.dart`) usado em dois pontos
  (bottom sheet da leitura e biblioteca). → **PASS**.
- **II. Offline-first e dados não confiáveis**: assets de estudo tratados por
  guardiões (mapas seguros, tipos tolerantes); carregamento sob demanda com cache
  + retry; determinismo por referência. → **PASS**.
- **III. Tolerância a falhas / UX idoso**: fallback amigável para ausência/
  corrupção; TTS manual e não contínuo reaproveitado; legibilidade e alvos de
  toque generosos. → **PASS**.
- **IV. Estado explícito e serializado**: `StatefulWidget` + `setState`; novos
  salvos em fila last-write-wins (`favoritos_estudos`); `mounted` após `await`;
  loader injetável no cache (testável). → **PASS**.
- **V. Testes (matriz QA)**: novos casos `EST1`…`EST6` na matriz + testes
  unitários do módulo puro; `flutter analyze`/`flutter test` como gate. → **PASS**.
- **Constraints Técnicas**: stack Flutter fixa; zero dependências novas;
  monetização inalterada. → **PASS**.

Re-check pós-design (Phase 1): nenhuma violação introduzida — Complexity Tracking
permanece vazia.

## Project Structure

### Documentation (this feature)

```text
specs/002-recursos-de-estudo/
├── plan.md              # This file (/speckit-plan command output)
├── spec.md              # Feature specification
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (delta dos contratos)
│   └── estudos.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── main.dart                     # Orquestração UI/estado (indicador, painel, aba Estudos, salvos, TTS)
├── catalogo_estudos.dart         # NOVO — modelo + parsing + casamento + filtros (funções puras)
├── cache_estudos.dart            # NOVO — cache sob demanda com deduplicação e retry
├── dados_seguros.dart            # (reuso de guardiões)
├── leitura_natural.dart          # (reuso para TTS do recurso)
├── cache_livros.dart             # (padrão espelhado)
├── platform_support.dart         # (gate de TTS)
└── widgets/
    ├── banner_anuncio.dart       # (existente)
    └── painel_estudos.dart       # NOVO — painel reutilizável de recursos

assets/data/
├── estudos_indice.json           # NOVO — índice leve (id, tipo, titulo, ref, livro)
└── estudos/<nome>.json           # NOVO — detalhe por livro (corpo, tema, fonte)

test/
├── catalogo_estudos_test.dart    # NOVO — unitário do módulo puro (EST1–EST6)
└── (demais testes existentes preservados)

tool/
└── QA_EDGE_CASES.md              # Atualizar com casos EST1–EST6
```

**Structure Decision**: projeto único Flutter (padrão). Mantém a separação atual:
regra pura/testável em `lib/*.dart`; widget com reuso real em `lib/widgets/`;
`lib/main.dart` apenas orquestra UI/estado. Nenhuma camada de service/DI, nenhuma
dependência nova.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

Nenhuma violação do Constitution Check — nenhuma justificativa necessária.
