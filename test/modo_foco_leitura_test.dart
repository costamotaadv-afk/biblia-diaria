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

/// Caso U3 da matriz de QA: na aba Bíblia, rolar para baixo esconde a barra
/// inferior (e o FAB) e rolar para cima a revela — modo foco de leitura.
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

  testWidgets('U3: modo foco esconde e revela a barra inferior',
      (tester) async {
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    await tester.tap(find.text('Bíblia').last);
    await tester.pump();
    await aguardarWidget(tester, find.text('Gênesis'));
    await tester.tap(find.text('Gênesis'));
    await aguardarWidget(tester, find.text('Capítulo 1'));

    expect(find.byType(NavigationBar), findsOneWidget);

    final scrollable = find.byType(CustomScrollView).first;
    await tester.fling(scrollable, const Offset(0, -800), 2000);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);

    await tester.fling(scrollable, const Offset(0, 800), 2000);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
