import 'package:biblia_diaria/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> aguardarWidget(WidgetTester tester, Finder finder) async {
  // runAsync permite que o rootBundle (assets) e os mocks de canal concluam
  // de verdade. Mantido dentro de UM ÚNICO testWidgets por arquivo para não
  // deixar trabalho real pendente entre testes (poluição conhecida do runAsync
  // em flutter test quando há dois testWidgets no mesmo arquivo).
  for (var tentativa = 0; tentativa < 100; tentativa++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget esperado não apareceu: $finder');
}

/// Cobertura do caso B2 da matriz de QA: permissão de clipboard negada ao
/// copiar a chave Pix deve gerar erro amigável — e NÃO o diálogo de sucesso.
///
/// Os dois cenários (negado/permitido) ficam em UM ÚNICO testWidgets: o mock
/// do canal é trocado no meio do teste, evitando a poluição entre testWidgets
/// do mesmo arquivo (o runAsync usado para carregar assets deixa estado
/// residual que quebrava o segundo teste do arquivo).
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

  /// Vai até o botão "Copiar chave Pix" (o card de doação fica abaixo da
  /// dobra na viewport de teste).
  Future<void> irAteBotaoCopiar(WidgetTester tester) async {
    await tester.tap(find.text('Ajustes').last);
    await tester.pump();

    final botaoCopiar = find.text('Copiar chave Pix');
    await tester.scrollUntilVisible(
      botaoCopiar,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  testWidgets(
      'B2: clipboard negado mostra erro amigável; permitido mostra sucesso',
      (tester) async {
    // ── Fase 1: clipboard NEGADO ────────────────────────────────────────────
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(
            code: 'AccessDeniedException',
            message: 'Permissão clipboard-write negada',
          );
        }
        return null;
      },
    );

    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));
    await irAteBotaoCopiar(tester);

    await tester.tap(find.text('Copiar chave Pix'));
    // Processa a falha assíncrona + animação do SnackBar.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // NÃO deve abrir o diálogo de sucesso.
    expect(find.text('Chave Pix copiada!'), findsNothing);
    // Deve mostrar erro amigável com orientação de cópia manual.
    expect(find.textContaining('Não foi possível copiar'), findsOneWidget);
    expect(find.textContaining('Copie manualmente'), findsOneWidget);

    // Descarta o app antes de trocar o cenário.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    // ── Fase 2: clipboard PERMITIDO ────────────────────────────────────────
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );

    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));
    await irAteBotaoCopiar(tester);

    await tester.tap(find.text('Copiar chave Pix'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Sucesso: abre o diálogo "Chave Pix copiada!" com o passo a passo.
    expect(find.text('Chave Pix copiada!'), findsOneWidget);
    expect(
      find.textContaining('Abra o aplicativo do seu banco'),
      findsOneWidget,
    );
  });
}
