import 'package:biblia_diaria/progresso_leitura.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final indice = [
    {'nome': 'Gênesis', 'capitulos': 50},
    {'nome': 'Salmos', 'capitulos': 150},
    {'nome': 'Obadias', 'capitulos': 1},
  ];

  test('totalDeCapitulos soma os capítulos do índice', () {
    expect(totalDeCapitulos(indice), 201);
  });

  test('totalDeCapitulos ignora tipos inesperados', () {
    expect(
      totalDeCapitulos([
        {'nome': 'A', 'capitulos': 10},
        {'nome': 'B', 'capitulos': 'x'},
        {'nome': 'C', 'capitulos': null},
      ]),
      10,
    );
  });

  test('contarCapitulosLidos conta apenas chaves válidas (ignora órfãs)', () {
    final lidos = {'Gênesis 1', 'Gênesis 50', 'Obadias 1', 'Fantasma 1:1'};
    expect(contarCapitulosLidos(indice, lidos), 3);
  });

  test('fracaoLida calcula a proporção 0..1', () {
    expect(
      fracaoLida(indice, {'Gênesis 1', 'Gênesis 2'}),
      closeTo(2 / 201, 0.0001),
    );
    expect(fracaoLida(indice, {}), 0);
    expect(fracaoLida([], {'X 1'}), 0);
  });
}
