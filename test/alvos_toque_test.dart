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

/// Caso U5 da matriz de QA: alvos de toque generosos (≥ 48 dp) na navegação
/// inferior e nas ações do cartão do Versículo do Dia.
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

  testWidgets('U5: navegação e ações do cartão têm alvo ≥ 48 dp',
      (tester) async {
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    final navSize = tester.getSize(find.byType(NavigationBar));
    expect(navSize.height, greaterThanOrEqualTo(48),
        reason: 'Barra de navegação deve ter alvo confortável.');

    for (final label in ['Ouvir', 'Favoritar', 'Compartilhar']) {
      final size = tester.getSize(find.widgetWithText(TextButton, label));
      expect(size.height, greaterThanOrEqualTo(48),
          reason: 'Ação "$label" deve ter alvo ≥ 48 dp.');
    }
  });
}
