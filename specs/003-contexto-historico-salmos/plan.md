# Implementation Plan: Contextualização Histórica dos 150 Salmos

**Branch**: `003-contexto-historico-salmos` | **Spec**: [spec.md](spec.md)

## Summary

Módulo dedicado (feature 003) que enriquece a leitura dos Salmos com
contextualização histórica estruturada, offline, reaproveitando os padrões da
feature 002 (lógica pura em `lib/`, cache com retry, assets JSON, widget
reutilizável). Cada um dos 150 Salmos ganha um registro com 10 campos e um grau de
certeza histórica; referências cruzadas navegam internamente.

## Technical Context

- **Stack**: Flutter/Dart (SDK `>=3.0.0 <4.0.0`). **Nenhuma dependência nova**.
- **Storage**: `assets/data/contexto/Salmos.json` (detalhe por livro), carregado sob
  demanda com `CacheDeContexto` (deduplicação + retry).
- **Testing**: `flutter_test`; casos CTX1–CTX7 em `test/contexto_historico_test.dart`.
- **Platforms**: Android e web (alvos ativos).

## Constitution Check

- I. Lógica pura (`contexto_historico.dart`) e widgets reutilizáveis → PASS.
- II. Offline-first, parsing defensivo, carregamento sob demanda + retry → PASS.
- III. TTS degrada graciosamente; 320px×1.18 sem overflow → PASS.
- IV. `setState`+`mounted`; cache com loader injetável → PASS.
- V. Casos CTX na matriz + testes unitários → PASS.
- Constraints: zero dependências novas, pt-BR → PASS.

## Structure

```text
lib/contexto_historico.dart            # NOVO — modelo + parsing + busca + referência
lib/cache_contexto.dart                # NOVO — cache com retry
lib/widgets/painel_contexto_historico.dart  # NOVO — painel do contexto
lib/widgets/tela_contexto_historico.dart    # NOVO — tela de busca
lib/main.dart                          # integração (botão, painel, TTS, navegação)
assets/data/contexto/Salmos.json       # NOVO — 150 registros
tool/validar_contexto.py               # NOVO — validador
test/contexto_historico_test.dart      # NOVO — CTX1–CTX7
specs/003-contexto-historico-salmos/   # NOVO — spec-kit
```

## Decision

UI "híbrida" para público idoso: painel na tela de leitura + tela de busca na aba
Estudos — **sem** 6ª aba inferior (evita poluição e overflow da NavigationBar).
