# Contract — Recursos de Estudo (módulos puros, widget e storage)

Contrato das APIs públicas introduzidas pela feature 002. Segue o padrão de
`specs/001-biblia-diaria-baseline/contracts/`: lógica pura em `lib/`, widget com
reuso real em `lib/widgets/`, chaves de persistência documentadas.

## `lib/catalogo_estudos.dart` (funções/classes puras)

Modelo:

- `class RecursoEstudo`
  - `String id`, `String tipo`, `String titulo`, `String corpo`,
    `String referencia`, `String livro`, `List<String> temas`, `String periodo`,
    `List<String> fatos`, `FonteEstudo? fonte`.
  - `String periodo`/`List<String> fatos` são **opcionais** (default `''`/`[]`),
    usados sobretudo em recursos `momento_historico` (contexto histórico).
  - `bool get temCorpo` — corpo não vazio após `trim()`.
  - `bool get temFonte` — `fonte` presente e com ao menos um campo.
  - `bool get temPeriodo` — `periodo` não vazio após `trim()`.
  - `bool get temFatos` — `fatos` não vazio.
- `class FonteEstudo`
  - `String autor`, `String obra`, `String ano`, `String licenca`.
  - `String get credito` — monta o crédito com os campos existentes (vazio se
    não houver nenhum).

Parsing (nunca lançam `TypeError`):

- `RecursoEstudo? recursoDeMapa(dynamic valor)` — `null` para não-`Map`/id vazio.
- `List<RecursoEstudo> recursosDeJson(dynamic decodificado)` — filtra itens
  inválidos; não-lista → `[]`.

Rótulos/tipos:

- `const List<String> tiposConhecidos` / `String rotuloTipo(String tipo)`.
- `Map<String, List<RecursoEstudo>> agruparPorTipo(List<RecursoEstudo>)` — ordem
  determinística (conhecidos primeiro, na ordem de `tiposConhecidos`; demais ao
  final, em ordem de primeira aparição).

Casamento referência ↔ recurso:

- `String? capituloDaReferencia(String referencia)` — `"João 3:16"` → `"João 3"`;
  referência de capítulo/livro → `null`.
- `bool recursoAplicavel(RecursoEstudo r, String referencia, {String? livro})`.
- `List<RecursoEstudo> recursosAplicaveis(Iterable<RecursoEstudo>, String
  referencia, {String? livro})`.

Filtros (biblioteca):

- `List<RecursoEstudo> filtrarRecursos(Iterable<RecursoEstudo>, {String? tipo,
  String? livro})`.
- `List<String> tiposDisponiveis(Iterable<RecursoEstudo>)`.
- `List<String> livrosDisponiveis(Iterable<RecursoEstudo>)`.

## `lib/cache_estudos.dart`

- `class CacheDeEstudos` — espelha `CacheDeLivros` (contrato 001):
  - `Map<String, List<RecursoEstudo>> cache`, `bool contem(String livro)`,
    `Future<List<RecursoEstudo>?> assegurar(String livro)`.
  - Falha transiente (loader → `null`) **remove** o future → retry no próximo
    acesso (caso C5); chamadas concorrentes deduplicadas.

## `lib/widgets/painel_estudos.dart`

- `class PainelEstudos extends StatelessWidget`
  - Parâmetros: `List<RecursoEstudo> recursos`, `Set<String> favoritos`,
    `void Function(RecursoEstudo) onAlternarFavorito`, `void Function(RecursoEstudo)?
    onOuvir`, `bool ttsDisponivel`.
  - Renderiza: estados vazio e preenchido; recursos agrupados por tipo; corpo,
    crédito de fonte e ações (Salvar/Remover, Ouvir). Para `momento_historico`
    com `periodo`/`fatos`, renderiza o selo do período e a lista de tópicos
    históricos/arqueológicos. Nunca lança; usa `Semantics` nos controles.

## Storage (delta de `contracts/storage.md`)

| Chave | Tipo | Padrão | Descrição |
| :--- | :--- | :--- | :--- |
| `favoritos_estudos` | `List<String>` | `[]` | `id` de recursos de estudo salvos. |

**Assets**: `assets/data/estudos_indice.json` (índice leve) e
`assets/data/estudos/<nome>.json` (detalhe por livro), declarados em
`pubspec.yaml`. Invariante: `id` do detalhe == `id` do índice; itens inválidos
ignorados no parsing.

## Casos da matriz de QA (novos)

| Caso | Cenário | Onde é validado |
| :--- | :--- | :--- |
| EST1 | JSON de estudos ausente/vazio/corrompido → catálogo vazio, sem crash | `test/catalogo_estudos_test.dart` |
| EST2 | Item não-`Map` / `id` vazio / tipos errados ignorados | `test/catalogo_estudos_test.dart` |
| EST3 | Casamento ref de versículo/capítulo/livro (inclui prefixo numérico) | `test/catalogo_estudos_test.dart` |
| EST4 | Corpo vazio/só espaços → `temCorpo == false` | `test/catalogo_estudos_test.dart` |
| EST5 | Agrupamento e filtros determinísticos (tipo/livro) | `test/catalogo_estudos_test.dart` |
| EST6 | Rótulo genérico para tipo desconhecido | `test/catalogo_estudos_test.dart` |
| EST7 | Busca por palavra-chave (ignora caixa/acentos) | `test/catalogo_estudos_test.dart` |
| EST8 | `periodo`/`fatos` do momento histórico (parse/fallback) | `test/catalogo_estudos_test.dart` |
