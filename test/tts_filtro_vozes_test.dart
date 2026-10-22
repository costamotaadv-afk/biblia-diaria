import 'package:biblia_diaria/leitura_natural.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cobertura unitária da seleção de voz (matriz B6/B7 + melhoria "adeus ao som
/// metálico"): motores legados (pico/compact/espeak) são descartados e vozes
/// neurais/wavenet/enhanced ficam no topo.
void main() {
  group('VozDeLeitura.ehRobotica', () {
    test('detecta motores legados pelo nome', () {
      expect(
        const VozDeLeitura(
          name: 'pico',
          locale: 'pt-BR',
          gender: 'female',
        ).ehRobotica,
        isTrue,
      );
      expect(
        const VozDeLeitura(
          name: 'com.apple.voice.compact.pt-BR.Luciana',
          locale: 'pt-BR',
          gender: 'female',
        ).ehRobotica,
        isTrue,
      );
      expect(
        const VozDeLeitura(
          name: 'espeak-pt',
          locale: 'pt-PT',
          gender: 'male',
        ).ehRobotica,
        isTrue,
      );
    });

    test('não marca vozes neurais/standard como robóticas', () {
      expect(
        const VozDeLeitura(
          name: 'pt-br-x-ftd-neural-local',
          locale: 'pt-BR',
          gender: 'female',
        ).ehRobotica,
        isFalse,
      );
      expect(
        const VozDeLeitura(
          name: 'pt-br-standard-local',
          locale: 'pt-BR',
          gender: 'female',
        ).ehRobotica,
        isFalse,
      );
    });
  });

  group('pontuarVozParaLeitura', () {
    test('neural/wavenet vencem a voz standard', () {
      final neural = pontuarVozParaLeitura(
        name: 'pt-br-x-ftd-neural-local',
        locale: 'pt-BR',
        gender: 'female',
      );
      final standard = pontuarVozParaLeitura(
        name: 'pt-br-standard-local',
        locale: 'pt-BR',
        gender: 'female',
      );
      expect(neural, greaterThan(standard));
    });

    test('pt-BR feminina supera pt-PT masculina', () {
      final brFem = pontuarVozParaLeitura(
        name: 'voz',
        locale: 'pt-BR',
        gender: 'female',
      );
      final ptMasc = pontuarVozParaLeitura(
        name: 'voz',
        locale: 'pt-PT',
        gender: 'male',
      );
      expect(brFem, greaterThan(ptMasc));
    });
  });

  group('filtrarVozesParaLeitura', () {
    test('descarta pico/compact/espeak quando há alternativa', () {
      final bruto = <Object>[
        <String, Object>{'name': 'pico', 'locale': 'pt-BR', 'gender': 'female'},
        <String, Object>{
          'name': 'com.apple.voice.compact.pt-BR.Luciana',
          'locale': 'pt-BR',
          'gender': 'female',
        },
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
      final vozes = filtrarVozesParaLeitura(bruto);
      final nomes = vozes.map((voz) => voz.name).toList();
      expect(nomes, isNot(contains('pico')));
      expect(nomes, isNot(contains('com.apple.voice.compact.pt-BR.Luciana')));
      expect(nomes, isNot(contains('en-us-voice')));
      expect(vozes.first.name, 'pt-br-x-ftd-neural-local');
    });

    test('mantém motores legados como último recurso (sem alternativa)', () {
      final bruto = <Object>[
        <String, Object>{'name': 'pico', 'locale': 'pt-BR', 'gender': 'female'},
      ];
      final vozes = filtrarVozesParaLeitura(bruto);
      expect(vozes, isNotEmpty);
      expect(vozes.single.name, 'pico');
    });

    test('lista vazia ou só de outros idiomas retorna vazio', () {
      expect(filtrarVozesParaLeitura(const <Object>[]), isEmpty);
      expect(
        filtrarVozesParaLeitura(<Object>[
          <String, Object>{
            'name': 'en-us-voice',
            'locale': 'en-US',
            'gender': 'female',
          },
        ]),
        isEmpty,
      );
    });
  });

  group('selecionarVozParaLeitura', () {
    final vozes = <VozDeLeitura>[
      const VozDeLeitura(name: 'neural', locale: 'pt-BR', gender: 'female'),
      const VozDeLeitura(name: 'standard-male', locale: 'pt-BR', gender: 'male'),
      const VozDeLeitura(name: 'neural-male', locale: 'pt-BR', gender: 'male'),
    ];

    test('respeita voz salva quando ainda existe', () {
      final escolhida = selecionarVozParaLeitura(vozes, 'standard-male|pt-BR');
      expect(escolhida?.name, 'standard-male');
    });

    test('sem voz salva prefere pt-BR feminina', () {
      expect(selecionarVozParaLeitura(vozes, null)?.name, 'neural');
    });

    test('voz salva removida → cai para melhor pt-BR feminina', () {
      final escolhida = selecionarVozParaLeitura(vozes, 'voz-removida|pt-BR');
      expect(escolhida?.name, 'neural');
    });

    test('lista vazia → null', () {
      expect(selecionarVozParaLeitura(const <VozDeLeitura>[], null), isNull);
    });
  });
}
