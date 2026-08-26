import 'package:biblia_diaria/config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Casos B3 (validação da chave Pix) e B8 (IDs de anúncio de teste em release)
/// da matriz de QA — regras de negócio puras de lib/config.dart.
void main() {
  group('B3 — chave Pix', () {
    test('a chave configurada é um e-mail válido', () {
      expect(
        chavePixValida(chavePix),
        isTrue,
        reason: 'A chave Pix do app não pode ser inválida em produção.',
      );
    });

    test('rejeita formatos inválidos', () {
      expect(chavePixValida('sem-arroba'), isFalse);
      expect(chavePixValida('123'), isFalse);
      expect(chavePixValida('a@b'), isFalse); // sem domínio com ponto
      expect(chavePixValida(''), isFalse);
      expect(chavePixValida('nome@dominio sem ponto'), isFalse);
    });
  });

  group('B8 — IDs de anúncio', () {
    test('IDs de TESTE do Google são bloqueados em release', () {
      expect(
        erroIdAnuncioEmProducao(
          isRelease: true,
          id: 'ca-app-pub-3940256099942544/6300978111',
        ),
        isNotNull,
      );
      expect(
        erroIdAnuncioEmProducao(
          isRelease: true,
          id: 'ca-app-pub-3940256099942544/2934735716',
        ),
        isNotNull,
      );
    });

    test('IDs de produção são aceitos em release', () {
      expect(
        erroIdAnuncioEmProducao(
          isRelease: true,
          id: 'ca-app-pub-1234567890123456/1234567890',
        ),
        isNull,
      );
    });

    test('em debug/desenvolvimento, IDs de teste não são bloqueados', () {
      expect(
        erroIdAnuncioEmProducao(
          isRelease: false,
          id: 'ca-app-pub-3940256099942544/6300978111',
        ),
        isNull,
      );
    });
  });
}
