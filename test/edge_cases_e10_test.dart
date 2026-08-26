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
}
