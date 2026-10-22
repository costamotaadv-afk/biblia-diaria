import 'package:biblia_diaria/tema.dart';
import 'package:flutter_test/flutter_test.dart';

/// Caso U1 da matriz de QA: o texto bíblico e os estudos usam fonte serifada
/// com altura de linha confortável (≥ 1.5) para leitura contínua.
void main() {
  test('versículo usa fonte serifada com altura ≥ 1.5', () {
    expect(estiloVersiculo.fontFamily, fonteSerifada);
    expect(estiloVersiculo.height, greaterThanOrEqualTo(1.5));
  });

  test('corpo de estudo usa fonte serifada com altura ≥ 1.5', () {
    expect(estiloCorpoEstudo.fontFamily, fonteSerifada);
    expect(estiloCorpoEstudo.height, greaterThanOrEqualTo(1.5));
  });

  test('a fonte serifada está configurada', () {
    expect(fonteSerifada, isNotEmpty);
  });
}
