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

/// Caso U4 da matriz de QA: tocar em um versículo abre a folha de ações com
/// Ouvir/Copiar/Compartilhar/Favoritar; favoritar persiste e copiar usa o
/// clipboard (degradação graciosa).
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

  testWidgets('U4: folha de ações do versículo favorita e copia',
      (tester) async {
    String? textoCopiado;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          textoCopiado = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );

    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    // Abre Gênesis 1.
    await tester.tap(find.text('Bíblia').last);
    await tester.pump();
    await aguardarWidget(tester, find.text('Gênesis'));
    await tester.tap(find.text('Gênesis'));
    await aguardarWidget(tester, find.text('Capítulo 1'));

    // Toca no versículo → folha de ações.
    await tester.tap(find.textContaining('No princípio').first);
    await tester.pumpAndSettle();

    expect(find.text('Ouvir'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
    expect(find.text('Favoritar'), findsOneWidget);

    // Favorita (o rótulo vira "Remover dos salvos") e persiste.
    await tester.tap(find.text('Favoritar'));
    await tester.pumpAndSettle();
    expect(find.text('Remover dos salvos'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('favoritos_versiculos'),
      contains('Gênesis 1:1'),
    );

    // Copia para o clipboard.
    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();
    expect(textoCopiado, contains('Gênesis 1:1'));
    expect(textoCopiado, contains('No princípio'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
