import 'package:biblia_diaria/busca_biblia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final livros = [
    {
      'nome': 'João',
      'capitulos': [
        {
          'numero': 3,
          'versiculos': [
            {'numero': 16, 'texto': 'Porque Deus amou o mundo de tal maneira.'},
            {'numero': 17, 'texto': 'Deus não enviou o Filho para condenar.'},
          ],
        },
      ],
    },
  ];

  test('busca ignora maiúsculas e acentos', () {
    final r = buscarNaBiblia(livros, 'DEUS');
    expect(r.length, 2);
    expect(r.first.livro, 'João');
  });

  test('busca sem correspondência retorna vazio', () {
    expect(buscarNaBiblia(livros, 'xyz'), isEmpty);
  });

  test('termo vazio retorna vazio', () {
    expect(buscarNaBiblia(livros, '   '), isEmpty);
  });

  test('referência é "Livro C:V"', () {
    final r = buscarNaBiblia(livros, 'amou');
    expect(r.single.referencia, 'João 3:16');
  });

  test('respeita o limite de resultados', () {
    final r = buscarNaBiblia(livros, 'deus', limite: 1);
    expect(r.length, 1);
  });

  test('normalizarParaBusca remove acentos', () {
    expect(normalizarParaBusca('Água Çedilha'), 'agua cedilha');
  });
}
