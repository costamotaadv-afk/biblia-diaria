/// Lógica pura do progresso de leitura da Bíblia (sem I/O e sem Flutter).
///
/// O progresso é medido por capítulos: cada capítulo lido é uma chave no
/// formato `"Livro N"` (mesmo padrão dos favoritos de capítulo). Funções puras
/// para permitir cobertura unitária.
library;

/// Soma o total de capítulos de todos os livros do índice.
///
/// O campo `capitulos` pode vir como `int` ou `num` (JSON); tipos inesperados
/// são ignorados defensivamente (nunca lança).
int totalDeCapitulos(Iterable<Map<String, dynamic>> indice) {
  var total = 0;
  for (final livro in indice) {
    final capitulos = livro['capitulos'];
    if (capitulos is int) {
      total += capitulos;
    } else if (capitulos is num) {
      total += capitulos.toInt();
    }
  }
  return total;
}

/// Conta, entre [lidos], apenas as chaves que correspondem a capítulos reais
/// do [indice] (`"Livro 1"` … `"Livro N"`). Chaves órfãs são ignoradas.
int contarCapitulosLidos(
    Iterable<Map<String, dynamic>> indice, Set<String> lidos) {
  var count = 0;
  for (final livro in indice) {
    final nome = '${livro['nome']}';
    final capitulos = livro['capitulos'];
    final total = capitulos is int
        ? capitulos
        : capitulos is num
            ? capitulos.toInt()
            : 0;
    for (var c = 1; c <= total; c++) {
      if (lidos.contains('$nome $c')) count++;
    }
  }
  return count;
}

/// Fração (0..1) da Bíblia já lida, baseada nos capítulos lidos válidos.
double fracaoLida(Iterable<Map<String, dynamic>> indice, Set<String> lidos) {
  final total = totalDeCapitulos(indice);
  if (total == 0) return 0;
  return (contarCapitulosLidos(indice, lidos) / total).clamp(0.0, 1.0);
}
