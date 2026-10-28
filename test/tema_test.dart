import 'package:biblia_diaria/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Garantias da paleta e da escala de texto (casos U2/U6 da matriz de QA):
/// contraste WCAG AA, ausência de branco/preto puros e teto de escala.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('escalaDeTexto', () {
    test('escala padrão 1.18 + sistema 1.0 → 1.18 (comportamento preservado)', () {
      expect(escalaDeTexto(escalaLeitura: 1.18, escalaSistema: 1.0), 1.18);
    });

    test('escala mínima 1.0 + sistema 1.0 → 1.0', () {
      expect(escalaDeTexto(escalaLeitura: 1.0, escalaSistema: 1.0), 1.0);
    });

    test('compõe com a escala do sistema até o teto de 2.0', () {
      expect(
        escalaDeTexto(escalaLeitura: 1.18, escalaSistema: 1.3),
        closeTo(1.534, 0.001),
      );
      expect(escalaDeTexto(escalaLeitura: 1.0, escalaSistema: 2.5), 2.0);
    });
  });

  group('razaoContraste', () {
    test('preto sobre branco = 21:1', () {
      expect(razaoContraste(Colors.black, Colors.white), closeTo(21.0, 0.01));
    });

    test('cor idêntica = 1:1', () {
      expect(razaoContraste(Colors.grey, Colors.grey), closeTo(1.0, 0.001));
    });
  });

  group('paleta (U2)', () {
    final claro = construirTema(Brightness.light);
    final escuro = construirTema(Brightness.dark);

    test('fundo claro não é branco puro; escuro não é preto puro', () {
      expect(claro.colorScheme.surface, isNot(const Color(0xFFFFFFFF)));
      expect(escuro.colorScheme.surface, isNot(const Color(0xFF000000)));
    });

    test('contraste de leitura ≥ 4.5:1 nos pares críticos', () {
      expect(
        razaoContraste(
          claro.colorScheme.onSurface,
          claro.colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        razaoContraste(
          claro.colorScheme.onSurfaceVariant,
          claro.colorScheme.surface,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        razaoContraste(claro.colorScheme.primary, claro.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        razaoContraste(claro.colorScheme.onPrimary, claro.colorScheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        razaoContraste(escuro.colorScheme.onSurface, escuro.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        razaoContraste(escuro.colorScheme.primary, escuro.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
