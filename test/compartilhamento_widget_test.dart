import 'package:biblia_diaria/config.dart';
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

/// Cobertura dos casos SH1/SH2 da matriz de QA: o botão "Compartilhar o app"
/// usa a mensagem pronta com o link e, quando o compartilhamento nativo não
/// está disponível, copia a mensagem e orienta colar no WhatsApp (nunca trava).
///
/// As duas fases ficam em UM ÚNICO testWidgets pelo mesmo motivo descrito em
/// clipboard_b2_test.dart (o runAsync usado para carregar assets deixa estado
/// residual que quebra um segundo testWidgets no mesmo arquivo).
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

  testWidgets('SH1/SH2: compartilha a mensagem pronta e degrada para clipboard',
      (tester) async {
    const link = 'https://biblia-diaria.streamlit.app';
    final mensagensCompartilhadas = <String>[];

    // ── Fase 1: compartilhamento nativo disponível (SH1) ────────────────────
    await tester.pumpWidget(
      BibliaApp(
        relogio: () => DateTime(2026, 1, 1),
        linkCompartilhamento: link,
        compartilhar: (texto, origem) async {
          mensagensCompartilhadas.add(texto);
          return true;
        },
      ),
    );
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    await tester.ensureVisible(find.text('Compartilhar o app'));
    await tester.pump();
    await tester.tap(find.text('Compartilhar o app'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(mensagensCompartilhadas, hasLength(1));
    expect(mensagensCompartilhadas.single, mensagemCompartilhamento(link: link));

    // ── Fase 2: share indisponível → clipboard + orientação (SH2) ───────────
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );

    await tester.pumpWidget(
      BibliaApp(
        relogio: () => DateTime(2026, 1, 1),
        linkCompartilhamento: link,
        compartilhar: (texto, origem) async => false,
      ),
    );
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    await tester.ensureVisible(find.text('Compartilhar o app'));
    await tester.pump();
    await tester.tap(find.text('Compartilhar o app'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('Mensagem copiada! Cole no WhatsApp para enviar.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
