import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('índice e os 66 livros estão íntegros', () async {
    final indiceRaw = await rootBundle.loadString('assets/data/indice.json');
    final indice = (jsonDecode(indiceRaw) as List).cast<Map<String, dynamic>>();

    expect(indice, hasLength(66));
    expect(indice.first['nome'], 'Gênesis');
    expect(indice.last['nome'], 'Apocalipse');

    var totalCapitulos = 0;
    var totalVersiculos = 0;

    for (final entrada in indice) {
      final nome = entrada['nome'] as String;
      final livroRaw = await rootBundle.loadString(
        'assets/data/livros/$nome.json',
      );
      final livro = jsonDecode(livroRaw) as Map<String, dynamic>;
      final capitulos =
          (livro['capitulos'] as List).cast<Map<String, dynamic>>();

      expect(livro['nome'], nome, reason: 'Nome divergente em $nome');
      expect(
        capitulos.length,
        entrada['capitulos'],
        reason: 'Quantidade de capítulos divergente em $nome',
      );

      totalCapitulos += capitulos.length;
      for (var i = 0; i < capitulos.length; i++) {
        final capitulo = capitulos[i];
        expect(capitulo['numero'], i + 1, reason: '$nome, capítulo ${i + 1}');

        final versiculos =
            (capitulo['versiculos'] as List).cast<Map<String, dynamic>>();
        expect(versiculos, isNotEmpty, reason: '$nome ${i + 1} está vazio');
        totalVersiculos += versiculos.length;

        for (var j = 0; j < versiculos.length; j++) {
          final versiculo = versiculos[j];
          expect(
            versiculo['numero'],
            j + 1,
            reason: '$nome ${i + 1}:${j + 1}',
          );
          expect(
            (versiculo['texto'] as String).trim(),
            isNotEmpty,
            reason: '$nome ${i + 1}:${j + 1} está vazio',
          );
        }
      }
    }

    expect(totalCapitulos, 1189);
    expect(totalVersiculos, 31100);
  });

  test('mensagens diárias são válidas', () async {
    final raw = await rootBundle.loadString('assets/data/mensagens.json');
    final mensagens = (jsonDecode(raw) as List).cast<String>();

    expect(mensagens, isNotEmpty);
    expect(mensagens.every((mensagem) => mensagem.trim().isNotEmpty), isTrue);
  });
}
