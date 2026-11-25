/// Helpers seguros para dados carregados de JSON (assets).
///
/// A Bíblia é servida por JSON editado manualmente; um campo com tipo errado
/// (ex.: `capitulos` como objeto em vez de lista) não pode derrubar o app.
/// Cobre os casos E1–E9, E13, B5 e E16 da matriz de QA
/// (tool/QA_EDGE_CASES.md).
library;

import 'leitura_natural.dart';

/// Devolve [valor] se for uma `List`; caso contrário, `null`.
///
/// Substitui o cast `(x['campo'] as List?)`, que lança `TypeError` quando o
/// JSON contém um tipo diferente (ex.: um objeto no lugar de uma lista).
List<dynamic>? comoLista(dynamic valor) => valor is List ? valor : null;

/// Normaliza a lista de mensagens do JSON, descartando itens não-string.
///
/// Casos E8/E9 da matriz: `[123, {"a":1}, null]` convertido com `'$m'` viraria
/// texto "123", "Instance of '_Map'" e "null" exibidos na Home. Aqui, apenas
/// strings não-vazias são aceitas; lista vazia → fallback padrão (E8).
List<String> normalizarMensagens(dynamic decodificado) {
  if (decodificado is! List) return const [];
  return decodificado
      .whereType<String>()
      .where((m) => m.trim().isNotEmpty)
      .toList();
}

/// Número de dias entre [data] (normalizada para UTC) e 01/01/2024 (época).
///
/// A seleção do versículo do dia usa módulo euclidiano, então datas antes da
/// época geram dias negativos sem `RangeError` (caso E13) e datas extremas
/// (ano 9999) não estouram o inteiro (precisão arbitrária do Dart).
int diasDesdeEpoca(DateTime data) {
  final diaUtc = DateTime.utc(data.year, data.month, data.day);
  return diaUtc.difference(DateTime.utc(2024)).inDays;
}

/// Seleciona o conteúdo do "Versículo do Dia" de forma pura e determinística.
///
/// Extraído de `_conteudoDoDia` (lib/main.dart) para permitir testes unitários
/// dos casos: E1 (índice vazio → livro nulo), E2 (livro nulo), E3 (`capitulos`
/// com tipo errado), E4 (versículos vazios), E13 (dias negativos) e B5
/// (determinismo: mesmo dia → mesmo conteúdo).
Map<String, String> selecionarVersiculoDoDia({
  required int dia,
  required List<String> mensagens,
  required Map<String, dynamic>? livro,
}) {
  final mensagem = mensagens.isEmpty
      ? 'Deus te fortaleça neste dia.'
      : mensagens[dia % mensagens.length];

  if (livro == null) {
    return {
      'versiculo': 'Carregando conteúdo...',
      'referencia': '',
      'mensagem': mensagem,
    };
  }

  final capitulos = comoLista(livro['capitulos']) ?? const <dynamic>[];
  if (capitulos.isEmpty) {
    return {
      'versiculo': 'Sem conteúdo bíblico disponível.',
      'referencia': '',
      'mensagem': mensagem,
    };
  }

  final capIndice = (dia ~/ 66) % capitulos.length;
  final capRaw = capitulos[capIndice];
  if (capRaw is! Map) {
    return {
      'versiculo': 'Sem conteúdo bíblico disponível.',
      'referencia': '',
      'mensagem': mensagem,
    };
  }
  final cap = Map<String, dynamic>.from(capRaw);

  final versiculos = comoLista(cap['versiculos']) ?? const <dynamic>[];
  if (versiculos.isEmpty) {
    return {
      'versiculo': 'Sem conteúdo bíblico disponível.',
      'referencia': '',
      'mensagem': mensagem,
    };
  }

  final versIndice =
      (dia ~/ (66 * capitulos.length)) % versiculos.length;
  final versRaw = versiculos[versIndice];
  if (versRaw is! Map) {
    return {
      'versiculo': 'Sem conteúdo bíblico disponível.',
      'referencia': '',
      'mensagem': mensagem,
    };
  }

  final texto = '${versRaw['texto']}';
  if (texto.trim().isEmpty) {
    // E5: versículo com texto vazio/só espaços → mensagem amigável em vez de
    // renderizar ""..."" e o TTS ler apenas a referência.
    return {
      'versiculo': 'Sem conteúdo bíblico disponível.',
      'referencia': '',
      'mensagem': mensagem,
    };
  }

  // Continuidade: quando o versículo sorteado termina em ':' (fala/diálogo sem
  // conclusão), junta o(s) versículo(s) seguinte(s) para não deixar o texto
  // "no ar" (ex.: "Chamou Jeová a Moisés…:" → "...: Fala aos filhos de Israel").
  final textoCompleto = completarContinuidadeDeVersiculo(
    capitulos: capitulos,
    capIndice: capIndice,
    versIndice: versIndice,
    textoInicial: texto,
  );

  return {
    'versiculo': textoCompleto,
    'referencia': '${livro['nome']} ${cap['numero']}:${versRaw['numero']}',
    'mensagem': mensagem,
  };
}

/// Devolve a lista de versículos do capítulo [indice] dentro de [capitulos],
/// de forma defensiva (capítulo não-Map ou ausente → lista vazia; E16).
List<dynamic> versiculosDeCapitulo(List<dynamic> capitulos, int indice) {
  if (indice < 0 || indice >= capitulos.length) return const [];
  final cap = capitulos[indice];
  if (cap is! Map) return const [];
  return comoLista(cap['versiculos']) ?? const <dynamic>[];
}

/// Devolve o texto do versículo [versIndice] do capítulo [capIndice], ou `null`
/// se o item estiver ausente, não for `Map` ou o texto estiver vazio (E16).
String? textoDeVersiculo(
  List<dynamic> capitulos,
  int capIndice,
  int versIndice,
) {
  final versiculos = versiculosDeCapitulo(capitulos, capIndice);
  if (versIndice < 0 || versIndice >= versiculos.length) return null;
  final vers = versiculos[versIndice];
  if (vers is! Map) return null;
  final texto = '${vers['texto']}';
  return texto.trim().isEmpty ? null : texto;
}

/// Complementa [textoInicial] com o(s) versículo(s) seguinte(s) enquanto o
/// texto terminar em ':' (falas/diálogos que continuam no versículo posterior).
/// Atravessa capítulos do mesmo livro; encerra no fim do livro ou em item
/// inválido. Limite de segurança evita loop extremo (E16).
String completarContinuidadeDeVersiculo({
  required List<dynamic> capitulos,
  required int capIndice,
  required int versIndice,
  required String textoInicial,
}) {
  final partes = <String>[textoInicial.trimRight()];
  var textoAtual = partes.last;
  var ci = capIndice;
  var vi = versIndice;
  var passos = 0;

  while (textoAtual.endsWith(':') && passos < 5) {
    String? proximo;
    if (vi + 1 < versiculosDeCapitulo(capitulos, ci).length) {
      proximo = textoDeVersiculo(capitulos, ci, vi + 1);
      if (proximo != null) vi += 1;
    } else if (ci + 1 < capitulos.length) {
      proximo = textoDeVersiculo(capitulos, ci + 1, 0);
      if (proximo != null) {
        ci += 1;
        vi = 0;
      }
    }
    if (proximo == null) break;
    partes.add(proximo.trimRight());
    textoAtual = proximo.trimRight();
    passos += 1;
  }

  return partes.join(' ');
}

/// Converte uma lista bruta de JSON em mapas seguros, descartando itens que
/// não sejam `Map` (ex.: String/int/null soltos dentro de `capitulos` ou
/// `versiculos`). Caso E16 — nunca lança `TypeError`.
List<Map<String, dynamic>> mapasSeguros(List<dynamic>? itens) {
  if (itens == null) return const [];
  final mapas = <Map<String, dynamic>>[];
  for (final item in itens) {
    if (item is Map) {
      mapas.add(Map<String, dynamic>.from(item));
    }
  }
  return mapas;
}

/// Procura o texto de um versículo por referência ("Livro N:M") entre os
/// livros carregados em cache. Defensivo contra corrupção interna (E16):
/// capítulos/versículos não-mapeáveis são ignorados; sem correspondência
/// devolve `null` — a UI converte em "Conteúdo não encontrado." (E14).
String? textoDeVersiculoEmLivros(
  Iterable<Map<String, dynamic>> livros,
  String chave,
) {
  for (final livro in livros) {
    for (final capitulo in mapasSeguros(comoLista(livro['capitulos']))) {
      for (final versiculo in mapasSeguros(comoLista(capitulo['versiculos']))) {
        final ref =
            '${livro['nome']} ${capitulo['numero']}:${versiculo['numero']}';
        if (ref == chave) return '${versiculo['texto']}';
      }
    }
  }
  return null;
}

/// Procura o texto (falado) de um capítulo inteiro — "Versículo N. ..." —
/// entre os livros carregados em cache. Mesma defensividade de
/// [textoDeVersiculoEmLivros] (E16): nunca lança; sem correspondência → null.
///
/// [anunciarVersiculos] = `false` remove o prefixo "Versículo N." para uma
/// narração mais fluida (as pausas vêm da pontuação dos próprios versículos).
String? textoDeCapituloEmLivros(
  Iterable<Map<String, dynamic>> livros,
  String chaveCapitulo, {
  bool anunciarVersiculos = true,
}) {
  for (final livro in livros) {
    for (final capitulo in mapasSeguros(comoLista(livro['capitulos']))) {
      final chave = '${livro['nome']} ${capitulo['numero']}';
      if (chave != chaveCapitulo) continue;
      final versiculos = mapasSeguros(comoLista(capitulo['versiculos']));
      final textos = <String>[];
      for (final versiculo in versiculos) {
        final prefixo = anunciarVersiculos
            ? 'Versículo ${numeroPorExtenso('${versiculo['numero']}')}. '
            : '';
        textos.add('$prefixo${versiculo['texto']}');
      }
      return textos.join(' ');
    }
  }
  return null;
}
