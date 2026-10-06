import 'package:biblia_diaria/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Caso E15 da matriz de QA (estresse): a tela "Salvos" com muitos favoritos
/// precisa carregar e renderizar sem travar nem lançar exceção. Usa 200
/// favoritos de um único livro para exercitar a lista sem carregar os 13MB.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => call.method == 'getVoices' ? <Object>[] : 1,
    );
  });

  testWidgets('E15: favoritos mistos (versículos + capítulos) carregam e removem',
      (tester) async {
    // 200 versículos + 50 capítulos de Gênesis (carga mista, mesmo livro para
    // que só um arquivo seja carregado e o teste continue rápido).
    final versiculos = List<String>.generate(
      200,
      (i) => 'Gênesis ${(i % 50) + 1}:${(i % 31) + 1}',
    );
    final capitulos = List<String>.generate(50, (i) => 'Gênesis ${i + 1}');
    SharedPreferences.setMockInitialValues({
      'favoritos_versiculos': versiculos,
      'favoritos_capitulos': capitulos,
    });

    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    await tester.tap(find.text('Salvos').last);
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Seção de capítulos no topo; a de versículos fica abaixo (fora da viewport).
    expect(find.text('Capítulos salvos'), findsOneWidget);

    final lista = find.byType(ListView).last;
    await tester.dragUntilVisible(
      find.text('Versículos salvos'),
      lista,
      const Offset(0, -300),
      maxIteration: 100,
    );
    await tester.pump();
    expect(find.text('Versículos salvos'), findsOneWidget);

    final ordenados = versiculos.toList()..sort();
    final primeiroChave = ordenados.first;
    await tester.dragUntilVisible(
      find.text(primeiroChave),
      lista,
      const Offset(0, -200),
      maxIteration: 100,
    );
    await tester.pump();

    // Todos os itens visíveis carregam o conteúdo: o placeholder some.
    for (var tentativa = 0; tentativa < 100; tentativa++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (find.textContaining('Carregando versículo...').evaluate().isEmpty) {
        break;
      }
    }
    expect(find.textContaining('Carregando versículo...'), findsNothing);
    expect(find.textContaining('princípio'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Remoção no meio da lista: o item some sem perda nem jank.
    final deleteDoAlvo = find.descendant(
      of: find.ancestor(
        of: find.text(primeiroChave),
        matching: find.byType(Card),
      ),
      matching: find.byTooltip('Remover versículo salvo'),
    );
    await tester.ensureVisible(deleteDoAlvo.first);
    await tester.pump();
    await tester.tap(deleteDoAlvo.first);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(primeiroChave), findsNothing);

    // Rola até o fim da lista para renderizar os itens de baixo.
    await tester.fling(
      find.byType(ListView).last,
      const Offset(0, -3000),
      3000,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
