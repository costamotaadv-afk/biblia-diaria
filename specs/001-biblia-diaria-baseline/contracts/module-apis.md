
# Contract — Módulos puros e Widgets

Contratos das APIs públicas dos módulos de lógica pura em `lib/` e dos
componentes de UI. Assinaturas em Dart refletem o código da linha de base.

## `lib/dados_seguros.dart`

Guardiões de dados JSON e seleção do conteúdo diário.

- `List<dynamic>? comoLista(dynamic valor)`
  Devolve `valor` se for `List`; senão `null` (nunca lança `TypeError`). Casos
  E3/E4.
- `List<String> normalizarMensagens(dynamic decodificado)`
  Aceita apenas strings não-vazias; não-lista → `[]`. Casos E8/E9.
- `int diasDesdeEpoca(DateTime data)`
  Dias entre `data` (UTC) e 2024-01-01. Datas anteriores → negativos. E13/B5.
- `Map<String, String> selecionarVersiculoDoDia({required int dia, required
  List<String> mensagens, required Map<String, dynamic>? livro})`
  Determinístico; fallbacks documentados (E1–E5, B5).
- `List<Map<String, dynamic>> mapasSeguros(List<dynamic>? itens)`
  Filtra itens que não sejam `Map` (String/int/null soltos em `capitulos`/
  `versiculos`); nunca lança `TypeError`. Caso E16.
- `String? textoDeVersiculoEmLivros(Iterable<Map<String, dynamic>> livros,
  String chave)` — texto de um versículo por referência entre livros
  carregados; corrupção interna ignorada; ausência → `null` (E14/E16).
- `String? textoDeCapituloEmLivros(Iterable<Map<String, dynamic>> livros,
  String chaveCapitulo)` — texto falado de um capítulo ("Versículo N. …");
  mesma defensividade (E16).

## `lib/config.dart`

Regras de negócio de monetização.

- `const String chavePix` — chave de doação (e-mail).
- `bool chavePixValida(String chave)` — valida e-mail (B3).
- `String? erroIdAnuncioEmProducao({required bool isRelease, required String
  id})` — erro se ID de teste em release (B8).

## `lib/leitura_natural.dart`

Conversões para leitura em voz alta (funções puras).

- `String referenciaParaLeitura(String referencia)`
  "Gênesis 1:1" → "Gênesis, capítulo um, versículo um". Prefixo numérico
  correto (E10).
- `String nomeLivroParaLeitura(String nome)` — "1 Coríntios" → "Primeira
  Coríntios".
- `String numeroPorExtenso(String numero)` / `String escreverNumero(int n)`
  (0–999; fora → dígito cru).
- `String textoParaLeituraNatural(String texto)` — normaliza pontuação e
  referências cruzadas para o TTS.
- `List<String> dividirTextoParaFala(String texto, {int maxCaracteres = 1500})`
  — divide texto longo em segmentos (corta na última pontuação, sem quebrar
  palavra) para capítulos gigantes (E12).

## `lib/cache_livros.dart`

Carregamento sob demanda com retry.

- `class CacheDeLivros` — `cache`, `contem(nome)`,
  `Future<Map<String,dynamic>?> assegurar(nome)`. Falha transiente remove o
  future (retry); chamadas concorrentes deduplicadas. C5.

## `lib/platform_support.dart`

Gates de capacidade por plataforma (voz/anúncios). Ver `platform.md`.

- `bool get suportaAdMob` — Android/iOS apenas.
- `bool get suportaTts` — Android/iOS/macOS/Windows (não na web/Linux).
- `Future<void> inicializarAdMob()` — nunca lança (C10).

## Widgets — `lib/widgets/`

Contrato de componente reutilizável (único hoje):

- `class BannerAnuncio extends StatefulWidget`
  Exibe banner adaptativo quando `suportaAdMob`; sem parâmetros obrigatórios
  (`const BannerAnuncio()`). Recarrega o tamanho adaptativo em
  `didChangeDependencies` (rotação/largura — C8) e dispõe o banner no
  `dispose`; falha de `load()` e `MissingPluginException` tratadas
  internamente (C9/C10); ID de teste bloqueado em release via
  `erroIdAnuncioEmProducao` (B8).

Regra de extração de widget: dois usos reais **ou** responsabilidade isolada
(ex.: banner). Qualquer widget novo deve declarar sua API pública aqui.
