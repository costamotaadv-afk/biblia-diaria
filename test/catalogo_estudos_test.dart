import 'package:biblia_diaria/catalogo_estudos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsing defensivo (EST1/EST2)', () {
    test('EST1: entrada não-lista vira catálogo vazio', () {
      expect(recursosDeJson(null), isEmpty);
      expect(recursosDeJson('texto'), isEmpty);
      expect(recursosDeJson(<dynamic>[]), isEmpty);
    });

    test('EST2: itens inválidos são ignorados', () {
      final entrada = <dynamic>[
        'texto',
        42,
        null,
        {'id': '', 'titulo': 'sem id'},
        {'titulo': 'sem id 2'},
        {'id': 'ok', 'tipo': 'nota', 'titulo': 'Válido', 'corpo': 'x'},
      ];

      final recursos = recursosDeJson(entrada);

      expect(recursos.length, 1);
      expect(recursos.single.id, 'ok');
    });

    test('EST2: tipos errados não lançam', () {
      final recursos = recursosDeJson([
        {
          'id': 'a',
          'tipo': 7,
          'titulo': true,
          'tema': 'não-lista',
          'fonte': 'x',
        },
      ]);

      expect(recursos.length, 1);
      expect(recursos.single.temas, isEmpty);
      expect(recursos.single.fonte, isNull);
    });
  });

  group('corpo e fonte (EST4)', () {
    test('EST4: corpo vazio ou só espaços → sem conteúdo', () {
      final vazio = recursosDeJson([{'id': 'a', 'corpo': '   '}]).single;
      expect(vazio.temCorpo, isFalse);
    });

    test('corpo preenchido → tem conteúdo', () {
      final cheio = recursosDeJson([{'id': 'a', 'corpo': 'Olá'}]).single;
      expect(cheio.temCorpo, isTrue);
    });

    test('fonte parcial vira crédito legível; fonte ausente é null', () {
      final comFonte = recursosDeJson([
        {
          'id': 'a',
          'fonte': {'autor': 'Autor', 'obra': 'Obra', 'ano': '2026'},
        },
      ]).single;
      expect(comFonte.temFonte, isTrue);
      expect(comFonte.fonte!.credito, 'Autor, Obra (2026)');

      final semFonte = recursosDeJson([{'id': 'b'}]).single;
      expect(semFonte.temFonte, isFalse);
    });
  });

  group('casamento de referência (EST3)', () {
    const recursos = <RecursoEstudo>[
      RecursoEstudo(
        id: 'v',
        tipo: 'nota',
        titulo: '',
        corpo: 'c',
        referencia: 'João 3:16',
        livro: 'João',
      ),
      RecursoEstudo(
        id: 'c',
        tipo: 'comentario',
        titulo: '',
        corpo: 'c',
        referencia: 'João 3',
        livro: 'João',
      ),
      RecursoEstudo(
        id: 'l',
        tipo: 'artigo',
        titulo: '',
        corpo: 'c',
        referencia: 'João',
        livro: 'João',
      ),
      RecursoEstudo(
        id: 'n',
        tipo: 'nota',
        titulo: '',
        corpo: 'c',
        referencia: '1 João 4:8',
        livro: '1 João',
      ),
    ];

    test('EST3: versículo herda recursos de capítulo e de livro', () {
      final ids = recursosAplicaveis(recursos, 'João 3:16', livro: 'João')
          .map((r) => r.id)
          .toSet();
      expect(ids, {'v', 'c', 'l'});
    });

    test('EST3: prefixo numérico não confunde o casamento', () {
      final ids = recursosAplicaveis(recursos, '1 João 4:8', livro: '1 João')
          .map((r) => r.id)
          .toSet();
      expect(ids, {'n'});
    });

    test('capituloDaReferencia extrai o capítulo apenas de versículos', () {
      expect(capituloDaReferencia('João 3:16'), 'João 3');
      expect(capituloDaReferencia('João 3'), isNull);
      expect(capituloDaReferencia('João'), isNull);
    });
  });

  group('tipos, agrupamento e filtros (EST5/EST6)', () {
    test('EST6: tipo conhecido tem rótulo fixo; desconhecido é capitalizado', () {
      expect(rotuloTipo('sermao'), 'Sermão');
      expect(rotuloTipo('momento_historico'), 'Momento histórico');
      expect(rotuloTipo('devocional'), 'Devocional');
      expect(rotuloTipo(''), 'Estudo');
    });

    test('EST5: agrupamento põe tipos conhecidos primeiro, de forma estável', () {
      final recursos = recursosDeJson([
        {'id': '1', 'tipo': 'devocional'},
        {'id': '2', 'tipo': 'artigo'},
        {'id': '3', 'tipo': 'nota'},
      ]);

      expect(
        agruparPorTipo(recursos).keys.toList(),
        ['nota', 'artigo', 'devocional'],
      );
    });

    test('EST5: filtros por tipo e por livro são determinísticos', () {
      final recursos = recursosDeJson([
        {'id': '1', 'tipo': 'nota', 'livro': 'João'},
        {'id': '2', 'tipo': 'artigo', 'livro': 'Salmos'},
      ]);

      expect(filtrarRecursos(recursos, tipo: 'nota').single.id, '1');
      expect(filtrarRecursos(recursos, livro: 'Salmos').single.id, '2');
      expect(filtrarRecursos(recursos, tipo: 'sermao'), isEmpty);
      expect(tiposDisponiveis(recursos), ['nota', 'artigo']);
      expect(livrosDisponiveis(recursos), ['João', 'Salmos']);
    });
  });
}
