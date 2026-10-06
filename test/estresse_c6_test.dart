import 'dart:convert';

import 'package:biblia_diaria/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cobertura do caso C6 da matriz de QA (tool/QA_EDGE_CASES.md → T013):
/// estresse de navegação da Bíblia completa — expandir os 66 livros com os
/// assets reais (Gênesis → Apocalipse), percorrer versículos e rolar a lista,
/// sem exceção nem estado preso.
///
/// UM ÚNICO `testWidgets` por arquivo (regra do `runAsync` — ver
/// `specs/001-biblia-diaria-baseline/quickstart.md`, seção 5): cada expansão
/// dispara `rootBundle.loadString` + `jsonDecode` reais, que só completam no
/// loop nativo via `tester.runAsync` — o relógio fake do framework nunca causa
/// timeout no carregamento dos assets.
///
/// Os três blocos de asserção exigidos pelo caso:
///  1. Integridade de carga de assets (rootBundle): decodificar os 66 JSONs
///     (do Gênesis ao Apocalipse) devolve Map/List válidos, sem
///     `AssetBundleException` nem `FormatException`;
///  2. Resiliência da árvore de UI (widget lifecycle): após a expansão
///     sequencial e o scroll rápido por blocos, `tester.takeException() ==
///     null` (nenhum widget corrompido) e os componentes essenciais (AppBar,
///     NavigationBar, cartões de livros) seguem montados;
///  3. Ausência de exceções silenciosas (leak & crash): todo o bloco roda sob
///     `try/catch` lógico e o teste finaliza o framework (`pumpWidget(SizedBox)`)
///     garantindo que não sobram exceções pendentes pós-dispose.
Future<void> aguardarWidget(WidgetTester tester, Finder finder) async {
  for (var tentativa = 0; tentativa < 100; tentativa++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget esperado não apareceu: $finder');
}

/// Bloco 1 — integridade de carga de assets.
///
/// Lê o índice e, para cada um dos 66 livros (na ordem canônica), decodifica
/// `assets/data/livros/<nome>.json`. Qualquer falha de I/O (`AssetBundleException`)
/// ou de decodificação (`FormatException`) é coletada e falha o teste com o
/// nome do livro — a UI nunca vê essas exceções porque o app as engole com
/// try/catch e cai no fallback, então o único jeito de detectá-las é ler o
/// asset diretamente aqui, dentro de `runAsync` (loop nativo, sem timeout do
/// relógio de teste). Devolve os nomes na ordem do índice.
Future<List<String>> validarIntegridadeDosAssets(WidgetTester tester) async {
  final falhas = <String>[];
  final nomes = await tester.runAsync(() async {
    final lista = <String>[];
    final indiceRaw = await rootBundle.loadString('assets/data/indice.json');
    final indice = jsonDecode(indiceRaw);
    if (indice is! List) {
      falhas.add('indice.json: raiz não é uma List');
      return lista;
    }

    for (final entrada in indice) {
      if (entrada is! Map) {
        falhas.add('indice.json: entrada não é um Map');
        continue;
      }
      final nome = '${entrada['nome']}';
      if (nome.trim().isEmpty) continue;
      lista.add(nome);

      final caminho = 'assets/data/livros/$nome.json';
      try {
        final raw = await rootBundle.loadString(caminho);
        final decodificado = jsonDecode(raw);
        if (decodificado is! Map) {
          falhas.add('$nome: raiz do JSON não é um Map');
          continue;
        }
        final livro = Map<String, dynamic>.from(decodificado);
        if (livro['nome'] != nome) {
          falhas.add('$nome: campo "nome" diverge do índice');
        }
        if (livro['capitulos'] is! List) {
          falhas.add('$nome: campo "capitulos" não é uma List');
        }
      } on FlutterError catch (e) {
        // O rootBundle (desta versão do Flutter) sinaliza asset ausente com
        // FlutterError('Unable to load asset: ...') — a exceção histórica
        // AssetBundleException do requisito C6 cai aqui também (mesmo cenário:
        // arquivo faltando/ilegível em assets/data/livros/).
        falhas.add('$nome: falha de leitura do asset ($caminho): $e');
      } on FormatException catch (e) {
        falhas.add('$nome: FormatException ao decodificar $caminho ($e)');
      } catch (e) {
        falhas.add('$nome: ${e.runtimeType} ao ler $caminho ($e)');
      }
    }
    return lista;
  });

  expect(
    falhas,
    isEmpty,
    reason: 'C6 (assets): falhas ao decodificar os 66 livros:\n'
        '${falhas.join('\n')}',
  );
  final livros = nomes ?? const <String>[];
  expect(
    livros,
    hasLength(66),
    reason: 'C6 (assets): o índice deve listar os 66 livros.',
  );
  expect(livros.first, 'Gênesis');
  expect(livros.last, 'Apocalipse');
  return livros;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => call.method == 'getVoices' ? <Object>[] : 1,
    );
  });

  testWidgets(
    'C6: expandir os 66 livros (Gênesis→Apocalipse) com assets reais, '
    'rolar a lista e finalizar sem exceção nem estado preso',
    (tester) async {
      // Bloco 3 (leak & crash): o corpo inteiro roda sob um try/catch lógico.
      // Cada fase grava em [falhas] e o assert final garante que nada
      // "silencioso" passou; o finally força o dispose do app para verificar
      // que o framework finaliza sem exceções pendentes.
      final falhas = <String>[];

      try {
        // ---- Bloco 1: integridade de carga de assets (rootBundle) ----
        final nomes =
            await validarIntegridadeDosAssets(tester); // 66 livros válidos.

        // ---- App: abre e vai para a aba Bíblia ----
        await tester.pumpWidget(const BibliaApp());
        await aguardarWidget(tester, find.text('Bíblia Diária'));
        await tester.tap(find.text('Bíblia').last);
        await tester.pump();
        await aguardarWidget(tester, find.text('Gênesis'));
        expect(
          tester.takeException(),
          isNull,
          reason: 'C6 (UI): exceção ao abrir a aba Bíblia.',
        );

        final lista = find.byType(ListView).first;

        // ---- Bloco 2: expansão sequencial dos 66 livros ----
        // Um livro por vez: expande (FutureBuilder → rootBundle → jsonDecode),
        // espera o conteúdo real decodificar e montar, valida a árvore e
        // recolhe antes de avançar — assim a subárvore pesada (todos os
        // capítulos/versículos do livro) é descartada pelo ListView ao sair do
        // cache, mantendo o estresse com memória limitada.
        var livrosCarregados = 0;
        for (final nome in nomes) {
          // Rolagem até o cartão do livro ficar montado e tocável.
          await tester.dragUntilVisible(
            find.text(nome),
            lista,
            const Offset(0, -140),
            maxIteration: 300,
          );
          await tester.ensureVisible(find.text(nome));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'C6 (UI): exceção ao rolar até $nome.',
          );

          // Expande o livro: dispara o carregamento sob demanda do asset.
          await tester.tap(find.text(nome));
          await tester.pump();

          // Aguarda a decodificação real (runAsync) montar o primeiro
          // versículo ("$nome 1:1"). Sem runAsync, o rootBundle nunca
          // completaria no relógio fake e o teste daria timeout.
          //
          // A renderização é lazy (ListView.builder): o conteúdo recém-expandido
          // pode nascer fora da viewport — p.ex. o último livro (Apocalipse),
          // cujo cabeçalho fica no rodapé da lista. Além de aguardar a carga,
          // revela o trecho abaixo do cabeçalho para montar o marcador.
          final marcador = find.text('$nome 1:1');
          var carregou = false;
          for (var tentativa = 0; tentativa < 300; tentativa++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.pump();
            if (marcador.evaluate().isNotEmpty) {
              carregou = true;
              break;
            }
            if (tentativa % 5 == 0) {
              await tester.drag(lista, const Offset(0, -120));
              await tester.pump();
            }
            if (tester.takeException() != null) break;
          }

          expect(
            carregou,
            isTrue,
            reason: 'C6: "$nome" não decodificou/renderizou dentro do prazo '
                '(AssetBundleException/FormatException virariam o fallback '
                '"Não foi possível carregar este livro.").',
          );
          expect(
            find.text('$nome 1:1'),
            findsWidgets,
            reason: 'C6 (UI): conteúdo de $nome deve estar montado.',
          );
          expect(
            find.text('Não foi possível carregar este livro.'),
            findsNothing,
            reason: 'C6 (UI): $nome falhou ao carregar o asset.',
          );
          expect(
            tester.takeException(),
            isNull,
            reason:
                'C6 (UI): exceção de framework durante a expansão de $nome.',
          );

          livrosCarregados++;

          // Recolhe o livro: encerra a animação e devolve a lista a ~1 linha
          // por livro (os filhos viram offstage até o item sair do cache).
          await tester.ensureVisible(find.text(nome));
          await tester.pumpAndSettle();
          await tester.tap(find.text(nome));
          await tester.pump();
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'C6 (UI): exceção ao recolher $nome.',
          );
        }
        expect(
          livrosCarregados,
          66,
          reason: 'C6: todos os 66 livros precisam carregar no estresse.',
        );

        // ---- Bloco 2b: scroll rápido por blocos (lifecycle churn) ----
        // Recolhida a árvore, percorre a lista inteira em flings: os cartões
        // no topo foram descartados pelo ListView durante a expansão e agora
        // são RECRIADOS ao voltar — o ciclo de vida completo é exercitado.
        for (var i = 0; i < 8; i++) {
          await tester.fling(lista, const Offset(0, -6000), 6000);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'C6 (UI): exceção no scroll rápido para o fim da lista.',
          );
        }
        for (var i = 0;
            i < 12 && find.text('Gênesis').evaluate().isEmpty;
            i++) {
          await tester.fling(lista, const Offset(0, 6000), 6000);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'C6 (UI): exceção no scroll rápido para o início.',
          );
        }

        // Componentes essenciais continuam montados após o estresse.
        expect(find.text('Gênesis'), findsWidgets,
            reason: 'C6 (UI): cartão do Gênesis recriado ao voltar ao topo.');
        expect(find.text('Bíblia Diária'), findsOneWidget,
            reason: 'C6 (UI): AppBar deve continuar montada.');
        for (final aba in const ['Início', 'Bíblia', 'Salvos', 'Ajustes']) {
          expect(find.text(aba), findsWidgets,
              reason: 'C6 (UI): destino "$aba" da NavigationBar montado.');
        }
        expect(tester.takeException(), isNull,
            reason: 'C6 (UI): árvore corrompida após o estresse.');

        // Troca rápida de abas: nenhum estado preso nem rebuild quebrado.
        for (final aba in const ['Início', 'Salvos', 'Ajustes', 'Bíblia']) {
          await tester.tap(find.text(aba).last);
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: 'C6 (UI): exceção ao voltar para a aba $aba.');
        }
        await aguardarWidget(tester, find.text('Gênesis'));
      } catch (e) {
        // Bloco 3 (leak & crash): nada de falha silenciosa — qualquer exceção
        // lógica vira uma entrada explícita para o assert final.
        falhas.add('$e');
      } finally {
        // Bloco 3: o framework precisa finalizar sem exceções pendentes.
        // Descarta a árvore (dispose de _BibliaAppState) e drena o último
        // frame — "setState after dispose", futures pendentes pós-dispose ou
        // vazamentos apareceriam aqui.
        if (find.byType(BibliaApp).evaluate().isNotEmpty) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
      }

      expect(
        falhas,
        isEmpty,
        reason: 'C6 (leak/crash): falha silenciosa detectada no estresse:\n'
            '${falhas.join('\n')}',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'C6 (leak/crash): framework finalizou com exceção pendente.',
      );
    },
    // Expansão + decodificação dos 66 assets reais exige janela folgada.
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
