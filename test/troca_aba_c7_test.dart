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

/// Caso C7 da matriz de QA: trocar de aba durante o carregamento de um livro
/// não pode gerar "setState called after dispose" nem exceção. O carregamento
/// continua em background e a volta para a aba Bíblia segue estável.
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

  testWidgets('C7: troca de aba durante carregamento de livro não quebra',
      (tester) async {
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    // Vai para a aba Bíblia.
    await tester.tap(find.text('Bíblia').last);
    await tester.pump();
    await aguardarWidget(tester, find.text('Gênesis'));

    // Expande Gênesis (dispara o carregamento sob demanda) e troca para Salvos
    // imediatamente — antes de o asset decodificar.
    await tester.tap(find.text('Gênesis'));
    await tester.pump();
    await tester.tap(find.text('Salvos').last);
    await tester.pump();

    // Aguarda o carregamento em background concluir (runAsync) e confirma que
    // não houve "setState after dispose" nem exceção de framework.
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(tester.takeException(), isNull);

    // Volta para a Bíblia: o livro segue carregável sem erro.
    await tester.tap(find.text('Bíblia').last);
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
