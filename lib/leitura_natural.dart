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
