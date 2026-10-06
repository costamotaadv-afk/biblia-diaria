import 'dart:async';

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

/// Caso C9 (variante timeout) da matriz de QA: `banner.load()` que nunca
/// completa não pode travar o app nem gerar exceção assíncrona — o carregamento
/// é fire-and-forget e o app segue navegável.
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

  testWidgets('C9: load do banner que nunca completa não trava o app',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final nuncaCompleta = Completer<Object?>();
    try {
      const ads = MethodChannel('plugins.flutter.io/google_mobile_ads');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ads, (call) {
        switch (call.method) {
          case '_init':
            return Future<Object?>.value();
          case 'AdSize#getAnchoredAdaptiveBannerAdSize':
            return Future<Object?>.value(50);
          case 'loadBannerAd':
            return nuncaCompleta.future; // pendente para sempre
          default:
            return Future<Object?>.value();
        }
      });

      await tester.pumpWidget(const BibliaApp());
      await aguardarWidget(tester, find.text('Bíblia Diária'));

      // O app segue navegável mesmo com o load do banner pendente.
      await tester.tap(find.text('Bíblia').last);
      await tester.pump();
      await tester.tap(find.text('Início').last);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Bíblia Diária'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    } finally {
      debugDefaultTargetPlatformOverride = null;
      if (!nuncaCompleta.isCompleted) nuncaCompleta.complete();
    }
  });
}
