# Data Model — Contextualização Histórica dos Salmos

## Entidade `ContextoSalmo`

Mapeada de `assets/data/contexto/Salmos.json` (um objeto por Salmo):

| Campo | Tipo | Obrigatório | Observação |
| :--- | :--- | :--- | :--- |
| `id` | String | sim | ex.: `sal-3`; estável e único |
| `salmo` | int | sim | 1..150 |
| `titulo` | String | sim | título temático |
| `classificacao` | List<String> | sim | louvor, lamentação, sabedoria… |
| `autoria` | String | — | vazio = desconhecida |
| `origem_autoria` | String | — | ex.: "Título hebraico do Salmo" |
| `autoria_incerta` | bool | — | distingue tradição de comprovação |
| `periodo` | String | sim | período associado |
| `periodo_retratado` | String | — | época retratada no texto |
| `periodo_composicao` | String | — | "Data de composição historicamente indeterminada" ou hipótese |
| `contexto_politico` | String | sim | organização política, conflitos etc. |
| `eventos` | List<String> | — | acontecimentos relacionados |
| `localizacao` | String | sim | reino/região/cidade |
| `referencias_cruzadas` | List<Map> | — | `{ref, tipo, nota}` |
| `certeza` | String | sim | documentado \| tradicional \| hipotese \| indeterminado |
| `explicacao` | String | sim | narrativa acessível |
| `fontes` | List<Map> | sim | `{autor, obra, ano, licenca}` |
| `temas`/`personagens`/`lugares` | List<String> | — | para busca |

## Referência cruzada

Formato textual canônico: `"<Livro> <cap>[:<vers>]"`. Faixas (`"15–18"`) resolvem
para o capítulo inicial na navegação; o texto completo segue exibido.

## Certeza histórica

`documentado` (texto/título), `tradicional` (tradição judaico-cristã), `hipotese`
(pesquisa acadêmica), `indeterminado` (sem elementos).

## Armazenamento (delta)

- Assets: `assets/data/contexto/Salmos.json` (declarado em `pubspec.yaml`).
- Cache em memória: `CacheDeContexto` (deduplicação + retry, espelha `CacheDeEstudos`).
- Sem chave nova em `SharedPreferences` (contexto não é "salvo" pelo usuário).

## Invariantes

- Exatamente 150 registros, `id` únicos, `salmo` 1..150.
- Campos obrigatórios não-vazios; tipos errados → `''`/`[]` sem `TypeError`.
- `referencias_cruzadas[].ref` resolve para um livro de `assets/data/indice.json`.
