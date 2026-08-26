import 'package:biblia_diaria/main.dart';
import 'package:biblia_diaria/platform_support.dart';
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

/// Cobertura dos casos C10 (AdMob sem GMS) e C11 (TTS ausente na web)
/// da matriz de QA (tool/QA_EDGE_CASES.md).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('C10 — inicialização do AdMob com degradação graciosa', () {
    // O plugin dispara `MobileAds#_init` fire-and-forget na criação do
    // singleton, então o canal precisa estar mockado ANTES da primeira
    // referência a MobileAds (no ambiente de teste não há implementação nativa).
    const channel = MethodChannel('plugins.flutter.io/google_mobile_ads');

    void mockarCanal(Future<Object?> Function(MethodCall) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);
    }

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('inicializarAdMob engole falha de inicialização (sem GMS)', () async {
      mockarCanal((call) async {
        if (call.method == '_init') return null;
        throw PlatformException(
          code: 'no_admob',
          message: 'Google Play Services ausente',
        );
      });

      // Deve completar normalmente, sem propagar a exceção.
      await expectLater(inicializarAdMob(), completes);
    });

    test('inicializarAdMob completa no caminho feliz', () async {
      mockarCanal((call) async {
        if (call.method == '_init') return null;
        if (call.method == 'MobileAds#initialize') return <String, dynamic>{};
        return null;
      });

      await expectLater(inicializarAdMob(), completes);
    });
  });

  group('C11 — TTS indisponível degrada sem travar o app', () {
    testWidgets('app abre, botão "Ouvir versículo" fica desabilitado '
        'e Ajustes avisa a indisponibilidade', (tester) async {
      // Simula plataforma SEM plugin TTS: toda chamada lança erro.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        (call) async => throw PlatformException(
          code: 'missing_plugin',
          message: 'flutter_tts não implementado nesta plataforma',
        ),
      );

      await tester.pumpWidget(const BibliaApp());
      await aguardarWidget(tester, find.text('Bíblia Diária'));

      // Aguarda o estado degradado estabilizar (configuração TTS falha).
      var desabilitado = false;
      for (var i = 0; i < 50; i++) {
        await tester.pump();
        final botoes = find.widgetWithText(FilledButton, 'Ouvir versículo');
        if (botoes.evaluate().isNotEmpty) {
          final botao = tester.widget<FilledButton>(botoes);
          if (botao.onPressed == null) {
            desabilitado = true;
            break;
          }
        }
      }
      expect(desabilitado, isTrue,
          reason: 'Com TTS indisponível, "Ouvir versículo" deve ficar '
              'desabilitado (B1/C11).');

      // A aba Ajustes deve sinalizar a indisponibilidade.
      await tester.tap(find.text('Ajustes').last);
      await tester.pump();
      expect(find.textContaining('indisponível'), findsWidgets);
    });
  });
}
