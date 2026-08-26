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

/// Garante que a leitura em voz alta seja configurada com fala humana:
/// velocidade 0.85 (levemente pausada, ideal para idosos) e a melhor voz
/// pt-BR disponível no motor nativo do aparelho (Google TTS/AVSpeechSynthesizer).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'TTS: velocidade 0.85 e melhor voz pt-BR neural selecionada por padrão',
      (tester) async {
    final chamadas = <String>[];
    final argumentos = <String, Object?>{};

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async {
        chamadas.add(call.method);
        argumentos[call.method] = call.arguments;
        if (call.method == 'getVoices') {
          // Vozes como o Google TTS expõe no Android (neural, padrão e en-US).
          return <Object>[
            <String, Object>{
              'name': 'pt-br-x-ftd-neural-local',
              'locale': 'pt-BR',
              'gender': 'female',
            },
            <String, Object>{
              'name': 'pt-br-standard-local',
              'locale': 'pt-BR',
              'gender': 'female',
            },
            <String, Object>{
              'name': 'en-us-voice',
              'locale': 'en-US',
              'gender': 'female',
            },
          ];
        }
        return 1;
      },
    );

    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));

    // Aguarda a configuração TTS concluir (a última chamada é awaitSpeakCompletion).
    for (var i = 0; i < 50; i++) {
      await tester.pump();
      if (chamadas.contains('awaitSpeakCompletion')) break;
    }

    // Sequência completa de configuração foi executada.
    expect(
      chamadas,
      containsAll([
        'setLanguage',
        'setSpeechRate',
        'setPitch',
        'setVolume',
        'setVoice',
        'awaitSpeakCompletion',
      ]),
    );

    // Idioma português.
    expect(argumentos['setLanguage'], 'pt-BR');

    // Velocidade 0.85: fala natural, levemente pausada (menos robótica).
    expect(argumentos['setSpeechRate'], 0.85);

    // A voz padrão deve ser a de melhor qualidade disponível (neural pt-BR).
    expect(argumentos['setVoice'], {
      'name': 'pt-br-x-ftd-neural-local',
      'locale': 'pt-BR',
    });

    // ── Fase 2 (B7): voz salva que não existe mais → fallback + reescrita ──
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    SharedPreferences.setMockInitialValues({
      'voz_tts_id': 'pt-br-antiga|pt-BR', // voz removida do sistema
    });
    chamadas.clear();
    argumentos.clear();

    await tester.pumpWidget(const BibliaApp());
    await aguardarWidget(tester, find.text('Bíblia Diária'));
    for (var i = 0; i < 50; i++) {
      await tester.pump();
      if (chamadas.contains('awaitSpeakCompletion')) break;
    }

    // A voz salva não está em getVoices → usa a melhor voz pt-BR disponível.
    expect(argumentos['setVoice'], {
      'name': 'pt-br-x-ftd-neural-local',
      'locale': 'pt-BR',
    });

    // E reescreve a preferência (evita DropdownButton sem valor correspondente).
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('voz_tts_id'), 'pt-br-x-ftd-neural-local|pt-BR');
  });
}
