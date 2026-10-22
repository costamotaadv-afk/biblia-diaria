/// Conversões de referências bíblicas e textos para leitura em voz alta.
///
/// Funções puras (sem dependência de Flutter/estado), extraídas de main.dart
/// para permitir cobertura unitária dos edge cases de TTS (ver
/// test/edge_cases_e10_test.dart).
library;

/// Converte uma referência bíblica (ex.: "Gênesis 1:1" ou "Gênesis 1")
/// em um texto falado natural: "Gênesis, capítulo 1, versículo 1".
///
/// Trata corretamente livros com prefixo numérico ("1 Coríntios", "2 Reis",
/// "3 João"): o número do livro vira ordinal por extenso e nunca é confundido
/// com o capítulo/versículo, pois o número final é sempre a referência.
String referenciaParaLeitura(String referencia) {
  final ref = referencia.trim();
  if (ref.isEmpty) return '';

  // Livros podem ter prefixo numérico ("1 Coríntios"), mas capítulo e
  // versículo sempre aparecem no FINAL da referência. A regex ancora o
  // grupo final de números ao fim da string para evitar ambiguidade.
  final regex = RegExp(r'^(.+?)\s+(\d{1,3})(?::(\d{1,3}))?$');
  final match = regex.firstMatch(ref);
  if (match == null) {
    // Sem número ao final: é só o nome do livro.
    return nomeLivroParaLeitura(ref);
  }

  final livro = nomeLivroParaLeitura(match.group(1)!.trim());
  final capExt = numeroPorExtenso(match.group(2)!);
  final versiculo = match.group(3);
  final base = '$livro, capítulo $capExt';
  if (versiculo != null) {
    return '$base, versículo ${numeroPorExtenso(versiculo)}';
  }
  return base;
}

/// Converte o prefixo numérico de um livro ("1 Coríntios") em ordinal por
/// extenso ("Primeira Coríntios"). Nomes sem prefixo são devolvidos intactos.
String nomeLivroParaLeitura(String nome) {
  final limpo = nome.trim();
  final match = RegExp(r'^(\d+)\s+(.+)$').firstMatch(limpo);
  if (match == null) return limpo;

  final numero = int.tryParse(match.group(1)!);
  if (numero == null || numero < 1) return limpo;

  const ordinais = <String>[
    '', // índice 0 não é usado
    'primeira',
    'segunda',
    'terceira',
    'quarta',
    'quinta',
    'sexta',
    'sétima',
    'oitava',
    'nona',
    'décima',
  ];
  if (numero < ordinais.length) {
    final ordinal = ordinais[numero];
    // Nome de livro começa com maiúscula em português: "Primeira Coríntios".
    return '${ordinal[0].toUpperCase()}${ordinal.substring(1)} '
        '${match.group(2)!}';
  }
  return limpo;
}

/// Converte um inteiro (0 a 999) para sua forma por extenso em português.
String numeroPorExtenso(String numero) {
  final n = int.tryParse(numero);
  if (n == null) return numero;
  return escreverNumero(n);
}

/// Implementação da escrita por extenso (0–999). Suficiente para capítulos
/// e versículos da Bíblia. Fora do intervalo devolve o número cru.
String escreverNumero(int n) {
  if (n < 0 || n > 999) return '$n';

  const unidades = [
    'zero',
    'um',
    'dois',
    'três',
    'quatro',
    'cinco',
    'seis',
    'sete',
    'oito',
    'nove',
    'dez',
    'onze',
    'doze',
    'treze',
    'catorze',
    'quinze',
    'dezesseis',
    'dezessete',
    'dezoito',
    'dezenove',
  ];
  const dezenas = [
    '',
    '',
    'vinte',
    'trinta',
    'quarenta',
    'cinquenta',
    'sessenta',
    'setenta',
    'oitenta',
    'noventa',
  ];
  const centenas = [
    '',
    'cento',
    'duzentos',
    'trezentos',
    'quatrocentos',
    'quinhentos',
    'seiscentos',
    'setecentos',
    'oitocentos',
    'novecentos',
  ];

  if (n < 20) return unidades[n];

  if (n < 100) {
    final d = n ~/ 10;
    final u = n % 10;
    final resto = u == 0 ? '' : ' e ${unidades[u]}';
    return '${dezenas[d]}$resto';
  }

  if (n == 100) return 'cem';

  final c = n ~/ 100;
  final r = n % 100;
  if (r == 0) return centenas[c];
  return '${centenas[c]} e ${escreverNumero(r)}';
}

/// Prepara um texto bíblico para o TTS: normaliza pontuação e transforma
/// referências cruzadas internas "Livro N:M" em texto natural, evitando que
/// o TTS leia "1:2" como horário (ex.: "uma e dois").
String textoParaLeituraNatural(String texto) {
  var t = texto
      .replaceAll(' - ', ', ')
      .replaceAll(';', ', ')
      .replaceAll('"', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  // Captura nome do livro com prefixo numérico opcional ("1 Co 2:3") e
  // capítulo:versículo (até 3 dígitos cada).
  t = t.replaceAllMapped(
    RegExp(r'((?:\d{1,2}\s+)?[A-Za-zÀ-ÿ]+)\s+(\d{1,3}):(\d{1,3})'),
    (m) {
      final livroNome = m.group(1)!.toLowerCase();
      final cap = numeroPorExtenso(m.group(2)!);
      final vers = numeroPorExtenso(m.group(3)!);
      // Em meio de frase, mantém minúsculas para o fluxo natural da leitura.
      return '${nomeLivroParaLeitura(livroNome).toLowerCase()}, '
          'capítulo $cap, versículo $vers';
    },
  );
  return t;
}

/// Divide um texto longo em segmentos de fala com no máximo [maxCaracteres]
/// caracteres, cortando na última pontuação forte (`.`, `!`, `?`, `;`) — sem
/// quebrar palavras. Se a janela não tiver pontuação, corta no último espaço;
/// numa palavra única gigante, corta no limite mesmo assim (fallback).
///
/// Textos curtos são devolvidos como uma lista de um único elemento. Usado para
/// capítulos gigantes (E12, ex.: Salmos 119) que os engines de TTS truncam
/// silenciosamente quando o texto passa de alguns milhares de caracteres.
List<String> dividirTextoParaFala(String texto, {int maxCaracteres = 1500}) {
  final t = texto.trim();
  if (t.isEmpty) return const <String>[];
  if (t.length <= maxCaracteres) return <String>[t];

  final segmentos = <String>[];
  var inicio = 0;
  while (inicio < t.length) {
    if (inicio + maxCaracteres >= t.length) {
      final resto = t.substring(inicio).trim();
      if (resto.isNotEmpty) segmentos.add(resto);
      break;
    }
    final janela = t.substring(inicio, inicio + maxCaracteres);
    var corte = _ultimoIndiceDePontuacao(janela);
    if (corte >= 0) {
      corte += 1; // inclui a pontuação no segmento
    } else {
      corte = janela.lastIndexOf(' ');
    }
    if (corte <= 0) corte = maxCaracteres;
    final segmento = t.substring(inicio, inicio + corte).trim();
    if (segmento.isNotEmpty) segmentos.add(segmento);
    inicio += corte;
    while (inicio < t.length && t[inicio] == ' ') {
      inicio++;
    }
  }
  return segmentos;
}

/// Índice da última ocorrência de uma pontuação forte dentro de [s] (ou -1).
int _ultimoIndiceDePontuacao(String s) {
  var indice = -1;
  for (final pontuacao in const ['.', '!', '?', ';']) {
    final posicao = s.lastIndexOf(pontuacao);
    if (posicao > indice) indice = posicao;
  }
  return indice;
}

/// Converte um ordinal (1º, 2ª) para sua forma por extenso.
///
/// Fora de 1–10 devolve "número N", para o TTS nunca ler o símbolo "º"/"ª" cru.
String escreverOrdinal(int? numero, {required bool feminino}) {
  const masculinos = <String>[
    'primeiro', 'segundo', 'terceiro', 'quarto', 'quinto',
    'sexto', 'sétimo', 'oitavo', 'nono', 'décimo',
  ];
  const femininos = <String>[
    'primeira', 'segunda', 'terceira', 'quarta', 'quinta',
    'sexta', 'sétima', 'oitava', 'nona', 'décima',
  ];
  final n = numero;
  if (n == null || n < 1) return 'número';
  final tabela = feminino ? femininos : masculinos;
  if (n <= 10) return tabela[n - 1];
  return 'número $n';
}

/// Escreve por extenso um número com separador de milhar em ponto
/// ("1.000" → "mil", "3.500" → "três mil e quinhentos"). Se não for um número
/// válido, devolve o texto original.
String escreverNumeroGrande(String comSeparadores) {
  final n = int.tryParse(comSeparadores.replaceAll('.', ''));
  if (n == null) return comSeparadores;
  if (n < 1000) return escreverNumero(n);
  if (n < 1000000) {
    final milhar = n ~/ 1000;
    final resto = n % 1000;
    final base = milhar == 1 ? 'mil' : '${escreverNumero(milhar)} mil';
    if (resto == 0) return base;
    return '$base e ${escreverNumero(resto)}';
  }
  return '$n';
}

/// Normaliza um texto já preparado por [textoParaLeituraNatural] para soar
/// natural no TTS: expande abreviações (a.C., d.C., séc., cap., v.), ordinais
/// (1º, 2ª), símbolos (%) e milhares com ponto (1.000). Aplicada como segunda
/// etapa da leitura em voz alta.
String normalizarTextoParaFala(String texto) {
  var t = texto;

  // Abreviações comuns (o ponto após "a"/"d" evita falso positivo com "a c").
  t = t.replaceAllMapped(
    RegExp(r'\ba\.\s*c\.?(?![A-Za-zÀ-ÿ0-9])', caseSensitive: false),
    (_) => 'antes de Cristo',
  );
  t = t.replaceAllMapped(
    RegExp(r'\bd\.\s*c\.?(?![A-Za-zÀ-ÿ0-9])', caseSensitive: false),
    (_) => 'depois de Cristo',
  );
  t = t.replaceAllMapped(
    RegExp(r'\bséc\.?(?![A-Za-zÀ-ÿ0-9])', caseSensitive: false),
    (_) => 'século',
  );
  t = t.replaceAllMapped(
    RegExp(r'\bcap\.?(?![A-Za-zÀ-ÿ0-9])', caseSensitive: false),
    (_) => 'capítulo',
  );
  // "v. 3" (com número à frente) vira "versículo 3".
  t = t.replaceAllMapped(
    RegExp(r'\bv\.\s*(?=\d)', caseSensitive: false),
    (_) => 'versículo ',
  );

  // Ordinais: 1º → primeiro; 3ª → terceira.
  t = t.replaceAllMapped(
    RegExp(r'(\d+)\s*º'),
    (m) => escreverOrdinal(int.tryParse(m.group(1)!), feminino: false),
  );
  t = t.replaceAllMapped(
    RegExp(r'(\d+)\s*ª'),
    (m) => escreverOrdinal(int.tryParse(m.group(1)!), feminino: true),
  );

  // Símbolos e milhares com separador de ponto.
  t = t.replaceAll('%', ' por cento').replaceAll('&', ' e ');
  t = t.replaceAllMapped(
    RegExp(r'\b\d{1,3}(?:\.\d{3})+\b'),
    (m) => escreverNumeroGrande(m.group(0)!),
  );

  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// ── Seleção de voz para leitura (TTS) ──────────────────────────────────
///
/// O `getVoices` do flutter_tts devolve vozes heterogêneas conforme a
/// plataforma: no Android, motores antigos (Pico, eSpeak) convivem com o
/// Google TTS (standard/neural/wavenet); no iOS há as variantes `compact`
/// (reduzida) e `enhanced` (aprimorada). Estas funções concentram a
/// heurística de qualidade para a leitura nunca cair num motor robotizado
/// quando existe alternativa neural disponível. São puras para teste unitário.

/// Marcadores presentes no nome de motores TTS legados/robotizados (som
/// metálico). Uma voz cujo nome contenha qualquer um deles é descartada.
const List<String> marcadoresMotorRobotico = <String>[
  'pico', // Android Pico TTS
  'espeak', // eSpeak NG
  'svox', // SVOX clássico
  'ekho', // Ekho (robótico)
  'festival', // Festival Speech (legado)
  'flite', // Flite (legado)
  'dectalk', // DECtalk (legado)
  'compact', // iOS compact (qualidade reduzida)
];

/// Representa uma voz de leitura oferecida pelo motor TTS do aparelho.
class VozDeLeitura {
  final String name;
  final String locale;
  final String gender;

  const VozDeLeitura({
    required this.name,
    required this.locale,
    required this.gender,
  });

  /// Identificador persistível (`voz_tts_id`), no formato `nome|locale`.
  String get id => '$name|$locale';

  /// Rótulo legível exibido no seletor de voz (Ajustes).
  String get label {
    final generoLegivel = gender.contains('male')
        ? 'Masculina'
        : gender.contains('female')
            ? 'Feminina'
            : 'Neutra';
    return '$name ($locale, $generoLegivel)';
  }

  /// `true` quando o nome aponta para um motor TTS legado/robotizado.
  bool get ehRobotica {
    final nome = name.toLowerCase();
    return marcadoresMotorRobotico.any((marcador) => nome.contains(marcador));
  }
}

/// Pontua uma voz para a leitura bíblica — quanto maior, mais adequada.
///
/// Prioriza pt-BR (depois pt-PT), marcadores de voz neural/natural
/// (`neural`, `wavenet`, `enhanced`, `premium`, `studio`) e, por fim, a voz
/// feminina (mais suave para meditação). Vozes sem marcador e sem gênero
/// ficam no final, mas não são descartadas aqui — esse papel é de
/// [filtrarVozesParaLeitura].
int pontuarVozParaLeitura({
  required String name,
  required String locale,
  required String gender,
}) {
  final nome = name.toLowerCase();
  final loc = locale.toLowerCase();
  var pts = 0;

  if (loc.contains('pt-br')) {
    pts += 100;
  } else if (loc.contains('pt-pt')) {
    pts += 60;
  }

  // Marcadores de alta qualidade (som humano), do mais forte ao mais fraco.
  if (nome.contains('neural') || nome.contains('wavenet')) {
    pts += 120;
  } else if (nome.contains('enhanced') ||
      nome.contains('premium') ||
      nome.contains('studio')) {
    pts += 90;
  } else if (nome.contains('online') ||
      nome.contains('network') ||
      nome.contains('high') ||
      nome.contains('quality')) {
    pts += 50;
  }

  if (gender.contains('female')) pts += 10;
  return pts;
}

/// Converte a lista bruta de `getVoices` em vozes `pt` adequadas à leitura,
/// já ordenadas da melhor para a pior.
///
/// Descarta motores legados/robotizados ([VozDeLeitura.ehRobotica]) sempre que
/// existir ao menos uma alternativa não legada; se o aparelho só oferecer
/// motores antigos, mantém todos para não deixar o usuário sem voz
/// (degradação graciosa). Vozes de outros idiomas são ignoradas.
List<VozDeLeitura> filtrarVozesParaLeitura(List<dynamic> vozesBrutas) {
  VozDeLeitura? parse(dynamic bruto) {
    if (bruto is! Map) return null;
    final locale = '${bruto['locale'] ?? ''}'.trim();
    if (!locale.toLowerCase().startsWith('pt')) return null;
    final name = '${bruto['name'] ?? ''}'.trim();
    if (name.isEmpty) return null;
    return VozDeLeitura(
      name: name,
      locale: locale,
      gender: '${bruto['gender'] ?? ''}'.toLowerCase(),
    );
  }

  final todas = <VozDeLeitura>[];
  for (final bruto in vozesBrutas) {
    final voz = parse(bruto);
    if (voz != null) todas.add(voz);
  }

  var selecionadas = todas.where((voz) => !voz.ehRobotica).toList();
  if (selecionadas.isEmpty) selecionadas = todas;

  selecionadas.sort((a, b) {
    final cmp = pontuarVozParaLeitura(
      name: b.name,
      locale: b.locale,
      gender: b.gender,
    ).compareTo(pontuarVozParaLeitura(
      name: a.name,
      locale: a.locale,
      gender: a.gender,
    ));
    if (cmp != 0) return cmp;
    return a.label.compareTo(b.label);
  });
  return selecionadas;
}

/// Escolhe a voz a usar, respeitando uma escolha salva em [vozSalvaId]
/// (se ainda existir na lista). Sem escolha salva, prefere a melhor voz
/// pt-BR feminina, depois a pt-BR masculina e, por fim, a primeira da lista.
VozDeLeitura? selecionarVozParaLeitura(
  List<VozDeLeitura> vozes,
  String? vozSalvaId,
) {
  if (vozes.isEmpty) return null;

  if (vozSalvaId != null) {
    for (final voz in vozes) {
      if (voz.id == vozSalvaId) return voz;
    }
  }

  for (final voz in vozes) {
    if (voz.locale.toLowerCase().contains('pt-br') &&
        voz.gender.contains('female')) {
      return voz;
    }
  }
  for (final voz in vozes) {
    if (voz.locale.toLowerCase().contains('pt-br') &&
        voz.gender.contains('male')) {
      return voz;
    }
  }
  return vozes.first;
}

