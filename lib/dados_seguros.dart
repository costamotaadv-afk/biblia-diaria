/// Helpers seguros para dados carregados de JSON (assets).
///
/// A Bíblia é servida por JSON editado manualmente; um campo com tipo errado
/// (ex.: `capitulos` como objeto em vez de lista) não pode derrubar o app.
/// Cobre os casos E1/E2/E3/E4/E13/B5 da matriz de QA (tool/QA_EDGE_CASES.md).
library;

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

  final capRaw = capitulos[(dia ~/ 66) % capitulos.length];
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

  final versRaw =
      versiculos[(dia ~/ (66 * capitulos.length)) % versiculos.length];
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

  return {
    'versiculo': texto,
    'referencia': '${livro['nome']} ${cap['numero']}:${versRaw['numero']}',
    'mensagem': mensagem,
  };
}
