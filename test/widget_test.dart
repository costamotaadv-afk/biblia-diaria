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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'favoritos_versiculos': <String>['João 3:16'],
      'favoritos_capitulos': <String>['Salmos 23'],
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => call.method == 'getVoices' ? <Object>[] : 1,
    );
  });

  testWidgets('navega pelas abas e carrega favoritos persistidos',
      (tester) async {
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    expect(find.text('Versículo do Dia'), findsOneWidget);
    expect(find.text('Mensagem para você'), findsOneWidget);

    await tester.tap(find.text('Bíblia').last);
    await tester.pump();
    expect(find.text('Gênesis'), findsOneWidget);

    await tester.tap(find.text('Salvos').last);
    await aguardarWidget(
      tester,
      find.textContaining('assim amou Deus ao mundo'),
    );
    expect(find.text('João 3:16'), findsOneWidget);
    expect(find.text('Salmos 23'), findsOneWidget);
    expect(find.textContaining('assim amou Deus ao mundo'), findsOneWidget);
    expect(find.text('Carregando versículo...'), findsNothing);

    await tester.tap(find.text('Ajustes').last);
    await tester.pump();
    expect(find.text('Tema escuro'), findsOneWidget);
    expect(find.text('Fonte maior (recomendado)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
