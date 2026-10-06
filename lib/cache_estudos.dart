import 'catalogo_estudos.dart';

/// Cache de recursos de estudo por livro, com deduplicação de futuros
/// concorrentes e retry em falha transiente.
///
/// Espelha o contrato de `lib/cache_livros.dart` (caso C5 da matriz de QA):
/// uma falha (loader → `null`) REMOVE o future, permitindo nova tentativa na
/// próxima chamada — nunca um estado "preso" em erro permanente.
class CacheDeEstudos {
  final Map<String, List<RecursoEstudo>> cache = {};
  final Map<String, Future<List<RecursoEstudo>?>> _futures = {};
  final Future<List<RecursoEstudo>?> Function(String livro) carregador;

  CacheDeEstudos({required this.carregador});

  bool contem(String livro) => cache.containsKey(livro);

  /// Devolve os recursos do cache, ou carrega sob demanda (deduplicando
  /// chamadas concorrentes para o mesmo livro).
  Future<List<RecursoEstudo>?> assegurar(String livro) {
    if (cache.containsKey(livro)) {
      return Future.value(cache[livro]);
    }
    final existente = _futures[livro];
    if (existente != null) {
      return existente;
    }
    final futuro = carregador(livro).then((recursos) {
      if (recursos != null) {
        cache[livro] = recursos;
      } else {
        // Falha transiente: libera a tentativa (retry no próximo acesso).
        _futures.remove(livro);
      }
      return recursos;
    });
    _futures[livro] = futuro;
    return futuro;
  }
}
