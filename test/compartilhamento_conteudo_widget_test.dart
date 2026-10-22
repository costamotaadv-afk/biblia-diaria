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

/// Cobertura dos casos SV1 (compartilhar versículo) e SC1 (compartilhar
/// capítulo) da matriz de QA: os botões de compartilhar na leitura usam a
/// mensagem pronta com referência + texto (e rodapé quando há link).
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

  testWidgets('SV1/SC1: compartilha versículo e capítulo com mensagem pronta',
      (tester) async {
    const link = 'https://biblia-diaria.streamlit.app';
    final mensagens = <String>[];

    await tester.pumpWidget(
      BibliaApp(
        relogio: () => DateTime(2026, 1, 1),
        linkCompartilhamento: link,
        compartilhar: (texto, origem) async {
          mensagens.add(texto);
          return true;
        },
      ),
    );
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    // Vai para a aba Bíblia e expande Gênesis.
    await tester.tap(find.text('Bíblia').last);
    await tester.pump();
    await aguardarWidget(tester, find.text('Gênesis'));
    await tester.tap(find.text('Gênesis'));
    await aguardarWidget(tester, find.text('Capítulo 1'));

    // Compartilha o capítulo inteiro (SC1).
    final botaoCapitulo = find.byTooltip('Compartilhar capítulo').first;
    await tester.ensureVisible(botaoCapitulo);
    await tester.pump();
    await tester.tap(botaoCapitulo);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Compartilha o primeiro versículo (SV1): toca no versículo para abrir a
    // folha de ações rápidas e toca em "Compartilhar".
    await tester.tap(find.textContaining('No princípio').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartilhar'));
    await tester.pumpAndSettle();

    expect(mensagens, hasLength(2));
    expect(mensagens.first, contains('*Gênesis 1*'));
    expect(mensagens.last, contains('*Gênesis 1:1*'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}