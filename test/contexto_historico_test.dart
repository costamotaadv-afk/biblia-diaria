import 'dart:convert';
import 'dart:io';

import 'package:biblia_diaria/contexto_historico.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsing defensivo (CTX1/CTX2)', () {
    test('CTX1: entrada não-lista vira lista vazia', () {
      expect(contextosDeJson(null), isEmpty);
      expect(contextosDeJson('texto'), isEmpty);
      expect(contextosDeJson(<dynamic>[]), isEmpty);
    });

    test('CTX2: itens inválidos são ignorados', () {
      final contextos = contextosDeJson([
        'texto',
        42,
        null,
        {'id': '', 'salmo': 3},
        {'id': 'a', 'salmo': 0},
        {'id': 'ok', 'salmo': 3, 'titulo': 'T', 'certeza': 'tradicional'},
      ]);
      expect(contextos.length, 1);
      expect(contextos.single.id, 'ok');
    });

    test('CTX2: tipos errados em listas não lançam', () {
      final contexto = contextosDeJson([
        {
          'id': 'a',
          'salmo': 1,
          'classificacao': 'não-lista',
          'referencias_cruzadas': 'não-lista',
          'fontes': 'não-lista',
          'eventos': 'não-lista',
          'temas': 7,
        },
      ]).single;
      expect(contexto.classificacao, isEmpty);
      expect(contexto.referenciasCruzadas, isEmpty);
      expect(contexto.fontes, isEmpty);
      expect(contexto.eventos, isEmpty);
      expect(contexto.temas, isEmpty);
    });
  });

  group('grau de certeza (CTX3)', () {
    test('códigos válidos mapeiam para o enum', () {
      expect(certezaDeCodigo('documentado'), CertezaHistorica.documentado);
      expect(certezaDeCodigo('tradicional'), CertezaHistorica.tradicional);
      expect(certezaDeCodigo('hipotese'), CertezaHistorica.hipotese);
      expect(certezaDeCodigo('indeterminado'), CertezaHistorica.indeterminado);
    });

    test('código desconhecido/ausente cai em indeterminado', () {
      expect(certezaDeCodigo('outro'), CertezaHistorica.indeterminado);
      expect(certezaDeCodigo(null), CertezaHistorica.indeterminado);
      expect(certezaDeCodigo(''), CertezaHistorica.indeterminado);
    });

    test('rótulos e explicações são não-vazios', () {
      for (final certeza in CertezaHistorica.values) {
        expect(rotuloCerteza(certeza), isNotEmpty);
        expect(explicacaoCerteza(certeza), isNotEmpty);
      }
    });
  });

  group('análise de referência para navegação (CTX4)', () {
    const livros = ['Salmos', '2 Samuel', '1 Samuel', 'João', '1 Coríntios'];

    test('referência de capítulo e faixa resolvem para o capítulo inicial', () {
      final a = analisarReferencia('2 Samuel 15', livros);
      expect(a, isNotNull);
      expect(a!.livro, '2 Samuel');
      expect(a.capitulo, 15);
      expect(a.versiculo, isNull);

      final b = analisarReferencia('2 Samuel 15–18', livros);
      expect(b!.livro, '2 Samuel');
      expect(b.capitulo, 15);
    });

    test('referência de versículo resolve livro/capítulo/versículo', () {
      final a = analisarReferencia('João 3:16', livros);
      expect(a!.livro, 'João');
      expect(a.capitulo, 3);
      expect(a.versiculo, 16);
    });

    test('prefixo numérico não confunde o casamento', () {
      final a = analisarReferencia('1 Coríntios 13:4', livros);
      expect(a!.livro, '1 Coríntios');
      expect(a.capitulo, 13);
      expect(a.versiculo, 4);
    });

    test('livro desconhecido devolve null', () {
      expect(analisarReferencia('Hebreus 11', livros), isNull);
      expect(analisarReferencia('', livros), isNull);
    });
  });

  group('busca e consulta (CTX5/CTX6)', () {
    final contextos = contextosDeJson([
      {
        'id': 's3',
        'salmo': 3,
        'titulo': 'Confiança em Deus',
        'autoria': 'Davi',
        'personagens': ['Absalão'],
        'lugares': ['Jerusalém'],
        'explicacao': 'Fuga durante a revolta.',
      },
      {
        'id': 's90',
        'salmo': 90,
        'titulo': 'Oração de Moisés',
        'autoria': 'Moisés',
        'periodo': 'Período do deserto',
        'lugares': ['Sinai'],
      },
    ]);

    test('busca por personagem e lugar', () {
      expect(filtrarContextoPorBusca(contextos, 'Absalão').single.id, 's3');
      expect(filtrarContextoPorBusca(contextos, 'Sinai').single.id, 's90');
    });

    test('busca ignora caixa e acentos', () {
      expect(filtrarContextoPorBusca(contextos, 'MOISÉS').single.id, 's90');
      expect(filtrarContextoPorBusca(contextos, 'confianca').single.id, 's3');
    });

    test('busca por número', () {
      expect(filtrarContextoPorBusca(contextos, 'salmo 3').single.id, 's3');
    });

    test('busca vazia devolve todos na ordem original', () {
      final todos = filtrarContextoPorBusca(contextos, '');
      expect(todos.map((c) => c.numero).toList(), [3, 90]);
    });

    test('contextoDoSalmo é determinístico e tolerante', () {
      expect(contextoDoSalmo(contextos, 90)!.id, 's90');
      expect(contextoDoSalmo(contextos, 999), isNull);
    });
  });

  group('integridade dos dados (CTX7)', () {
    final arquivo = File('assets/data/contexto/Salmos.json');

    test('150 Salmos presentes, ids únicos e campos obrigatórios', () {
      expect(arquivo.existsSync(), isTrue,
          reason: 'assets/data/contexto/Salmos.json deve existir');
      final contextos =
          contextosDeJson(jsonDecode(arquivo.readAsStringSync()));
      expect(contextos.length, 150);

      final ids = <String>{};
      final numeros = <int>{};
      for (final c in contextos) {
        expect(ids.add(c.id), isTrue, reason: 'id duplicado ${c.id}');
        numeros.add(c.numero);
        expect(c.numero >= 1 && c.numero <= 150, isTrue);
        expect(c.titulo, isNotEmpty);
        expect(c.classificacao, isNotEmpty);
        expect(c.periodo, isNotEmpty);
        expect(c.contextoPolitico, isNotEmpty);
        expect(c.localizacao, isNotEmpty);
        expect(c.explicacao, isNotEmpty);
        expect(c.fontes, isNotEmpty);
      }
      for (var n = 1; n <= 150; n++) {
        expect(numeros.contains(n), isTrue, reason: 'Salmo $n ausente');
      }
    });

    test('referências cruzadas resolvem para livros conhecidos', () {
      final indice =
          jsonDecode(File('assets/data/indice.json').readAsStringSync());
      final nomes = (indice as List)
          .whereType<Map>()
          .map((m) => '${m['nome']}')
          .toList();
      final contextos =
          contextosDeJson(jsonDecode(arquivo.readAsStringSync()));
      for (final c in contextos) {
        for (final ref in c.referenciasCruzadas) {
          final alvo = analisarReferencia(ref.referencia, nomes);
          expect(alvo, isNotNull,
              reason: 'ref não resolvida: ${ref.referencia}');
        }
      }
    });
  });
}

