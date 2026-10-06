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

/// Cobertura do caso B4 da matriz de QA: a virada do dia com o app aberto
/// deve atualizar o "Versículo do Dia" (o relógio é injetável via
/// [BibliaApp.relogio] para teste determinístico).
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

  testWidgets('B4: virada de dia com app aberto atualiza o versículo do dia',
      (tester) async {
    var dataAtual = DateTime(2024, 1, 1);
    await tester.pumpWidget(BibliaApp(relogio: () => dataAtual));
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    // dia 0 (01/01/2024) → Gênesis 1:1.
    await aguardarWidget(tester, find.text('Gênesis 1:1'));

    // "Virada do dia" com o app aberto, sem reiniciar.
    dataAtual = DateTime(2024, 1, 2);
    await tester.tap(find.text('Bíblia').last);
    await tester.pump();
    await tester.tap(find.text('Início').last);
    await tester.pump();

    // O conteúdo passa a seguir o novo dia (dia 1 → Êxodo 1:1), em vez de
    // continuar exibindo o versículo de ontem.
    await aguardarWidget(tester, find.text('Êxodo 1:1'));
    expect(find.text('Gênesis 1:1'), findsNothing);

    // T011/B4 (2ª virada, sem sair do Início): o usuário permanece na Home;
    // a próxima INTERAÇÃO (salvar versículo) dispara o rebuild, que recalcula
    // o conteúdo do dia 2 (Levítico 1:1) e carrega o livro novo sob demanda.
    // O setState posterior ao `_cacheLivros.assegurar` é guardado por `mounted`
    // — nenhum "setState called after dispose" pode ser lançado.
    dataAtual = DateTime(2024, 1, 3); // dia 2 → Levítico 1:1
    // Rola a Home para o botão sair de trás da NavigationBar e ficar tocável.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -220),
    );
    await tester.pump();
    await tester.tap(find.text('Salvar versículo').last);
    await tester.pump();
    await aguardarWidget(tester, find.text('Levítico 1:1'));
    expect(find.text('Êxodo 1:1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
