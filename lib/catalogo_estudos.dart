/// Catálogo de recursos de estudo do texto bíblico: notas de rodapé,
/// comentários, artigos, sermões, palestras e momentos históricos.
///
/// Funções puras (sem I/O e sem dependência de Flutter), no padrão de
/// `lib/dados_seguros.dart`, para permitir cobertura unitária dos casos
/// EST1–EST6 da matriz de QA (tool/QA_EDGE_CASES.md).
library;

/// Fonte/atribuição de um recurso de estudo (autor, obra, ano, licença).
class FonteEstudo {
  final String autor;
  final String obra;
  final String ano;
  final String licenca;

  const FonteEstudo({
    this.autor = '',
    this.obra = '',
    this.ano = '',
    this.licenca = '',
  });

  bool get vazio =>
      autor.trim().isEmpty &&
      obra.trim().isEmpty &&
      ano.trim().isEmpty &&
      licenca.trim().isEmpty;

  /// Crédito legível montado apenas com os campos existentes; vazio quando não
  /// há nenhum (a UI então não exibe a linha de crédito — NFR-006).
  String get credito {
    final a = autor.trim();
    final o = obra.trim();
    final anoTexto = ano.trim();
    final l = licenca.trim();

    final partes = <String>[];
    if (a.isNotEmpty) partes.add(a);
    if (o.isNotEmpty) {
      partes.add(anoTexto.isNotEmpty ? '$o ($anoTexto)' : o);
    } else if (anoTexto.isNotEmpty) {
      partes.add(anoTexto);
    }

    final base = partes.join(', ');
    if (l.isNotEmpty) {
      return base.isEmpty ? l : '$base — $l';
    }
    return base;
  }
}

/// Recurso de estudo associado (opcionalmente) a uma referência bíblica.
class RecursoEstudo {
  /// Identificador estável e único (persistido em favoritos).
  final String id;

  /// Tipo do recurso (ver [tiposConhecidos]).
  final String tipo;

  final String titulo;

  /// Corpo do texto; pode conter parágrafos (quebras de linha).
  final String corpo;

  /// Referência associada: `"Livro cap:vers"`, `"Livro cap"`, `"Livro"` ou `''`.
  final String referencia;

  /// Livro dono do recurso (usado para casar e carregar o detalhe).
  final String livro;

  /// Assuntos/palavras-chave (opcional).
  final List<String> temas;

  /// Fonte/atribuição (opcional).
  final FonteEstudo? fonte;

  const RecursoEstudo({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    required this.referencia,
    required this.livro,
    this.temas = const <String>[],
    this.fonte,
  });

  bool get temCorpo => corpo.trim().isNotEmpty;

  bool get temFonte => fonte != null && !fonte!.vazio;
}

// ---------------------------------------------------------------------------
// Parsing defensivo (nunca lança TypeError — casos EST1/EST2)
// ---------------------------------------------------------------------------

String _texto(dynamic valor) => valor == null ? '' : '$valor'.trim();

List<String> _listaDeTexto(dynamic valor) {
  if (valor is! List) return const <String>[];
  final itens = <String>[];
  for (final item in valor) {
    final t = _texto(item);
    if (t.isNotEmpty) itens.add(t);
  }
  return itens;
}

FonteEstudo? _fonteDeMapa(dynamic valor) {
  if (valor is! Map) return null;
  final m = Map<String, dynamic>.from(valor);
  final fonte = FonteEstudo(
    autor: _texto(m['autor']),
    obra: _texto(m['obra']),
    ano: _texto(m['ano']),
    licenca: _texto(m['licenca']),
  );
  return fonte.vazio ? null : fonte;
}

/// Converte um item bruto em [RecursoEstudo]; devolve `null` para itens que não
/// sejam `Map` ou que não tenham `id` utilizável (caso EST2).
RecursoEstudo? recursoDeMapa(dynamic valor) {
  if (valor is! Map) return null;
  final m = Map<String, dynamic>.from(valor);
  final id = _texto(m['id']);
  if (id.isEmpty) return null;

  return RecursoEstudo(
    id: id,
    tipo: _texto(m['tipo']),
    titulo: _texto(m['titulo']),
    corpo: '${m['corpo'] ?? ''}'.trim(),
    referencia: _texto(m['ref']),
    livro: _texto(m['livro']),
    temas: _listaDeTexto(m['tema']),
    fonte: _fonteDeMapa(m['fonte']),
  );
}

/// Converte uma lista bruta de JSON em recursos válidos, descartando entradas
/// inválidas; não-lista → lista vazia (casos EST1/EST2).
List<RecursoEstudo> recursosDeJson(dynamic decodificado) {
  if (decodificado is! List) return const <RecursoEstudo>[];
  final recursos = <RecursoEstudo>[];
  for (final item in decodificado) {
    final recurso = recursoDeMapa(item);
    if (recurso != null) recursos.add(recurso);
  }
  return recursos;
}

// ---------------------------------------------------------------------------
// Tipos e rótulos (casos EST5/EST6)
// ---------------------------------------------------------------------------

/// Tipos conhecidos na ordem canônica de exibição.
const List<String> tiposConhecidos = <String>[
  'nota',
  'comentario',
  'artigo',
  'sermao',
  'palestra',
  'momento_historico',
];

const Map<String, String> _rotulosFixos = <String, String>{
  'nota': 'Nota',
  'comentario': 'Comentário',
  'artigo': 'Artigo',
  'sermao': 'Sermão',
  'palestra': 'Palestra',
  'momento_historico': 'Momento histórico',
};

/// Rótulo legível do tipo; tipo desconhecido recebe rótulo genérico
/// capitalizado (ex.: `devocional` → "Devocional"). Caso EST6.
String rotuloTipo(String tipo) {
  final t = tipo.trim();
  if (t.isEmpty) return 'Estudo';
  final fixo = _rotulosFixos[t];
  if (fixo != null) return fixo;
  return '${t[0].toUpperCase()}${t.substring(1)}';
}

/// Agrupa recursos por tipo em ordem determinística (caso EST5): tipos
/// conhecidos na ordem de [tiposConhecidos]; desconhecidos ao final, na ordem em
/// que aparecem (preserva determinismo de NFR-007).
Map<String, List<RecursoEstudo>> agruparPorTipo(
  List<RecursoEstudo> recursos,
) {
  final ordemAparicao = <String>[];
  final mapa = <String, List<RecursoEstudo>>{};
  for (final recurso in recursos) {
    if (!mapa.containsKey(recurso.tipo)) {
      ordemAparicao.add(recurso.tipo);
      mapa[recurso.tipo] = <RecursoEstudo>[];
    }
    mapa[recurso.tipo]!.add(recurso);
  }

  final conhecidos =
      tiposConhecidos.where(mapa.containsKey).toList(growable: false);
  final desconhecidos = ordemAparicao
      .where((t) => !tiposConhecidos.contains(t))
      .toList(growable: false);
  final ordenados = <String>[...conhecidos, ...desconhecidos];

  return <String, List<RecursoEstudo>>{
    for (final chave in ordenados) chave: mapa[chave]!,
  };
}

// ---------------------------------------------------------------------------
// Casamento referência ↔ recurso (caso EST3)
// ---------------------------------------------------------------------------

/// Devolve a referência de capítulo de uma referência de versículo
/// (`"João 3:16"` → `"João 3"`); referências de capítulo/livro → `null`.
String? capituloDaReferencia(String referencia) {
  final ref = referencia.trim();
  final posicao = ref.lastIndexOf(':');
  if (posicao <= 0) return null;
  final capitulo = ref.substring(0, posicao).trim();
  return capitulo.isEmpty ? null : capitulo;
}

/// True se [recurso] se aplica à [referencia]: igual à referência, igual ao seu
/// capítulo, ou igual ao [livro] (recurso de livro).
bool recursoAplicavel(
  RecursoEstudo recurso,
  String referencia, {
  String? livro,
}) {
  final ref = recurso.referencia.trim();
  final alvo = referencia.trim();
  if (ref.isEmpty || alvo.isEmpty) return false;

  if (ref == alvo) return true;

  final capitulo = capituloDaReferencia(alvo);
  if (capitulo != null && ref == capitulo) return true;

  final nomeLivro = (livro ?? '').trim();
  if (nomeLivro.isNotEmpty && ref == nomeLivro) return true;

  return false;
}

/// Filtra, de [todos], os recursos aplicáveis a [referencia] (e [livro]).
List<RecursoEstudo> recursosAplicaveis(
  Iterable<RecursoEstudo> todos,
  String referencia, {
  String? livro,
}) {
  final aplicaveis = <RecursoEstudo>[];
  for (final recurso in todos) {
    if (recursoAplicavel(recurso, referencia, livro: livro)) {
      aplicaveis.add(recurso);
    }
  }
  return aplicaveis;
}

// ---------------------------------------------------------------------------
// Filtros da biblioteca (caso EST5)
// ---------------------------------------------------------------------------

/// Filtra recursos por [tipo] e/ou [livro] (strings vazias/nulas → sem filtro).
List<RecursoEstudo> filtrarRecursos(
  Iterable<RecursoEstudo> todos, {
  String? tipo,
  String? livro,
}) {
  final t = (tipo ?? '').trim();
  final l = (livro ?? '').trim();
  final filtrados = <RecursoEstudo>[];
  for (final recurso in todos) {
    if (t.isNotEmpty && recurso.tipo != t) continue;
    if (l.isNotEmpty && recurso.livro != l) continue;
    filtrados.add(recurso);
  }
  return filtrados;
}

/// Tipos presentes em [todos], em ordem determinística (conhecidos primeiro).
List<String> tiposDisponiveis(Iterable<RecursoEstudo> todos) {
  final vistos = <String>{};
  final ordemAparicao = <String>[];
  for (final recurso in todos) {
    final tipo = recurso.tipo.trim();
    if (tipo.isEmpty) continue;
    if (vistos.add(tipo)) ordemAparicao.add(tipo);
  }
  final conhecidos =
      tiposConhecidos.where(vistos.contains).toList(growable: false);
  final desconhecidos = ordemAparicao
      .where((t) => !tiposConhecidos.contains(t))
      .toList(growable: false);
  return <String>[...conhecidos, ...desconhecidos];
}

/// Livros presentes em [todos], ordenados alfabeticamente (determinismo).
List<String> livrosDisponiveis(Iterable<RecursoEstudo> todos) {
  final livros = <String>{};
  for (final recurso in todos) {
    final livro = recurso.livro.trim();
    if (livro.isNotEmpty) livros.add(livro);
  }
  return livros.toList()..sort();
}

/// Filtra [todos] por palavra-chave [busca], casando (sem diferenciar
/// maiúsculas/minúsculas e ignorando acentos) contra título, corpo e temas.
/// Busca vazia ou só espaços → devolve todos (sem filtro). Caso EST7.
List<RecursoEstudo> filtrarPorBusca(
  Iterable<RecursoEstudo> todos,
  String busca,
) {
  final termo = _normalizarBusca(busca);
  if (termo.isEmpty) return todos.toList(growable: false);

  final encontrados = <RecursoEstudo>[];
  for (final recurso in todos) {
    final alvo = _normalizarBusca(
      '${recurso.titulo} ${recurso.corpo} ${recurso.temas.join(' ')}',
    );
    if (alvo.contains(termo)) encontrados.add(recurso);
  }
  return encontrados;
}

/// Normaliza para busca: minúsculas e sem acentos (busca tolerante).
String _normalizarBusca(String texto) {
  return texto
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll(RegExp('ç'), 'c')
      .trim();
}
