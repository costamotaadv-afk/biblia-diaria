import 'package:biblia_diaria/cache_livros.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cobertura do caso C5 da matriz de QA: falha transiente no carregamento de
/// um livro não pode travar o retry (o future antigo ficava resolvido com
/// `null` para sempre). Aqui, a falha remove o future e permite nova tentativa.
void main() {
  test('C5: falha transiente permite nova tentativa (retry)', () async {
    var chamadas = 0;
    final cache = CacheDeLivros(carregador: (nome) async {
      chamadas++;
      if (chamadas == 1) return null; // falha de I/O na 1ª tentativa
      return <String, dynamic>{'nome': nome, 'capitulos': <dynamic>[]};
    });

    expect(await cache.assegurar('Gênesis'), isNull);
    expect(chamadas, 1);

    // Retry: a 2ª chamada tenta de novo (não fica preso no null).
    final livro = await cache.assegurar('Gênesis');
    expect(livro, isNotNull);
    expect(chamadas, 2);

    // Agora fica em cache: novas chamadas não disparam o carregador.
    await cache.assegurar('Gênesis');
    expect(chamadas, 2);
    expect(cache.contem('Gênesis'), isTrue);
  });

  test('C5: chamadas concorrentes compartilham o mesmo future', () async {
    var chamadas = 0;
    final cache = CacheDeLivros(carregador: (nome) async {
      chamadas++;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      return <String, dynamic>{'nome': nome};
    });

    final resultados = await Future.wait([
      cache.assegurar('Gênesis'),
      cache.assegurar('Gênesis'),
      cache.assegurar('Gênesis'),
    ]);
    expect(resultados.every((l) => l != null), isTrue);
    expect(chamadas, 1); // deduplicado
  });

  test('sucesso fica em cache; livros diferentes carregam separados', () async {
    final carregados = <String>[];
    final cache = CacheDeLivros(carregador: (nome) async {
      carregados.add(nome);
      return <String, dynamic>{'nome': nome};
    });

    await cache.assegurar('Gênesis');
    await cache.assegurar('Êxodo');
    expect(carregados, ['Gênesis', 'Êxodo']);

    await cache.assegurar('Gênesis');
    expect(carregados, ['Gênesis', 'Êxodo']); // sem recarga
  });

  test('C5: falha transiente em livro não-primeiro permite retry', () async {
    final chamadasPorLivro = <String, int>{};
    final cache = CacheDeLivros(carregador: (nome) async {
      chamadasPorLivro[nome] = (chamadasPorLivro[nome] ?? 0) + 1;
      // Êxodo falha uma vez na 1ª tentativa; os demais carregam de cara.
      if (nome == 'Êxodo' && chamadasPorLivro[nome] == 1) return null;
      return <String, dynamic>{'nome': nome, 'capitulos': <dynamic>[]};
    });

    // Navega Gênesis (ok) → Êxodo (falha transiente) → retry Êxodo.
    await cache.assegurar('Gênesis');
    expect(cache.contem('Gênesis'), isTrue);

    expect(await cache.assegurar('Êxodo'), isNull);
    expect(cache.contem('Êxodo'), isFalse);

    final exodo = await cache.assegurar('Êxodo'); // retry após a falha
    expect(exodo, isNotNull);
    expect(cache.contem('Êxodo'), isTrue);
    expect(chamadasPorLivro['Êxodo'], 2);
  });
}
