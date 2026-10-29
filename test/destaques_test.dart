import 'package:biblia_diaria/destaques.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paleta tem cores com hex válido (#RRGGBB)', () {
    expect(paletaDestaques, isNotEmpty);
    for (final hex in paletaDestaques.values) {
      expect(hex, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
    }
  });

  test('nomes de cor são estáveis (usados na persistência)', () {
    expect(paletaDestaques.keys.toSet(), {
      'amarelo',
      'verde',
      'azul',
      'rosa',
      'laranja',
    });
  });
}
