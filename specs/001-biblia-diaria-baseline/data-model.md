# Data Model — Bíblia Diária Linha de Base

**Fase 1 do `/speckit-plan`.** Descreve as entidades de domínio, seus campos,
regras de validação e transições de estado. Deriva das "Key Entities" da spec e
do código real (linha de base). Toda validação aqui tem dono testável nos
módulos puros (`lib/dados_seguros.dart`, `lib/config.dart`) ou em regra
documentada na matriz de QA.

## Entidades

### Livro
- Representa uma unidade canônica da Bíblia (66 livros, Gênesis → Apocalipse).
- **Campos** (JSON em `assets/data/livros/<nome>.json`):
  - `nome` (String) — ex.: "1 Coríntios".
  - `capitulos` (List) — lista de capítulos.
- **Validação**: `nome` não-nulo é desejável; `capitulos` tratado por `comoLista`
  (objeto/string/null → tratado como ausente, sem `TypeError`). Livro nulo/ausente
  → fallback "Carregando conteúdo...". Dados de origem: ~31 mil versículos reais
  validados por `test/dados_biblicos_test.dart`.

### Capítulo
- Agrupamento numerado de versículos dentro de um livro.
- **Campos**: `numero` (int/numérico), `versiculos` (List).
- **Validação**: lista vazia ou itens não-Map → "Sem conteúdo bíblico
  disponível."; números inválidos não geram crash na referência/TTS.
- **Regra de domínio**: pode ser favorito e lido em voz alta inteiro.

### Versículo
- Menor unidade de texto com referência única.
- **Campos**: `numero`, `texto`.
- **Validação**: `texto` vazio/só espaços → tratado como sem conteúdo (E5).
- **Regra de domínio**: alvo da leitura diária, favoritos e leitura em voz alta.

### Referência
- Identificador textual canônico: `"Livro capitulo:versiculo"` (versículo) ou
  `"Livro capitulo"` (capítulo). Ex.: `"1 Coríntios 2:3"`, `"Salmos 119"`.
- **Validação/uso**: chave de favoritos; resolução inversa pelo índice
  (livros com prefixo numérico — B11); favoritos órfãos → "Conteúdo não
  encontrado." (E14).

### Favorito
- Referência salva pelo usuário, com tipo (versículo ou capítulo).
- **Armazenamento**: conjuntos de strings (`favoritos_versiculos`,
  `favoritos_capitulos`) persistidos em chave-valor local.
- **Regras**: persistência serializada last-write-wins (C4); toques rápidos não
  perdem dados; ordenação lexicográfica na aba "Salvos" (E15).

### Preferências do usuário
- Tema: `tema_escuro` (bool, padrão `false`).
- Fonte: `fonte_grande` (bool, padrão `true`).
- Voz: `voz_tts_id` (String, opcional — aponta para voz salva; voz removida →
  fallback + reescrita, B7).
- **Regras**: persistidas entre sessões; mudanças aplicadas imediatamente
  (rebuild) e depois persistidas.

### Conteúdo diário (Versículo do Dia + Mensagem)
- Derivado deterministicamente da data: `diasDesdeEpoca` (época 2024-01-01 =
  dia 0), seleção por módulo euclidiano sobre livro/capítulo/versículo e
  mensagens.
- **Regras**: mesmo dia → mesmo conteúdo em qualquer plataforma/horário (B5);
  dias negativos e datas extremas não estouram (E13); virada do dia com app
  aberto recalcula no próximo build (B4).
- **Não é persistido** — é calculado.

### Chave de doação (Pix)
- Constante de config: e-mail fixo (`costamota@gmail.com`).
- **Validação**: `chavePixValida` (regex de e-mail) — B3.

### Configuração de anúncios
- `erroIdAnuncioEmProducao(isRelease, id)`: IDs de teste (`ca-app-pub-3940…`)
  bloqueados em release — B8.

## Transições de estado (TTS — leitura em voz alta)

Máquina de estados explícita no widget raiz (`_falando`, `_pausado`,
`_leituraAtiva`):

```text
(ocioso) ──ouvir──▶ falando ──pausar──▶ pausado ──continuar──▶ falando
   ▲                  │                                         │
   └──concluir/cancelar┘◀──────────(stop ao iniciar novo trecho)┘
```

- Regras: um único áudio por vez (novo trecho faz `stop` antes de `speak`);
  leitura manual e não contínua (FR-007); plataforma sem voz → `_ttsDisponivel
  = false` e botões desabilitados; todo handler só faz `setState` se `mounted`.

## Transições de estado (persistência de favoritos)

Escritas concorrentes encadeadas em fila de futuros — ordem de chegada define o
resultado (last-write-wins), evitando que o disco seja gravado fora de ordem
(race C4):

```text
tocar salvar/remover → mutar conjunto em memória → enfileirar snapshot → gravar
```

## Chaves de armazenamento local

| Chave | Tipo | Dono |
|-------|------|------|
| `favoritos_versiculos` | `List<String>` | tela Início/Bíblia/Salvos |
| `favoritos_capitulos` | `List<String>` | tela Bíblia/Salvos |
| `favoritos_estudos` | `List<String>` | Aba Estudos / painel / Salvos |
| `tema_escuro` | `bool` | Ajustes |
| `fonte_grande` | `bool` | Ajustes |
| `voz_tts_id` | `String` | Ajustes (voz) |

Detalhes e contratos de integração em `contracts/`.
