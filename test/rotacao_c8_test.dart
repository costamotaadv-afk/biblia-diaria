import 'package:biblia_diaria/main.dart';
import 'package:flutter/foundation.dart';
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

/// Caso C8 da matriz de QA: mudar o tamanho/orientação com o banner em ação
/// não pode lançar exceção; o `didChangeDependencies` descarta o banner antigo
/// e recarrega um novo (sem vazamento), mantendo o app navegável.
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

  testWidgets('C8: rotação com banner em ação não quebra', (tester) async {
    // Simula Android (suportaAdMob) para o banner entrar em ação.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      const ads = MethodChannel('plugins.flutter.io/google_mobile_ads');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ads, (call) async {
        switch (call.method) {
          case '_init':
            return null;
          case 'AdSize#getAnchoredAdaptiveBannerAdSize':
            return 50; // altura em px retornada pelo plugin
          case 'loadBannerAd':
            return null;
          default:
            return null;
        }
      });

      await tester.pumpWidget(const BibliaApp());
      await aguardarWidget(tester, find.text('Bíblia Diária'));

      // Rotação: muda a largura → didChangeDependencies recarrega o banner.
      await tester.binding.setSurfaceSize(const Size(600, 800));
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Bíblia Diária'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

