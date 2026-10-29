/// Busca textual na Bíblia (funções puras, sem I/O e sem Flutter).
library;

import 'dados_seguros.dart';

/// Um versículo que casa com o termo pesquisado.
class ResultadoBusca {
  final String livro;
  final String capitulo;
  final String versiculo;
  final String texto;

  const ResultadoBusca({
    required this.livro,
    required this.capitulo,
    required this.versiculo,
    required this.texto,
  });

  /// Referência canônica (`"Livro C:V"`) usada para navegação.
  String get referencia => '$livro $capitulo:$versiculo';
}

/// Normaliza para busca: minúsculas e sem acentos (busca tolerante).
String normalizarParaBusca(String texto) {
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

/// Varre [livros] (JSON já carregados) e devolve os versículos cujo texto
/// contém [termo], limitado a [limite] resultados.
List<ResultadoBusca> buscarNaBiblia(
  Iterable<Map<String, dynamic>> livros,
  String termo, {
  int limite = 100,
}) {
  final alvo = normalizarParaBusca(termo);
  if (alvo.isEmpty) return const <ResultadoBusca>[];

  final resultados = <ResultadoBusca>[];
  for (final livro in livros) {
    final nomeLivro = '${livro['nome']}';
    final capitulos = mapasSeguros(comoLista(livro['capitulos']));
    for (final capitulo in capitulos) {
      final numeroCapitulo = '${capitulo['numero']}';
      final versiculos = mapasSeguros(comoLista(capitulo['versiculos']));
      for (final versiculo in versiculos) {
        final texto = '${versiculo['texto']}';
        if (normalizarParaBusca(texto).contains(alvo)) {
          resultados.add(ResultadoBusca(
            livro: nomeLivro,
            capitulo: numeroCapitulo,
            versiculo: '${versiculo['numero']}',
            texto: texto,
          ));
          if (resultados.length >= limite) return resultados;
        }
      }
    }
  }
  return resultados;
}
