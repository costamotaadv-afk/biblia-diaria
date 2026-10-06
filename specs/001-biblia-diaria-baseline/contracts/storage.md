# Storage Contract: Persistência Local (Bíblia Diária)

Este documento define o contrato de chaves, estruturas e invariantes para o
armazenamento local no app (SharedPreferences e assets de dados). Ele espelha o
código da linha de base (`lib/main.dart`, `lib/config.dart`) e a tabela de
chaves de `../data-model.md`; qualquer mudança aqui exige atualizar os testes
correspondentes e vice-versa.

## 1. Chaves do SharedPreferences

| Chave | Tipo | Valor Padrão | Descrição |
| :--- | :--- | :--- | :--- |
| `favoritos_versiculos` | `List<String>` | `[]` | Referências de **versículos** favoritos (ex.: `"Gênesis 1:1"`, `"João 3:16"`). |
| `favoritos_capitulos` | `List<String>` | `[]` | Referências de **capítulos** favoritos (ex.: `"Salmos 23"`, `"1 João 3"`). |
| `favoritos_estudos` | `List<String>` | `[]` | `id` de recursos de estudo salvos (ex.: `"joao-3-16-comentario-1"`). |
| `tema_escuro` | `bool` | `false` | Tema ativo: `false` = claro, `true` = escuro. |
| `fonte_grande` | `bool` | `true` | Fonte maior ativa (textScaler 1.18); `false` = fonte padrão. |
| `voz_tts_id` | `String` | ausente (`null`) | Identificador da voz de TTS escolhida (ex.: `pt-br-x-ftd-neural-local\|pt-BR`). `null` → usa a voz padrão do aparelho. |

### Formato da referência de favorito

- Versículo: `"<Livro> <capítulo>:<versículo>"` — ex.: `"Gênesis 1:1"`.
- Capítulo: `"<Livro> <capítulo>"` — ex.: `"Salmos 23"`.
- O tipo do favorito é definido pela **chave** em que ele está armazenado
  (versículo ou capítulo), não por um campo separado. Nunca se deve gravar a
  mesma referência nas duas chaves com significados diferentes.
- Livros com prefixo numérico ("1 João", "3 João") usam a forma canônica com
  espaço entre o número e o nome; a resolução inversa na aba Salvos casa o
  prefixo mais longo primeiro (caso B11).

### Invariantes de escrita e leitura

- **Semântica de conjunto**: em memória os favoritos vivem como `Set<String>`
  (sem duplicatas); a leitura de disco faz `getStringList(...) ?? [] → toSet()`.
- **Escritas serializadas (last-write-wins)**: gravações de favoritos são
  encadeadas em fila de futuros por chave — ordem de chegada define o resultado
  no disco, evitando que memória e disco divirjam sob toques rápidos (caso C4).
- **Favorito órfão**: referência que não resolve em nenhum livro do índice é
  exibida como `"Conteúdo não encontrado."` — nunca lança e nunca fica em estado
  de carregamento eterno (caso E14).
- **Referência vazia nunca é persistida**: botões "Salvar" ficam desabilitados
  quando não há conteúdo válido (caso B9).
- **Preferências**: a mudança é aplicada na UI imediatamente e depois
  persistida (`setBool`); ausência da chave → valor padrão da tabela.
- **Voz removida do sistema**: se `voz_tts_id` apontar para uma voz que não
  existe mais, o app escolhe a melhor voz pt-BR disponível e **reescreve** a
  chave (caso B7).

## 2. Formato e Invariantes dos Dados (Assets)

- **Localização:** os arquivos com os 66 livros canônicos devem residir em
  `assets/data/`, declarados em `pubspec.yaml`:
  - `assets/data/indice.json` — índice leve dos 66 livros (Gênesis → Apocalipse);
  - `assets/data/mensagens.json` — mensagens diárias (strings);
  - `assets/data/livros/<nome>.json` — conteúdo por livro, carregado sob demanda;
  - `assets/data/estudos_indice.json` — índice leve dos recursos de estudo (sem `corpo`);
  - `assets/data/estudos/<Livro>.json` — detalhe por livro (com `corpo` e `fonte`), carregado sob demanda.

- **Recursos de estudo (feature 002):** seguem o mesmo padrão de índice leve +
  detalhe sob demanda. Invariante: o `id` de cada detalhe é idêntico ao `id` da
  sua entrada no índice; itens não-`Map`, com `id` vazio ou tipos errados são
  ignorados no parsing (`lib/catalogo_estudos.dart`) e nunca lançam `TypeError`.

- **Invariante 1 — Estrutura canônica por arquivo:** cada livro DEVE conter o
  nome oficial em português (`nome`, ex.: `"1 Coríntios"`) seguido da lista de
  capítulos (`capitulos`). Cada capítulo tem `numero` e `versiculos`; cada
  versículo tem `numero` e `texto`. Nomes de livro não-nulos são desejáveis;
  tipos de campo são tratados defensivamente por `comoLista`/`normalizarMensagens`
  (`lib/dados_seguros.dart`) — nenhum cast inseguro na UI.

- **Invariante 2 — Nunca exceção não tratada:** a ausência ou corrupção de um
  capítulo ou versículo individual NUNCA pode disparar uma exceção não tratada
  na UI. O app deve exibir uma string de fallback amigável (sem texto técnico),
  com os botões de ação desabilitados quando não houver conteúdo utilizável:

  | Situação (dado ausente/corrompido) | Fallback exibido | Caso QA |
  | :--- | :--- | :--- |
  | Livro do dia nulo/ausente no índice | `"Carregando conteúdo..."` | E1, E2 |
  | Capítulo com `versiculos` vazio | `"Sem conteúdo bíblico disponível."` | E4 |
  | Versículo com `texto` vazio ou só espaços | `"Sem conteúdo bíblico disponível."` | E5 |
  | Falha ao carregar o arquivo do livro | `"Não foi possível carregar este livro."` | C5 |
  | Favorito órfão (livro removido/renomeado) | `"Conteúdo não encontrado."` | E14 |
  | Mensagens vazias ou inválidas | `"Deus te fortaleça neste dia."` | E8, E9 |

  O carregamento de livro também deve permitir nova tentativa após falha
  transiente (cache com retry — `lib/cache_livros.dart`, caso C5), e o conteúdo
  diário é **calculado, não persistido** — determinístico por data
  (`diasDesdeEpoca`, casos B5/E13).

## 3. Testes que validam este contrato

- `test/concurrency_c4_test.dart` — fila last-write-wins e estado em disco.
- `test/widget_test.dart` — carga inicial de favoritos (`favoritos_versiculos`,
  `favoritos_capitulos`) e persistência entre "sessões".
- `test/estresse_e15_test.dart` — 200+ favoritos (uma chave) carregam e rolam.
- `test/limites_dados_test.dart` — fallbacks de dados E1–E9/E13/B5 e determinismo.
- `test/dados_biblicos_test.dart` — valida os ~31.100 versículos reais do asset.
- `test/tts_qualidade_test.dart` — persistência/fallback de `voz_tts_id` (B7).
- `test/config_negocio_test.dart` — chave Pix e IDs de anúncio (B3, B8).
- `test/catalogo_estudos_test.dart` — parsing/casamento/filtros dos recursos de
  estudo (EST1–EST6).
