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

/// True se o `speak` recebeu texto vazio (String ou Map, dependendo da versão
/// do plugin `flutter_tts`).
bool _speakVazio(MethodCall call) {
  final args = call.arguments;
  if (args is String) return args.isEmpty;
  if (args is Map) return (args['text'] ?? '').toString().isEmpty;
  return false;
}

/// Caso C12 da matriz de QA: ao retomar, `_tts.speak('')` pode lançar em
/// engines sem suporte a string vazia. A falha deve encerrar o trecho
/// graciosamente (voltar ao estado ocioso) sem desabilitar o TTS para a sessão
/// inteira.
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
      (call) async {
        if (call.method == 'getVoices') return <Object>[];
        if (call.method == 'speak' && _speakVazio(call)) {
          throw PlatformException(code: 'speak_empty', message: 'empty');
        }
        return 1;
      },
    );
  });

  testWidgets('C12: falha na retomada encerra o trecho sem desabilitar o TTS',
      (tester) async {
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    // Inicia a leitura do versículo do dia (speak com texto válido → sucesso).
    final botaoOuvir = find.widgetWithText(FilledButton, 'Ouvir versículo');
    for (var i = 0; i < 50; i++) {
      await tester.pump();
      if (botaoOuvir.evaluate().isEmpty) continue;
      if (tester.widget<FilledButton>(botaoOuvir).onPressed != null) break;
    }
    await tester.ensureVisible(botaoOuvir);
    await tester.pumpAndSettle();
    await tester.tap(botaoOuvir);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Pausa a leitura (aciona `_alternarPlayPause` diretamente — o tap no FAB
    // pode não atingir o alvo no ambiente de teste).
    tester
        .widget<FloatingActionButton>(find.byType(FloatingActionButton))
        .onPressed!();
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Retoma: `speak('')` lança → encerra graciosamente (sem exceção).
    tester
        .widget<FloatingActionButton>(find.byType(FloatingActionButton))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    // Leitura encerrada: FAB desaparece.
    expect(find.byType(FloatingActionButton), findsNothing);

    // TTS segue disponível (não foi desabilitado para a sessão inteira).
    await tester.tap(find.text('Ajustes').last);
    await tester.pump();
    expect(find.textContaining('indisponível'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
