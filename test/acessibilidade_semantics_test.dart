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

/// Auditoria de acessibilidade: o componente de doação (o mais sensível) expõe
/// rótulo Semantics para leitores de tela (público idoso/de baixa visão).
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

  testWidgets('Acessibilidade: chave Pix expõe rótulo Semantics',
      (tester) async {
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    await tester.tap(find.text('Ajustes').last);
    await tester.pump();

    final semantica = tester.ensureSemantics();
    await tester.scrollUntilVisible(
      find.textContaining('confira no banco'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp('Chave Pix por e-mail')),
      findsOneWidget,
    );
    semantica.dispose();
  });
}
