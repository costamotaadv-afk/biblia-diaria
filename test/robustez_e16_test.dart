import 'package:biblia_diaria/dados_seguros.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cobertura do caso E16 da matriz de QA (tool/QA_EDGE_CASES.md):
/// robustez do parser de dados contra corrupção DENTRO de listas —
/// capítulo/versículo como dado primitivo solto (String/int/null) em vez de
/// Map estruturado. Garante o Invariante 2 de contracts/storage.md: nenhuma
/// exceção não tratada na UI; conteúdo ausente vira fallback amigável.
void main() {
  group('E16 — Robustez no parser de dados (contrato de storage/assets)', () {
    test('dados corrompidos em capitulos/versiculos não lançam TypeError', () {
      // JSON corrompido onde capítulos/versículos vêm como dados primitivos
      // soltos misturados a um Map estruturado válido.
      final livros = <Map<String, dynamic>>[
        {
          'nome': 'Gênesis',
          'capitulos': <dynamic>[
            'Isso deveria ser um Map de capítulo, mas é uma string',
            12345, // número solto
            null,
            {
              'numero': 1,
              'versiculos': <dynamic>[
                null, // versículo nulo
                10, // versículo como número em vez de Map
                {
                  'numero': 1,
                  'texto': 'No princípio criou Deus o céu e a terra.',
                }, // formato correto misturado
              ],
            },
          ],
        },
      ];

      // Guardiões de mapa filtram os itens malformados sem lançar TypeError.
      final capitulos = mapasSeguros(comoLista(livros.first['capitulos']));
      expect(capitulos, hasLength(1));
      expect(capitulos.single['numero'], 1);

      final versiculos =
          mapasSeguros(comoLista(capitulos.single['versiculos']));
      expect(versiculos, hasLength(1));
      expect(versiculos.single['texto'], contains('No princípio'));

      // Resolução ponta a ponta: o versículo válido é encontrado mesmo com
      // o restante da lista corrompido.
      expect(
        textoDeVersiculoEmLivros(livros, 'Gênesis 1:1'),
        contains('No princípio'),
      );
    });

    test(
        'Invariante 2: trecho ausente/corrompido retorna null (fallback na '
        'UI) e nunca lança exceção', () {
      // Livro com capítulo sem versículos: nada resolvível.
      final livroVazio = <Map<String, dynamic>>[
        {
          'nome': 'Gênesis',
          'capitulos': <dynamic>[
            {'numero': 1, 'versiculos': <dynamic>[]},
          ],
        },
      ];

      String? texto;
      expect(
        () => texto = textoDeVersiculoEmLivros(livroVazio, 'Gênesis 1:1'),
        returnsNormally,
      );
      // Camada de dados devolve null; a UI converte em "Conteúdo não
      // encontrado." (caso E14) — jamais exceção ou estado de carregamento.
      expect(texto, isNull);

      // Livro totalmente corrompido (nenhum capítulo mapeável).
      final livroCorrompido = <Map<String, dynamic>>[
        {
          'nome': 'Gênesis',
          'capitulos': <dynamic>[1, 'x', null],
        },
      ];
      expect(
        () => textoDeCapituloEmLivros(livroCorrompido, 'Gênesis 1'),
        returnsNormally,
      );
      expect(textoDeCapituloEmLivros(livroCorrompido, 'Gênesis 1'), isNull);
    });
  });
}
