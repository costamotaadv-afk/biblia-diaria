<!--
  Sync Impact Report (plan)
  - Creates the implementation plan for feature 001-biblia-diaria-baseline.
  - Stack: Flutter (Dart) — per user decision (Opção A) and constitution v1.0.0.
  - All Technical Context fields resolved; no NEEDS CLARIFICATION remains.
  - Constitution Check passes before Phase 0 and after Phase 1 (no violations).
-->

# Implementation Plan: Bíblia Diária — Linha de Base (Componentização, Persistência e Integrações)

**Branch**: `001-biblia-diaria-baseline` | **Date**: 2026-09-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-biblia-diaria-baseline/spec.md`

## Summary

O app Flutter Bíblia Diária entrega leitura diária offline, Bíblia completa
(66 livros), favoritos, leitura em voz alta, tema/fonte, doação Pix e banner de
anúncio. O escopo desta feature é a **linha de base estrutural**: organizar em
componentes a UI e a lógica pura, consolidar o modelo de persistência e
documentar as integrações de plataforma (voz, área de transferência e anúncios)
— preservando os critérios da spec (FR-001…FR-016) e as gates da constituição
v1.0.0. A abordagem técnica é a do próprio código existente: **um único projeto
Flutter**, lógica pura em módulos `lib/` testáveis, widgets reutilizáveis em
`lib/widgets/`, persistência local chave-valor e conteúdo em assets carregado
sob demanda.

## Technical Context

**Language/Version**: Dart + Flutter (constraint em `pubspec.yaml`: SDK
`>=3.0.0 <4.0.0`; env Puro `stable`).

**Primary Dependencies**: `flutter` (Material 3), `shared_preferences`
(persistência local), `intl` (datas/`pt_BR`), `flutter_tts` (voz),
`google_mobile_ads` (banner), `cupertino_icons`. Dev: `flutter_test`,
`flutter_lints`, `flutter_launcher_icons`. Nenhuma dependência nova sem
justificativa (constituição — Constraints Técnicas).

**Storage**: conteúdo bíblico imutável em assets JSON (`assets/data/indice.json`,
`assets/data/mensagens.json`, `assets/data/livros/<nome>.json`); favoritos e
preferências em armazenamento chave-valor local persistido; cache de livros em
memória (deduplicação de futuros + retry em falha transiente).

**Testing**: `flutter_test` + `flutter_lints`. Padrão da casa: testes unitários
para funções puras (sem widget), testes de widget para fluxos, um único
`testWidgets` por arquivo quando carrega assets (regra do `runAsync`), e cada
teste referenciando o caso da matriz de QA (`tool/QA_EDGE_CASES.md`).

**Target Platform**: Android (publicação principal), web e Windows (desenvolvimento
e validação); iOS exige Mac e está fora de escopo imediato.

**Project Type**: mobile-app Flutter (multiplataforma).

**Performance Goals**: abertura em poucos segundos em aparelho de entrada;
interação fluida (60 fps); conteúdo carregado sob demanda — nunca os ~13 MB da
Bíblia inteira de uma vez; telas de 320 px com fonte 1.18 sem overflow.

**Constraints**: 100% offline (sem rede); dependências mínimas; degradação
graciosa de plugins (voz/anúncios/clipboard); determinismo do versículo do dia;
pt-BR em UI/comentários/tests; chave Pix sempre um e-mail válido; nenhum ID de
anúncio de teste em release; `setState` sempre guardado por `mounted`; escritas
de persistência serializadas (last-write-wins).

**Scale/Scope**: conteúdo fixo (66 livros, ~31 mil versículos); favoritos típicos
< 200; público regional pt-BR; app de 4 abas em uma única tela raiz. Esta
feature documenta a linha de base; não adiciona telas nem features novas.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Gates derivadas da constituição v1.0.0 (`.specify/memory/constitution.md`):

- **I. Código limpo/componentização**: lógica de negócio fora de widgets, em
  módulos puros; widgets reutilizáveis só com uso real. → **PASS** (plano
  preserva `lib/*.dart` puros + `lib/widgets/`).
- **II. Offline-first e dados não confiáveis**: conteúdo em assets tratado por
  guardiões; cache com retry; determinismo do versículo. → **PASS**.
- **III. Tolerância a falhas / UX idoso**: `platform_support` declara
  capacidade; degradação graciosa; 320 px × 1.18 sem overflow; TTS manual
  não contínuo. → **PASS**.
- **IV. Estado explícito e serializado**: `StatefulWidget` + `setState`;
  escritas em fila last-write-wins; `mounted` em todo `await→setState`;
  relógio/cache injetáveis. → **PASS**.
- **V. Testes (matriz QA)**: toda mudança atualiza a matriz e cria teste
  referenciando o caso. → **PASS** (exigido nas tarefas de implementação).
- **Constraints Técnicas**: stack Flutter fixa; dependências mínimas;
  monetização segura (Pix/AdMob). → **PASS**.

Re-check pós-design (Phase 1): nenhuma violação introduzida; tabela de
Complexity Tracking permanece vazia.

## Project Structure

### Documentation (this feature)

```text
specs/001-biblia-diaria-baseline/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── main.dart                # Orquestração UI/estado (StatefulWidget + setState)
├── config.dart              # Regras puras: chave Pix válida, IDs de anúncio em release
├── dados_seguros.dart       # Guardiões de JSON + seleção determinística do dia
├── leitura_natural.dart     # Referência/texto → fala natural (TTS)
├── cache_livros.dart        # Cache sob demanda com deduplicação e retry
├── platform_support.dart    # Capacidades por plataforma (voz, anúncios)
└── widgets/
    └── banner_anuncio.dart  # Banner AdMob isolado (load com try/catch)

assets/
├── data/
│   ├── indice.json          # 66 livros (índice leve)
│   ├── mensagens.json       # Mensagens diárias
│   └── livros/<nome>.json   # Conteúdo por livro (carregado sob demanda)

test/                         # unit + widget; arquivos referenciam casos (E/C/B)
tool/
├── QA_EDGE_CASES.md          # Matriz de QA (fonte de verdade)
└── (backup/, scripts de dados)
```

**Structure Decision**: projeto único Flutter (padrão), sem monorepo. Mantém-se
a separação atual: `lib/main.dart` concentra UI/estado; regras puras vivem em
módulos `lib/*.dart`; componentes de UI reutilizáveis em `lib/widgets/`.
Componentização futura segue estes critérios — extrair para `lib/` apenas
regra testável ou reuso real, e para `lib/widgets/` apenas widget com dois usos
ou responsabilidade isolada (ex.: banner). Não há camada de service/DI externa.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

Nenhuma violação do Constitution Check — nenhuma justificativa necessária.
