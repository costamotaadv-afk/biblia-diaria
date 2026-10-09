/// Contextualização histórica dos 150 Salmos (feature 003), 100% offline.
///
/// Funções e classes puras (sem I/O e sem Flutter), no padrão de
/// `lib/catalogo_estudos.dart`, para permitir cobertura unitária dos casos
/// CTX1–CTX7 da matriz de QA (tool/QA_EDGE_CASES.md).
library;

import 'catalogo_estudos.dart' show FonteEstudo;

/// Grau de certeza histórica de uma informação (especificação §2.8).
enum CertezaHistorica {
  /// Informação expressamente presente na narrativa ou no título do Salmo.
  documentado,
  /// Interpretação histórica ou autoria transmitida pela tradição.
  tradicional,
  /// Proposta discutida na pesquisa bíblica/acadêmica.
  hipotese,
  /// Ausência de elementos suficientes para uma conclusão.
  indeterminado,
}

/// Converte o código textual do JSON no enum correspondente. Código ausente ou
/// desconhecido cai em [CertezaHistorica.indeterminado] (nunca lança).
CertezaHistorica certezaDeCodigo(String? codigo) {
  switch (codigo) {
    case 'documentado':
      return CertezaHistorica.documentado;
    case 'tradicional':
      return CertezaHistorica.tradicional;
    case 'hipotese':
      return CertezaHistorica.hipotese;
    case 'indeterminado':
      return CertezaHistorica.indeterminado;
    default:
      return CertezaHistorica.indeterminado;
  }
}

/// Rótulo curto do grau de certeza (exibido como selo).
String rotuloCerteza(CertezaHistorica certeza) {
  switch (certeza) {
    case CertezaHistorica.documentado:
      return 'Documentado no texto bíblico';
    case CertezaHistorica.tradicional:
      return 'Atribuição tradicional';
    case CertezaHistorica.hipotese:
      return 'Hipótese acadêmica';
    case CertezaHistorica.indeterminado:
      return 'Historicamente indeterminado';
  }
}

/// Descrição explicativa do grau de certeza.
String explicacaoCerteza(CertezaHistorica certeza) {
  switch (certeza) {
    case CertezaHistorica.documentado:
      return 'Informação expressamente presente na narrativa ou no título do Salmo.';
    case CertezaHistorica.tradicional:
      return 'Interpretação histórica ou autoria transmitida pela tradição judaico-cristã.';
    case CertezaHistorica.hipotese:
      return 'Proposta de datação, autoria ou contexto discutida na pesquisa bíblica.';
    case CertezaHistorica.indeterminado:
      return 'Não há elementos suficientes para estabelecer uma conclusão.';
  }
}

/// Referência cruzada navegável a outro trecho bíblico.
class ReferenciaCruzada {
  final String referencia;
  final String tipo;
  final String nota;

  const ReferenciaCruzada({
    this.referencia = '',
    this.tipo = '',
    this.nota = '',
  });

  bool get temReferencia => referencia.trim().isNotEmpty;

  bool get temNota => nota.trim().isNotEmpty;
}

/// Contextualização histórica completa de um Salmo.
class ContextoSalmo {
  final String id;
  final int numero;
  final String titulo;
  final List<String> classificacao;
  final String autoria;
  final String origemAutoria;
  final bool autoriaIncerta;
  final String periodo;
  final String periodoRetratado;
  final String periodoComposicao;
  final String contextoPolitico;
  final List<String> eventos;
  final String localizacao;
  final List<ReferenciaCruzada> referenciasCruzadas;
  final CertezaHistorica certeza;
  final String explicacao;
  final List<FonteEstudo> fontes;
  final List<String> temas;
  final List<String> personagens;
  final List<String> lugares;

  const ContextoSalmo({
    required this.id,
    required this.numero,
    this.titulo = '',
    this.classificacao = const <String>[],
    this.autoria = '',
    this.origemAutoria = '',
    this.autoriaIncerta = false,
    this.periodo = '',
    this.periodoRetratado = '',
    this.periodoComposicao = '',
    this.contextoPolitico = '',
    this.eventos = const <String>[],
    this.localizacao = '',
    this.referenciasCruzadas = const <ReferenciaCruzada>[],
    this.certeza = CertezaHistorica.indeterminado,
    this.explicacao = '',
    this.fontes = const <FonteEstudo>[],
    this.temas = const <String>[],
    this.personagens = const <String>[],
    this.lugares = const <String>[],
  });

  bool get temTitulo => titulo.trim().isNotEmpty;
  bool get temClassificacao => classificacao.isNotEmpty;
  bool get temAutoria => autoria.trim().isNotEmpty;
  bool get temOrigemAutoria => origemAutoria.trim().isNotEmpty;
  bool get temPeriodo => periodo.trim().isNotEmpty;
  bool get temPeriodoRetratado => periodoRetratado.trim().isNotEmpty;
  bool get temPeriodoComposicao => periodoComposicao.trim().isNotEmpty;
  bool get temContextoPolitico => contextoPolitico.trim().isNotEmpty;
  bool get temEventos => eventos.isNotEmpty;
  bool get temLocalizacao => localizacao.trim().isNotEmpty;
  bool get temReferencias => referenciasCruzadas.isNotEmpty;
  bool get temExplicacao => explicacao.trim().isNotEmpty;
  bool get temFontes => fontes.isNotEmpty;
  bool get temTemas => temas.isNotEmpty;
  bool get temPersonagens => personagens.isNotEmpty;
  bool get temLugares => lugares.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Parsing defensivo (nunca lança TypeError — casos CTX1/CTX2)
// ---------------------------------------------------------------------------

String _texto(dynamic valor) => valor == null ? '' : '$valor'.trim();

int _inteiro(dynamic valor) => int.tryParse('$valor'.trim()) ?? 0;

bool _booleano(dynamic valor) => valor == true;

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

List<FonteEstudo> _fontes(dynamic valor) {
  if (valor is! List) return const <FonteEstudo>[];
  final fontes = <FonteEstudo>[];
  for (final item in valor) {
    final fonte = _fonteDeMapa(item);
    if (fonte != null) fontes.add(fonte);
  }
  return fontes;
}

List<ReferenciaCruzada> _referencias(dynamic valor) {
  if (valor is! List) return const <ReferenciaCruzada>[];
  final referencias = <ReferenciaCruzada>[];
  for (final item in valor) {
    if (item is! Map) continue;
    final m = Map<String, dynamic>.from(item);
    final ref = ReferenciaCruzada(
      referencia: _texto(m['ref']),
      tipo: _texto(m['tipo']),
      nota: _texto(m['nota']),
    );
    if (ref.temReferencia) referencias.add(ref);
  }
  return referencias;
}

/// Converte um item bruto em [ContextoSalmo]; devolve `null` para itens que não
/// sejam `Map` ou que não tenham `id` utilizável e `salmo` positivo (CTX2).
ContextoSalmo? contextoSalmoDeMapa(dynamic valor) {
  if (valor is! Map) return null;
  final m = Map<String, dynamic>.from(valor);
  final id = _texto(m['id']);
  final numero = _inteiro(m['salmo']);
  if (id.isEmpty || numero <= 0) return null;

  return ContextoSalmo(
    id: id,
    numero: numero,
    titulo: _texto(m['titulo']),
    classificacao: _listaDeTexto(m['classificacao']),
    autoria: _texto(m['autoria']),
    origemAutoria: _texto(m['origem_autoria']),
    autoriaIncerta: _booleano(m['autoria_incerta']),
    periodo: _texto(m['periodo']),
    periodoRetratado: _texto(m['periodo_retratado']),
    periodoComposicao: _texto(m['periodo_composicao']),
    contextoPolitico: _texto(m['contexto_politico']),
    eventos: _listaDeTexto(m['eventos']),
    localizacao: _texto(m['localizacao']),
    referenciasCruzadas: _referencias(m['referencias_cruzadas']),
    certeza: certezaDeCodigo(_texto(m['certeza'])),
    explicacao: _texto(m['explicacao']),
    fontes: _fontes(m['fontes']),
    temas: _listaDeTexto(m['temas']),
    personagens: _listaDeTexto(m['personagens']),
    lugares: _listaDeTexto(m['lugares']),
  );
}

/// Converte uma lista bruta de JSON em contextos válidos, descartando entradas
/// inválidas; não-lista → lista vazia (casos CTX1/CTX2).
List<ContextoSalmo> contextosDeJson(dynamic decodificado) {
  if (decodificado is! List) return const <ContextoSalmo>[];
  final contextos = <ContextoSalmo>[];
  for (final item in decodificado) {
    final contexto = contextoSalmoDeMapa(item);
    if (contexto != null) contextos.add(contexto);
  }
  return contextos;
}

// ---------------------------------------------------------------------------
// Consultas (caso CTX6)
// ---------------------------------------------------------------------------

/// Devolve o contexto do Salmo [numero], ou `null` se não houver.
ContextoSalmo? contextoDoSalmo(Iterable<ContextoSalmo> todos, int numero) {
  for (final contexto in todos) {
    if (contexto.numero == numero) return contexto;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Busca por palavra-chave (caso CTX5)
// ---------------------------------------------------------------------------

/// Filtra [todos] por [busca], casando (sem caixa e sem acentos) contra número,
/// título, autoria, período, contexto político, eventos, localização,
/// explicação, temas, personagens e lugares. Busca vazia → todos (sem filtro).
List<ContextoSalmo> filtrarContextoPorBusca(
  Iterable<ContextoSalmo> todos,
  String busca,
) {
  final termo = _normalizarBusca(busca);
  if (termo.isEmpty) return todos.toList(growable: false);

  final encontrados = <ContextoSalmo>[];
  for (final contexto in todos) {
    final alvo = _normalizarBusca(
      'salmo ${contexto.numero} ${contexto.titulo} ${contexto.autoria} '
      '${contexto.periodo} ${contexto.periodoRetratado} '
      '${contexto.periodoComposicao} ${contexto.contextoPolitico} '
      '${contexto.eventos.join(' ')} ${contexto.localizacao} '
      '${contexto.explicacao} ${contexto.temas.join(' ')} '
      '${contexto.personagens.join(' ')} ${contexto.lugares.join(' ')}',
    );
    if (alvo.contains(termo)) encontrados.add(contexto);
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

// ---------------------------------------------------------------------------
// Análise de referência para navegação interna (caso CTX4)
// ---------------------------------------------------------------------------

/// Alvo de navegação resolvido a partir de uma referência textual.
class AlvoReferencia {
  final String livro;
  final int? capitulo;
  final int? versiculo;

  const AlvoReferencia({required this.livro, this.capitulo, this.versiculo});

  /// True quando há livro e capítulo identificados (navegável até o capítulo).
  bool get navegavel => livro.isNotEmpty && capitulo != null;
}

/// Extrai livro/capítulo/versículo de uma referência ("2 Samuel 15–18",
/// "Salmos 4", "João 3:16"). Casa o nome do livro contra a lista de nomes
/// conhecidos (o mais longo primeiro, para tratar prefixos numéricos); o
/// restante fornece o capítulo (e o versículo após ':'). Faixas (ex.: "15–18")
/// resolvem para o capítulo inicial — o texto completo segue exibido.
AlvoReferencia? analisarReferencia(String referencia, List<String> nomesLivros) {
  final ref = referencia.trim();
  if (ref.isEmpty) return null;

  final nomes = nomesLivros.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final nome in nomes) {
    final nomeLimpo = nome.trim();
    if (nomeLimpo.isEmpty) continue;

    if (ref == nomeLimpo) return AlvoReferencia(livro: nomeLimpo);
    if (!ref.startsWith('$nomeLimpo ')) continue;

    final resto = ref.substring(nomeLimpo.length).trim();

    final versiculoMatch = RegExp(r'^(\d{1,3}):(\d{1,3})').firstMatch(resto);
    if (versiculoMatch != null) {
      return AlvoReferencia(
        livro: nomeLimpo,
        capitulo: int.tryParse(versiculoMatch.group(1)!),
        versiculo: int.tryParse(versiculoMatch.group(2)!),
      );
    }

    final capituloMatch = RegExp(r'^(\d{1,3})').firstMatch(resto);
    if (capituloMatch != null) {
      return AlvoReferencia(
        livro: nomeLimpo,
        capitulo: int.tryParse(capituloMatch.group(1)!),
      );
    }

    return AlvoReferencia(livro: nomeLimpo);
  }

  return null;
}


