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

/// Cobertura do caso C4 da matriz de QA: duplo-toque em "Salvar versículo"
/// não pode deixar memória e disco divergentes, nem perder dados do usuário.
///
/// Usa o botão "Salvar versículo" da tela inicial (versículo do dia), que é
/// leve — evita montar os ~1500 versículos de Gênesis, como fazia a versão
/// anterior do teste (que chegou a estourar o timeout da suíte).
///
/// Os dois cenários (duplo-toque e toque único) ficam em UM ÚNICO testWidgets:
/// o `runAsync` usado para carregar assets deixa estado residual que faz o
/// 2º testWidgets do mesmo arquivo falhar ao abrir o app (poluição conhecida
/// do flutter test — ver test/clipboard_b2_test.dart, mesma estratégia).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    // Sem favoritos iniciais; armazenamento novo por teste.
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => call.method == 'getVoices' ? <Object>[] : 1,
    );
  });

  /// Garante que a aba Início está ativa e o botão "Salvar versículo" está
  /// habilitado e visível/acessível ao toque.
  Future<void> irParaInicioComBotaoSalvar(WidgetTester tester) async {
    await tester.tap(find.text('Início').last);
    await tester.pump();

    final botaoSalvar = find.widgetWithText(OutlinedButton, 'Salvar versículo');
    for (var i = 0; i < 50; i++) {
      await tester.pump();
      if (botaoSalvar.evaluate().isEmpty) continue;
      final botao = tester.widget<OutlinedButton>(botaoSalvar);
      if (botao.onPressed != null) break;
    }

    // Rola a Home até o botão ficar totalmente visível/acessível ao toque.
    await tester.ensureVisible(botaoSalvar);
    await tester.pumpAndSettle();

    final botao = tester.widget<OutlinedButton>(botaoSalvar);
    if (botao.onPressed == null) {
      fail('Botão "Salvar versículo" não ficou habilitado a tempo.');
    }
  }

  /// Abre o app e aguarda o botão "Salvar versículo" da Home ficar habilitado
  /// (o que significa que o versículo do dia já foi carregado) e visível,
  /// fora da área coberta pela NavigationBar (senão o tap erra o alvo).
  Future<void> abrirAteHomePronta(WidgetTester tester) async {
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));
    await irParaInicioComBotaoSalvar(tester);
  }

  /// Reinício simulado com o MESMO armazenamento de SharedPreferences.
  Future<void> reiniciarApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));
  }

  testWidgets(
      'C4: favoritos consistentes entre memória e disco após reinício '
      '(duplo-toque e toque único)', (tester) async {
    // ── Fase 1: duplo-toque (add + remove) → nada fica salvo ───────────────
    await abrirAteHomePronta(tester);
    final botaoSalvar = find.widgetWithText(OutlinedButton, 'Salvar versículo');

    // Dois toques sem pump entre eles simulam chamadas concorrentes
    // disparadas antes de qualquer escrita concluir.
    await tester.tap(botaoSalvar);
    await tester.tap(botaoSalvar);
    await tester.pumpAndSettle();

    // Estado em memória: voltou ao estado inicial (nada salvo).
    expect(find.text('Salvar versículo'), findsOneWidget);
    expect(find.text('Salvo'), findsNothing);

    // Estado em disco: nada persistido.
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favoritos_versiculos') ?? [], isEmpty);
    expect(prefs.getStringList('favoritos_capitulos') ?? [], isEmpty);

    // Reinício simulado: continua vazio.
    await reiniciarApp(tester);
    await tester.tap(find.text('Salvos').last);
    await aguardarWidget(
      tester,
      find.text('Nenhum versículo ou capítulo salvo ainda.'),
    );

    // ── Fase 2: toque único → favorito persiste após reinício ─────────────
    await irParaInicioComBotaoSalvar(tester);
    await tester.tap(botaoSalvar);
    await tester.pumpAndSettle();

    // Em memória, o versículo do dia ficou salvo (botão mudou para "Salvo").
    expect(find.text('Salvo'), findsOneWidget);

    // Em disco, exatamente uma chave foi persistida.
    prefs = await SharedPreferences.getInstance();
    final salvos = prefs.getStringList('favoritos_versiculos') ?? [];
    expect(salvos, hasLength(1));

    // Reinício simulado: o favorito deve sobreviver e exibir o conteúdo.
    await reiniciarApp(tester);
    await tester.tap(find.text('Salvos').last);
    await aguardarWidget(tester, find.text(salvos.first));

    // O FutureBuilder resolve no microtask seguinte ao pump: aguarda o
    // "Carregando versículo..." sumir antes de afirmar o conteúdo.
    for (var i = 0; i < 50; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (find.text('Carregando versículo...').evaluate().isEmpty) break;
    }
    expect(find.text('Carregando versículo...'), findsNothing);
    expect(find.text('Conteúdo não encontrado.'), findsNothing);
  });
}
