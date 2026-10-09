import 'contexto_historico.dart';

/// Cache de contextualização histórica por livro (Salmos), com deduplicação de
/// futuros concorrentes e retry em falha transiente. Espelha
/// `lib/cache_estudos.dart` (padrão do caso C5 da matriz de QA).
class CacheDeContexto {
  final Map<String, List<ContextoSalmo>> cache = {};
  final Map<String, Future<List<ContextoSalmo>?>> _futures = {};
  final Future<List<ContextoSalmo>?> Function(String livro) carregador;

  CacheDeContexto({required this.carregador});

  bool contem(String livro) => cache.containsKey(livro);

  Future<List<ContextoSalmo>?> assegurar(String livro) {
    if (cache.containsKey(livro)) {
      return Future.value(cache[livro]);
    }
    final existente = _futures[livro];
    if (existente != null) return existente;
    final futuro = carregador(livro).then((contextos) {
      if (contextos != null) {
        cache[livro] = contextos;
      } else {
        // Falha transiente: libera a tentativa (retry no próximo acesso).
        _futures.remove(livro);
      }
      return contextos;
    });
    _futures[livro] = futuro;
    return futuro;
  }
}
