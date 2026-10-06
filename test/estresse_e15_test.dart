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

  testWidgets('E15: 200 favoritos na tela Salvos carregam sem travar',
      (tester) async {
    // 200 versículos de Gênesis já salvos (todos no mesmo livro, para que só
    // um arquivo seja carregado e o teste continue rápido).
    final favoritos = List<String>.generate(
      200,
      (i) => 'Gênesis ${(i % 50) + 1}:${(i % 31) + 1}',
    );
    SharedPreferences.setMockInitialValues({
      'favoritos_versiculos': favoritos,
    });

    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    await tester.tap(find.text('Salvos').last);
    await tester.pump();
    expect(tester.takeException(), isNull);

    // A tela "Salvos" ordena as chaves por texto (comportamento do app), então
    // "Gênesis 10:10" vem antes de "Gênesis 1:1" (o dígito '0' < ':'). O primeiro
    // item visível precisa resolver com o texto real do versículo.
    final ordenados = favoritos.toList()..sort();
    final primeiroChave = ordenados.first;
    await aguardarWidget(tester, find.text(primeiroChave));

    // Todos os itens visíveis carregam o conteúdo: o placeholder "Carregando..."
    // some assim que o livro Gênesis é carregado no cache.
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

    // Garante que conteúdo real foi renderizado (não "Conteúdo não encontrado.").
    expect(find.textContaining('princípio'), findsWidgets);
    expect(tester.takeException(), isNull);

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
