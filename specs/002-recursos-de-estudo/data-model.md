# Data Model — Recursos de Estudo do Texto Bíblico

**Fase 1 do `/speckit-plan`.** Deriva das "Key Entities" da spec e do padrão real
do projeto (índice leve em assets + detalhe sob demanda + cache com retry).

## Entidades

### Recurso de Estudo
Material de apoio à compreensão de um texto bíblico.

- **Campos** (JSON em assets):
  - `id` (String, obrigatório) — identificador **estável** e único (ex.:
    `"joao-3-16-comentario-1"`). Recursos sem `id` são descartados no parsing.
  - `tipo` (String) — ver "Tipos".
  - `titulo` (String).
  - `corpo` (String) — texto do recurso (pode ter parágrafos).
  - `ref` (String) — referência associada: `"<Livro> <cap>:<vers>"` (versículo),
    `"<Livro> <cap>"` (capítulo) ou `"<Livro>"` (livro). Vazio → recurso não
    aplicável a trechos (só aparece na biblioteca).
  - `livro` (String) — livro dono do arquivo; usado para casar e carregar.
  - `tema` (List<String>) — opcional; assuntos/palavras-chave.
  - `periodo` (String) — opcional; período histórico/arqueológico (usado
    sobretudo em `momento_historico`).
  - `fatos` (List<String>) — opcional; fatos históricos/arqueológicos em tópicos.
  - `fonte` (Map) — opcional: `autor`, `obra`, `ano`, `licenca`.
- **Validação**: texto de `corpo` só com espaços → tratado como sem conteúdo;
  `tipo` desconhecido → rótulo genérico legível; `fonte` parcial → crédito
  montado apenas com os campos existentes; `periodo`/`fatos` ausentes, vazios ou
  com tipos errados → `''`/`[]` (nunca `TypeError`); `ref`/`livro` ausentes →
  recurso sem associação a trecho (nunca crash).

### Tipos de Recurso
Categoria estável (extensível apenas por dados):

| Chave | Rótulo |
| :--- | :--- |
| `nota` | Nota |
| `comentario` | Comentário |
| `artigo` | Artigo |
| `sermao` | Sermão |
| `palestra` | Palestra |
| `momento_historico` | Momento histórico |

Chave desconhecida → rótulo genérico derivado (ex.: `devocional` → "Devocional");
a ordem de exibição mantém os tipos conhecidos na ordem da tabela e os demais ao
final (determinismo — NFR-007).

### Referência
Identificador textual canônico (reaproveitado dos favoritos):
- Versículo: `"<Livro> <cap>:<vers>"` — ex.: `"João 3:16"`.
- Capítulo: `"<Livro> <cap>"` — ex.: `"Salmos 23"`.
- Livro: `"<Livro>"` — ex.: `"Gênesis"`.

**Regra de casamento** (`recursoAplicavel`): um recurso aplica-se a uma referência
`R` quando `recurso.ref == R`, ou `recurso.ref == capítulo(R)` (para R de
versículo), ou `recurso.ref == livro(R)`. Isso faz um recurso de capítulo
aparecer em todos os versículos do capítulo e um recurso de livro aparecer no
capítulo e nos versículos.

### Favorito de Estudo
Recurso salvo pelo usuário (conjunto de `id` de recursos).
- **Armazenamento**: `List<String>` na chave `favoritos_estudos`, persistido no
  aparelho; em memória é um `Set<String>`.
- **Regras**: escritas serializadas last-write-wins (mesmo padrão dos favoritos
  de versículo/capítulo); id salvo que não resolve em nenhum recurso → a seção
  "Salvos" mostra `"Conteúdo não encontrado."` (E14 análogo), sem carregamento
  eterno.

### Coleção/Tema
Agrupamento opcional por assunto/palavra-chave para navegação futura; nesta
feature apenas o campo `tema` é modelado (filtro por livro/tema já habilitado na
biblioteca).

## Formato dos arquivos (assets)

### `assets/data/estudos_indice.json` (índice leve)
Array de recursos **sem o `corpo`** (carregamento rápido na abertura):

```json
[
  {"id": "gen-1-1-nota", "tipo": "nota", "titulo": "No princípio",
   "ref": "Gênesis 1:1", "livro": "Gênesis", "tema": ["criação"]}
]
```

### `assets/data/estudos/<Livro>.json` (detalhe por livro)
Array de recursos **completos** (inclui `corpo` e `fonte`), carregado sob demanda:

```json
[
  {"id": "gen-1-1-nota", "tipo": "nota", "titulo": "No princípio",
   "ref": "Gênesis 1:1", "livro": "Gênesis", "tema": ["criação"],
   "corpo": "...", "fonte": {"autor": "...", "obra": "...", "ano": "...",
   "licenca": "Domínio público"}}
]
```

**Invariantes**:
- Todo item do detalhe deve ter o mesmo `id` da sua entrada no índice (o índice é
  a fonte da verdade para disponibilidade; o detalhe é a fonte do corpo).
- Itens não-`Map`, `id` vazio ou tipos errados são **ignorados** no parsing
  (nunca `TypeError`).

## Transições de estado (salvar recursos)

```text
tocar salvar → alterna id no Set em memória → enfileira snapshot →
SharedPreferences.setStringList('favoritos_estudos', snapshot)
```

Fila por chave (last-write-wins) — memória e disco nunca divergem (caso C4).

## Chaves de armazenamento local (delta)

| Chave | Tipo | Dono |
| :--- | :--- | :--- |
| `favoritos_estudos` | `List<String>` | Aba Estudos / painel / Salvos |
| `favoritos_versiculos` | `List<String>` | (existente) |
| `favoritos_capitulos` | `List<String>` | (existente) |
| `tema_escuro` / `fonte_grande` / `voz_tts_id` | (existentes) | Ajustes |

## Casos de borda cobertos pelo modelo

- Índice/detalhe ausente ou corrompido → catálogo vazio/filtrado, sem erro.
- Recurso com `corpo` vazio → sem conteúdo; painel exibe mensagem amigável.
- Recurso de capítulo/livro aparece nos versículos aplicáveis (casamento acima).
- Livros com prefixo numérico ("1 Coríntios") → casam pela mesma regra de string.
- Recurso salvo cujo `id` sumiu → "Conteúdo não encontrado."
