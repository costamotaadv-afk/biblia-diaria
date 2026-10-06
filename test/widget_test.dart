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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'favoritos_versiculos': <String>['João 3:16', 'Livro Fantasma 1:1'],
      'favoritos_capitulos': <String>['Salmos 23', '1 João 3'],
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => call.method == 'getVoices' ? <Object>[] : 1,
    );
  });

  testWidgets('navega pelas abas e carrega favoritos persistidos',
      (tester) async {
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    expect(find.text('Versículo do Dia'), findsOneWidget);
    expect(find.text('Mensagem para você'), findsOneWidget);

    await tester.tap(find.text('Bíblia').last);
    await tester.pump();
    expect(find.text('Gênesis'), findsOneWidget);

    await tester.tap(find.text('Salvos').last);
    await aguardarWidget(
      tester,
      find.textContaining('assim amou Deus ao mundo'),
    );
    expect(find.text('João 3:16'), findsOneWidget);
    expect(find.text('Salmos 23'), findsOneWidget);
    expect(find.textContaining('assim amou Deus ao mundo'), findsOneWidget);
    expect(find.text('Carregando versículo...'), findsNothing);

    // E14: favorito órfão (chave que não casa com nenhum livro) → fallback
    // "Conteúdo não encontrado." em vez de carregar indefinidamente.
    expect(find.text('Livro Fantasma 1:1'), findsOneWidget);
    expect(find.text('Conteúdo não encontrado.'), findsOneWidget);

    // B11: favorito de capítulo com prefixo numérico ("1 João 3") aparece.
    expect(find.text('1 João 3'), findsOneWidget);

    await tester.tap(find.text('Ajustes').last);
    await tester.pump();
    expect(find.text('Tema escuro'), findsOneWidget);
    expect(find.text('Fonte maior (recomendado)'), findsOneWidget);

    // T025/FR-011: persistência de tema_escuro com reinício simulado.
    await tester.tap(find.byType(Switch).first); // alterna "Tema escuro"
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));
    await tester.tap(find.text('Ajustes').last);
    await tester.pump();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Tema escuro'),
          )
          .value,
      isTrue,
    );

    // B10: aviso anti-fraude do Pix presente na aba Ajustes (regressão de texto)
    // e rótulo Semantics da chave Pix acessível.
    await tester.scrollUntilVisible(
      find.textContaining('confira no banco'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(
      find.textContaining('confira no banco o nome de quem receberá'),
      findsOneWidget,
    );
    final semantica = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('Chave Pix por e-mail')),
      findsOneWidget,
    );
    semantica.dispose();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
