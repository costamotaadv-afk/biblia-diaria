# Quickstart — Contextualização Histórica dos Salmos

## Como o conteúdo é servido

- `assets/data/contexto/Salmos.json` — array com **150 objetos** (um por Salmo).
- Carregado sob demanda via `CacheDeContexto` (deduplicação + retry), nunca no boot.

## Como editar/adicionar contexto (sem mexer em código)

1. Edite `assets/data/contexto/Salmos.json` (um objeto por Salmo, campos da spec).
2. Respeite os invariantes: `id` único (`sal-N`), `salmo` 1..150, campos
   obrigatórios (`titulo`, `classificacao`, `periodo`, `contexto_politico`,
   `localizacao`, `explicacao`, `certeza`, `fontes`).
3. Use `certeza` ∈ {documentado, tradicional, hipotese, indeterminado}.
4. `referencias_cruzadas[].ref` deve resolver para um livro de
   `assets/data/indice.json` (nome completo, ex.: "2 Samuel 15").
5. Valide: `python tool/validar_contexto.py` (ou rode `flutter test
   test/contexto_historico_test.dart`).

## Pontos de entrada na UI

- Leitura de Salmos: botão "Contexto Histórico" (`history_edu`) no cabeçalho do capítulo.
- Aba Estudos: botão "Contexto histórico dos Salmos" → tela de busca.
- Cada referência cruzada navega para o capítulo na aba Bíblia (ancoragem aproximada + destaque).
