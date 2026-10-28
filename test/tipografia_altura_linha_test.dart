import 'package:biblia_diaria/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Garantias do espaçamento de linha ajustável (Phase 2b).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('construirTema expõe TipografiaLeitura com a altura informada', () {
    final tema = construirTema(Brightness.light, alturaLinha: 1.5);
    expect(tema.extension<TipografiaLeitura>()?.alturaLinha, 1.5);
  });

  test('altura padrão = 1.65 quando não informada', () {
    final tema = construirTema(Brightness.dark);
    expect(
      tema.extension<TipografiaLeitura>()?.alturaLinha,
      alturaLinhaPadrao,
    );
  });

  test('limites do espaçamento (1.4–1.8)', () {
    expect(alturaLinhaMinima, 1.4);
    expect(alturaLinhaMaxima, 1.8);
  });
}
