import 'package:biblia_diaria/leitura_natural.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cobertura do caso E10 da matriz de QA (tool/QA_EDGE_CASES.md):
/// livros com prefixo numérico ("1 Coríntios", "2 Reis", "3 João") devem ser
/// lidos como "Primeira/Segunda/Terceira" e o capítulo/versículo corretos.
void main() {
  group('E10 — referenciaParaLeitura com prefixo numérico', () {
    test('1 Coríntios 2:3', () {
      expect(
        referenciaParaLeitura('1 Coríntios 2:3'),
        'Primeira Coríntios, capítulo dois, versículo três',
      );
    });

    test('1 João 3:16', () {
      expect(
        referenciaParaLeitura('1 João 3:16'),
        'Primeira João, capítulo três, versículo dezesseis',
      );
    });

    test('2 Reis 4:1', () {
      expect(
        referenciaParaLeitura('2 Reis 4:1'),
        'Segunda Reis, capítulo quatro, versículo um',
      );
    });

    test('3 João 1 (apenas capítulo)', () {
      expect(
        referenciaParaLeitura('3 João 1'),
        'Terceira João, capítulo um',
      );
    });

    test('1 Samuel 2:1', () {
      expect(
        referenciaParaLeitura('1 Samuel 2:1'),
        'Primeira Samuel, capítulo dois, versículo um',
      );
    });

    test('Salmos 119:176 (limite alto de versículo)', () {
      expect(
        referenciaParaLeitura('Salmos 119:176'),
        'Salmos, capítulo cento e dezenove, '
        'versículo cento e setenta e seis',
      );
    });
  });

  group('referenciaParaLeitura — casos gerais', () {
    test('Gênesis 1:1', () {
      expect(
        referenciaParaLeitura('Gênesis 1:1'),
        'Gênesis, capítulo um, versículo um',
      );
    });

    test('Salmos 23 (apenas capítulo)', () {
      expect(
        referenciaParaLeitura('Salmos 23'),
        'Salmos, capítulo vinte e três',
      );
    });

    test('nome composto: Lamentações de Jeremias 3:22', () {
      expect(
        referenciaParaLeitura('Lamentações de Jeremias 3:22'),
        'Lamentações de Jeremias, capítulo três, versículo vinte e dois',
      );
    });

    test('apenas nome do livro (sem número ao final)', () {
      expect(referenciaParaLeitura('Apocalipse'), 'Apocalipse');
    });

    test('string vazia retorna vazio', () {
      expect(referenciaParaLeitura(''), '');
      expect(referenciaParaLeitura('   '), '');
    });
  });

  group('E11 — textoParaLeituraNatural com referências cruzadas', () {
    test('João 3:16 dentro do texto', () {
      expect(
        textoParaLeituraNatural('Disse-lhe Jesus: João 3:16, com amor.'),
        contains('joão, capítulo três, versículo dezesseis'),
      );
    });

    test('prefixo numérico preservado: 1 Co 2:3', () {
      expect(
        textoParaLeituraNatural('Veja 1 Co 2:3 no contexto.'),
        contains('primeira co, capítulo dois, versículo três'),
      );
    });

    test('Salmos 119:176 em cruzamento', () {
      expect(
        textoParaLeituraNatural('Compare com Salmos 119:176.'),
        contains('salmos, capítulo cento e dezenove, '
            'versículo cento e setenta e seis'),
      );
    });
  });

  group('numeroPorExtenso / escreverNumero (limites 0–999)', () {
    test('limites mínimo e máximo', () {
      expect(escreverNumero(0), 'zero');
      expect(escreverNumero(999), 'novecentos e noventa e nove');
    });

    test('cem é especial', () {
      expect(escreverNumero(100), 'cem');
      expect(escreverNumero(101), 'cento e um');
    });

    test('fora do intervalo devolve o número cru (E7)', () {
      expect(escreverNumero(1000), '1000');
      expect(escreverNumero(-1), '-1');
    });

    test('entrada não numérica é devolvida intacta (E6)', () {
      expect(numeroPorExtenso('abc'), 'abc');
      expect(numeroPorExtenso(''), '');
    });
  });

  group('E11 — referência cruzada malformada (4 dígitos)', () {
    test('Salmos 1190:12 não casa e não lança', () {
      final resultado = textoParaLeituraNatural('Veja Salmos 1190:12, amigo.');
      expect(resultado, isNotEmpty);
      // 4 dígitos excedem \d{1,3}: a referência fica literal (sem virar horário
      // nem crash) — decisão documentada na matriz (E11).
      expect(resultado, contains('1190:12'));
    });

    test('prefixo numérico 1 Co 2:3 continua preservado (E11)', () {
      expect(
        textoParaLeituraNatural('Veja 1 Co 2:3 no contexto.'),
        contains('primeira co, capítulo dois, versículo três'),
      );
    });
  });

  group('E6/E7 — referência com número inválido não gera TTS absurdo', () {
    test('numero ausente/"abc" não crasha (E6)', () {
      expect(referenciaParaLeitura('Gênesis abc:1'), 'Gênesis abc:1');
    });

    test('numero > 999 cai no literal, sem virar horário (E7)', () {
      expect(referenciaParaLeitura('Gênesis 1000:1'), 'Gênesis 1000:1');
    });
  });

  group('E12 — dividirTextoParaFala (capítulo gigante)', () {
    test('texto curto devolve um único segmento', () {
      expect(dividirTextoParaFala('Olá mundo.'), ['Olá mundo.']);
    });

    test('texto vazio devolve lista vazia', () {
      expect(dividirTextoParaFala(''), isEmpty);
    });

    test('divide em segmentos <= maxCaracteres', () {
      final frases = List.generate(
        200,
        (i) => 'Versículo $i. Esta é uma frase de teste que continua.',
      ).join(' ');
      final segmentos = dividirTextoParaFala(frases, maxCaracteres: 200);
      expect(segmentos.length, greaterThan(1));
      for (final segmento in segmentos) {
        expect(segmento.length, lessThanOrEqualTo(200));
      }
      expect(segmentos.every((s) => s.trim().isNotEmpty), isTrue);
    });

    test('corta em pontuação, preservando o ponto final', () {
      final segmentos = dividirTextoParaFala(
        'Primeira frase. Segunda frase! Terceira? Quarta; Quinta.',
        maxCaracteres: 30,
      );
      // Cada segmento (exceto o último) termina em pontuação forte.
      for (var i = 0; i < segmentos.length - 1; i++) {
        final ultimo = segmentos[i].substring(segmentos[i].length - 1);
        expect(const ['.', '!', '?', ';'], contains(ultimo));
      }
    });
  });
}
