import 'package:biblia_diaria/main.dart';
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

/// Cobertura do caso C9 da matriz de QA: `banner.load()` falhando
/// (rede indisponível, dispositivo sem Google Play Services) não pode virar
/// exceção assíncrona não tratada — o app deve seguir funcional sem banner.
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

  testWidgets('C9: falha no load do banner não derruba o app', (tester) async {
    // Simula SDK do AdMob registrado (tamanho adaptativo responde), mas o
    // load do banner falha com PlatformException.
    const ads = MethodChannel('plugins.flutter.io/google_mobile_ads');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ads, (call) async {
      switch (call.method) {
        case '_init':
          return null;
        case 'AdSize#getAnchoredAdaptiveBannerAdSize':
          return 50; // altura em px retornada pelo plugin
        case 'loadBannerAd':
          throw PlatformException(
            code: 'no_ad_available',
            message: 'Falha simulada ao carregar banner',
          );
        default:
          return null;
      }
    });

    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    // Sem exceção não tratada até aqui; o app continua navegável.
    await tester.tap(find.text('Bíblia').last);
    await tester.pump();
    await tester.tap(find.text('Início').last);
    await tester.pump();

    expect(find.text('Bíblia Diária'), findsOneWidget);
  });
}
