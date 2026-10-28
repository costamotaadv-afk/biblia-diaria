import 'package:biblia_diaria/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Garantias do tema sépia (novo modo de leitura) e do mapeamento de
/// persistência `ModoTema` (chave `modo_tema`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModoTema.deNome', () {
    test('mapeia os três valores persistidos', () {
      expect(ModoTema.deNome('claro'), ModoTema.claro);
      expect(ModoTema.deNome('escuro'), ModoTema.escuro);
      expect(ModoTema.deNome('sepia'), ModoTema.sepia);
    });

    test('valor nulo ou desconhecido → claro (fallback seguro)', () {
      expect(ModoTema.deNome(null), ModoTema.claro);
      expect(ModoTema.deNome('desconhecido'), ModoTema.claro);
    });
  });

  group('construirTemaSepia', () {
    test('é claro (Brightness.light) e distinto do tema claro padrão', () {
      final sepia = construirTemaSepia();
      final claro = construirTema(Brightness.light);
      expect(sepia.brightness, Brightness.light);
      expect(sepia.colorScheme.surface, isNot(claro.colorScheme.surface));
    });

    test('não usa branco/preto puros e mantém contraste ≥ 4.5:1', () {
      final sepia = construirTemaSepia();
      expect(sepia.colorScheme.surface, isNot(const Color(0xFFFFFFFF)));
      expect(sepia.colorScheme.surface, isNot(const Color(0xFF000000)));

      expect(
        razaoContraste(sepia.colorScheme.onSurface, sepia.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        razaoContraste(sepia.colorScheme.primary, sepia.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
