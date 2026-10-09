# Contract — Contextualização Histórica dos Salmos

## `lib/contexto_historico.dart` (funções/classes puras)

- `enum CertezaHistorica { documentado, tradicional, hipotese, indeterminado }`
- `CertezaHistorica certezaDeCodigo(String?)` — desconhecido → indeterminado.
- `String rotuloCerteza(...)` / `String explicacaoCerteza(...)`.
- `class ReferenciaCruzada { referencia, tipo, nota }`.
- `class ContextoSalmo` — os 10 campos da spec + getters `tem*`.
- `ContextoSalmo? contextoSalmoDeMapa(dynamic)` — `null` para não-Map/id vazio/salmo ≤ 0.
- `List<ContextoSalmo> contextosDeJson(dynamic)` — não-lista → `[]`.
- `ContextoSalmo? contextoDoSalmo(Iterable<ContextoSalmo>, int)`.
- `List<ContextoSalmo> filtrarContextoPorBusca(Iterable, String)` — sem caixa/acentos.
- `class AlvoReferencia { livro, capitulo, versiculo }` + `analisarReferencia(String, List<String>)`.

## `lib/cache_contexto.dart`

- `class CacheDeContexto` — `cache`, `contem(livro)`, `assegurar(livro)`; falha
  transiente remove o future (retry), chamadas concorrentes deduplicadas.

## `lib/widgets/painel_contexto_historico.dart`

- `class PainelContextoHistorico extends StatelessWidget`
  - Params: `ContextoSalmo`, `ttsDisponivel`, `onOuvir`, `onNavegarReferencia`.
  - Renderiza: identificação + classificação, selo de certeza, autoria, período,
    contexto político, acontecimentos, localização, referências cruzadas
    (navegáveis), explicação, fontes e "Ouvir contexto". Sem overflow 320px×1.18.

## `lib/widgets/tela_contexto_historico.dart`

- `class TelaContextoHistorico` — busca + lista dos 150; abre o painel via bottom sheet.

## Storage

| Chave | Tipo | Descrição |
| :--- | :--- | :--- |
| — | — | sem chave nova (contexto não é persistido como favorito) |

**Assets**: `assets/data/contexto/Salmos.json`; validador `tool/validar_contexto.py`.

## Casos da matriz de QA (novos)

| Caso | Cenário | Onde é validado |
| :--- | :--- | :--- |
| CTX1 | JSON ausente/vazio/corrompido | `test/contexto_historico_test.dart` |
| CTX2 | itens/tipos inválidos | idem |
| CTX3 | grau de certeza (parse + rótulos) | idem |
| CTX4 | análise de referência (faixa/prefixo numérico) | idem |
| CTX5/CTX6 | busca tolerante + determinismo | idem |
| CTX7 | integridade dos 150 registros | idem |
