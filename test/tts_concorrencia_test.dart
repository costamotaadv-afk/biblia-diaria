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

/// Casos C1 (duplo-toque em "Ouvir versículo") e C13 (duplo-toque em "Copiar
/// chave Pix") da matriz de QA: toques concorrentes não podem gerar exceção
/// não tratada nem estado quebrado.
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
    // Clipboard permitido (caminho de sucesso do Pix).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
  });

  testWidgets('C1 + C13: duplo-toques concorrentes não quebram o app',
      (tester) async {
    // ── Fase 1 (C1): duplo-toque em "Ouvir versículo" ─────────────────
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    final botaoOuvir = find.widgetWithText(FilledButton, 'Ouvir versículo');
    for (var i = 0; i < 50; i++) {
      await tester.pump();
      if (botaoOuvir.evaluate().isEmpty) continue;
      final botao = tester.widget<FilledButton>(botaoOuvir);
      if (botao.onPressed != null) break;
    }
    await tester.ensureVisible(botaoOuvir);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(botaoOuvir).onPressed, isNotNull);

    // Dois taps sem pump: leitura concorrente "último vence", sem exceção.
    await tester.tap(botaoOuvir);
    await tester.tap(botaoOuvir);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // animação do FAB
    expect(tester.takeException(), isNull);

    // Leitura ativa → FAB de pausa visível; nenhum estado quebrado.
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Pausa a leitura para não interferir na fase seguinte.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // ── Fase 2 (C13): duplo-toque em "Copiar chave Pix" ───────────────
    await tester.tap(find.text('Ajustes').last);
    await tester.pump();

    final botaoCopiar = find.text('Copiar chave Pix');
    await tester.scrollUntilVisible(
      botaoCopiar,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    // Dois toques rápidos: pode abrir diálogo; o app não pode crashar.
    await tester.tap(botaoCopiar);
    await tester.tap(botaoCopiar);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // animação do diálogo
    expect(tester.takeException(), isNull);

    // Pelo menos um diálogo de confirmação foi exibido.
    expect(find.text('Chave Pix copiada!'), findsWidgets);
  });
}
