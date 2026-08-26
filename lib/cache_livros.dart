/// Cache de livros com retry em falha transiente (caso C5 da matriz de QA).
///
/// O bug original em `main.dart`: após uma falha de I/O (rede, cache web),
/// `_futuresLivros[nome]` ficava resolvido com `null` para sempre — o livro
/// permanecia "Não foi possível carregar" mesmo depois de o arquivo voltar.
/// Aqui, uma falha REMOVE o future, permitindo que a próxima chamada tente
/// novamente.
class CacheDeLivros {
  final Map<String, Map<String, dynamic>> cache = {};
  final Map<String, Future<Map<String, dynamic>?>> _futures = {};
  final Future<Map<String, dynamic>?> Function(String nome) carregador;

  CacheDeLivros({required this.carregador});

  bool contem(String nome) => cache.containsKey(nome);

  /// Devolve o livro do cache, ou carrega sob demanda (com deduplicação de
  /// futuros concorrentes).
  Future<Map<String, dynamic>?> assegurar(String nome) {
    if (cache.containsKey(nome)) {
      return Future.value(cache[nome]);
    }
    final existente = _futures[nome];
    if (existente != null) {
      return existente;
    }
    final futuro = carregador(nome).then((livro) {
      if (livro != null) {
        cache[nome] = livro;
      } else {
        // Falha transiente: libera a tentativa (retry no próximo acesso).
        _futures.remove(nome);
      }
      return livro;
    });
    _futures[nome] = futuro;
    return futuro;
  }
}
