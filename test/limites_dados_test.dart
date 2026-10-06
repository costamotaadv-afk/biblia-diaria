import 'package:biblia_diaria/dados_seguros.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cobertura dos casos E1–E4 (dados malformados), E13 (dias negativos/extremos)
/// e B5 (determinismo do versículo do dia) da matriz de QA
/// (tool/QA_EDGE_CASES.md) via funções puras de lib/dados_seguros.dart.
void main() {
  final livroGenesis = <String, dynamic>{
    'nome': 'Gênesis',
    'capitulos': [
      {
        'numero': 1,
        'versiculos': [
          {'numero': 1, 'texto': 'No princípio, criou Deus o céu e a terra.'},
          {'numero': 2, 'texto': 'A terra, porém, estava sem forma e vazia.'},
        ],
      },
      {
        'numero': 2,
        'versiculos': [
          {'numero': 1, 'texto': 'Assim foram acabados os céus e a terra.'},
        ],
      },
    ],
  };

  group('comoLista — cast seguro contra tipo errado (E3/E4)', () {
    test('aceita lista normalmente', () {
      expect(comoLista(<dynamic>[1, 2, 3]), [1, 2, 3]);
    });

    test('objeto/string/número/null → null, sem TypeError', () {
      expect(comoLista(<String, Object>{'errado': true}), isNull);
      expect(comoLista('texto'), isNull);
      expect(comoLista(42), isNull);
      expect(comoLista(null), isNull);
    });
  });

  group('diasDesdeEpoca (E13/B5)', () {
    test('época 01/01/2024 = dia 0; 02/01 = dia 1', () {
      expect(diasDesdeEpoca(DateTime(2024, 1, 1)), 0);
      expect(diasDesdeEpoca(DateTime(2024, 1, 2)), 1);
    });

    test('antes da época → negativo, sem RangeError', () {
      expect(diasDesdeEpoca(DateTime(2023, 12, 31)), -1);
      expect(diasDesdeEpoca(DateTime(2023, 6, 15)), lessThan(0));
    });

    test('data extrema (ano 9999) não estoura', () {
      expect(diasDesdeEpoca(DateTime(9999, 12, 31)), greaterThan(0));
    });

    test('determinismo: mesma data → mesmo valor', () {
      expect(
        diasDesdeEpoca(DateTime(2025, 3, 10)),
        diasDesdeEpoca(DateTime(2025, 3, 10)),
      );
    });
  });

  group('selecionarVersiculoDoDia', () {
    test('E1/E2: livro nulo → "Carregando conteúdo..." sem crash', () {
      final r = selecionarVersiculoDoDia(dia: 0, mensagens: [], livro: null);
      expect(r['versiculo'], 'Carregando conteúdo...');
      expect(r['referencia'], '');
      expect(r['mensagem'], 'Deus te fortaleça neste dia.');
    });

    test('E3: capitulos como objeto (tipo errado) → "Sem conteúdo"', () {
      final r = selecionarVersiculoDoDia(
        dia: 0,
        mensagens: [],
        livro: <String, dynamic>{'nome': 'Gênesis', 'capitulos': {'errado': true}},
      );
      expect(r['versiculo'], 'Sem conteúdo bíblico disponível.');
    });

    test('E3: capitulos ausente → "Sem conteúdo" sem crash', () {
      final r = selecionarVersiculoDoDia(
        dia: 0,
        mensagens: [],
        livro: <String, dynamic>{'nome': 'Gênesis'},
      );
      expect(r['versiculo'], 'Sem conteúdo bíblico disponível.');
    });

    test('E4: versículos vazios → "Sem conteúdo" sem crash', () {
      final r = selecionarVersiculoDoDia(
        dia: 0,
        mensagens: [],
        livro: <String, dynamic>{
          'nome': 'Gênesis',
          'capitulos': [
            {'numero': 1, 'versiculos': <dynamic>[]},
          ],
        },
      );
      expect(r['versiculo'], 'Sem conteúdo bíblico disponível.');
    });

    test('versículos com itens não-Map → "Sem conteúdo" sem crash', () {
      final r = selecionarVersiculoDoDia(
        dia: 0,
        mensagens: [],
        livro: <String, dynamic>{
          'nome': 'Gênesis',
          'capitulos': [
            {'numero': 1, 'versiculos': [1, 2, 3]},
          ],
        },
      );
      expect(r['versiculo'], 'Sem conteúdo bíblico disponível.');
    });

    test('T010/E3: capítulo SORTEADO do dia não-Map → fallback sem crash', () {
      // dia 66 → (66 ~/ 66) % 2 == 1 → capitulos[1], que é item primitivo
      // solto no índice (mesmo tipo de corrupção do E3, agora no fluxo diário).
      final r = selecionarVersiculoDoDia(
        dia: 66,
        mensagens: [],
        livro: <String, dynamic>{
          'nome': 'Gênesis',
          'capitulos': <dynamic>[
            {
              'numero': 1,
              'versiculos': <dynamic>[
                {'numero': 1, 'texto': 'ok'},
              ],
            },
            'corrompido',
          ],
        },
      );
      expect(r['versiculo'], 'Sem conteúdo bíblico disponível.');
      expect(r['referencia'], '');
    });

    test('T012/E4: capítulo sorteado com versículos vazios → fallback e '
        'referência vazia (botões desabilitados na Home)', () {
      // dia 66 sorteia capitulos[1] (capítulo 2), cujo versiculos é vazio.
      final r = selecionarVersiculoDoDia(
        dia: 66,
        mensagens: [],
        livro: <String, dynamic>{
          'nome': 'Gênesis',
          'capitulos': <dynamic>[
            {
              'numero': 1,
              'versiculos': <dynamic>[
                {'numero': 1, 'texto': 'ok'},
              ],
            },
            {'numero': 2, 'versiculos': <dynamic>[]},
          ],
        },
      );
      expect(r['versiculo'], 'Sem conteúdo bíblico disponível.');
      // Referência vazia é o contrato que mantém "Ouvir"/"Salvar"
      // desabilitados na Home (onPressed: null quando referencia.isEmpty).
      expect(r['referencia'], '');
      expect(r['mensagem'], isNotEmpty);
    });

    test('B5: ciclo determinístico (livro retorna a cada 66 dias; versículo a cada 132)', () {
      // dia 0: cap (0~/66)%2=0, vers (0~/132)%2=0 → Gênesis 1:1
      expect(
        selecionarVersiculoDoDia(dia: 0, mensagens: [], livro: livroGenesis)
            ['referencia'],
        'Gênesis 1:1',
      );
      // A cada 66 dias o livro retorna e o capítulo avança.
      expect(
        selecionarVersiculoDoDia(dia: 66, mensagens: [], livro: livroGenesis)
            ['referencia'],
        'Gênesis 2:1',
      );
      // Versículo avança a cada 66 × número de capítulos = 132 dias.
      expect(
        selecionarVersiculoDoDia(dia: 132, mensagens: [], livro: livroGenesis)
            ['referencia'],
        'Gênesis 1:2',
      );
      // Ciclo completo: dia 264 volta a Gênesis 1:1 (determinismo).
      expect(
        selecionarVersiculoDoDia(dia: 264, mensagens: [], livro: livroGenesis)
            ['referencia'],
        'Gênesis 1:1',
      );
    });

    test('E13: dia negativo → sem RangeError e determinístico', () {
      final r = selecionarVersiculoDoDia(
        dia: -1,
        mensagens: [],
        livro: livroGenesis,
      );
      expect(r['referencia'], isNotEmpty);
      expect(
        r,
        selecionarVersiculoDoDia(dia: -1, mensagens: [], livro: livroGenesis),
      );
    });

    test('mensagens: fallback vazio e índice circular', () {
      expect(
        selecionarVersiculoDoDia(dia: 0, mensagens: [], livro: livroGenesis)
            ['mensagem'],
        'Deus te fortaleça neste dia.',
      );
      expect(
        selecionarVersiculoDoDia(
          dia: 1,
          mensagens: ['M1', 'M2'],
          livro: null,
        )['mensagem'],
        'M2',
      );
    });

    test('E5: versículo com texto vazio/só espaços → "Sem conteúdo"', () {
      final r = selecionarVersiculoDoDia(
        dia: 0,
        mensagens: [],
        livro: <String, dynamic>{
          'nome': 'Gênesis',
          'capitulos': [
            {
              'numero': 1,
              'versiculos': [
                {'numero': 1, 'texto': '   '},
              ],
            },
          ],
        },
      );
      expect(r['versiculo'], 'Sem conteúdo bíblico disponível.');
      expect(r['referencia'], '');
    });
  });

  group('normalizarMensagens (E8/E9)', () {
    test('E9: itens não-string são descartados (sem "Instance of...")', () {
      expect(
        normalizarMensagens([123, {'a': 1}, null, 'Ola  ', '  ']),
        ['Ola  '],
      );
    });

    test('E8: lista vazia ou não-lista → vazia (UI usa fallback padrão)', () {
      expect(normalizarMensagens([]), isEmpty);
      expect(normalizarMensagens('nao-e-lista'), isEmpty);
      expect(normalizarMensagens(null), isEmpty);
    });

    test('aceita apenas strings não-vazias', () {
      expect(
        normalizarMensagens(['Deus te abençoe.', '', '   ', 'Segunda']),
        ['Deus te abençoe.', 'Segunda'],
      );
    });
  });
}
