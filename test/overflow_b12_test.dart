import 'package:biblia_diaria/main.dart';
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

/// Caso B12 da matriz de QA: com fonte grande (textScaler 1.18, padrão do app
/// para idosos) em uma tela estreita (320 px), nenhuma tela pode ter overflow
/// de layout — um RenderFlex overflow falharia este teste automaticamente.
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

  testWidgets('B12: fonte grande (1.18) em tela de 320 px não gera overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    // Tela Início (a mais densa): sem overflow.
    expect(tester.takeException(), isNull);

    // Percorre as demais abas exercitando os layouts.
    await tester.tap(find.text('Bíblia').last);
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Salvos').last);
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Ajustes').last);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
