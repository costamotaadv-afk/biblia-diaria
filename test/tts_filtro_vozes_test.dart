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

    test('detecta eloquence pelo identificador', () {
      expect(
        const VozDeLeitura(
          name: 'Fiona',
          locale: 'pt-BR',
          gender: 'female',
          identifier: 'com.apple.eloquence.pt-BR.Fiona',
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

    test('pt-PT não pontua — o app roda somente em pt-BR', () {
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
      expect(ptMasc, 0);
    });

    test('qualidade estruturada do Android vence a heurística de nome', () {
      final alta = pontuarVozParaLeitura(
        name: 'pt-br-x-ptd-local',
        locale: 'pt-BR',
        gender: 'female',
        quality: 500,
      );
      final baixa = pontuarVozParaLeitura(
        name: 'pt-br-x-ptd-local',
        locale: 'pt-BR',
        gender: 'female',
        quality: 300,
      );
      expect(alta, greaterThan(baixa));
    });

    test('voz de rede (network_required) pontua acima da local', () {
      final rede = pontuarVozParaLeitura(
        name: 'pt-br-x-ptd-network',
        locale: 'pt-BR',
        gender: 'female',
        quality: 400,
        networkRequired: true,
      );
      final local = pontuarVozParaLeitura(
        name: 'pt-br-x-ptd-local',
        locale: 'pt-BR',
        gender: 'female',
        quality: 400,
      );
      expect(rede, greaterThan(local));
    });

    test('qualidade iOS: premium (3) supera enhanced (2) e default (1)', () {
      final premium = pontuarVozParaLeitura(
        name: 'com.apple.voice.premium.pt-BR.Luciana',
        locale: 'pt-BR',
        gender: 'female',
        quality: 3,
      );
      final enhanced = pontuarVozParaLeitura(
        name: 'com.apple.voice.enhanced.pt-BR.Luciana',
        locale: 'pt-BR',
        gender: 'female',
        quality: 2,
      );
      final compacta = pontuarVozParaLeitura(
        name: 'com.apple.voice.compact.pt-BR.Luciana',
        locale: 'pt-BR',
        gender: 'female',
        quality: 1,
      );
      expect(premium, greaterThan(enhanced));
      expect(enhanced, greaterThan(compacta));
    });

    test('voz não instalada é penalizada', () {
      final instalada = pontuarVozParaLeitura(
        name: 'pt-br-x-ptd-local',
        locale: 'pt-BR',
        gender: 'female',
        quality: 400,
      );
      final naoInstalada = pontuarVozParaLeitura(
        name: 'pt-br-x-ptd-local',
        locale: 'pt-BR',
        gender: 'female',
        quality: 400,
        features: {'notInstalled'},
      );
      expect(instalada, greaterThan(naoInstalada));
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

    test('ignora vozes pt-PT — somente pt-BR é aceito', () {
      final bruto = <Object>[
        <String, Object>{
          'name': 'pt-pt-voz-neural',
          'locale': 'pt-PT',
          'gender': 'female',
        },
        <String, Object>{
          'name': 'pt-br-x-ftd-neural-local',
          'locale': 'pt-BR',
          'gender': 'female',
        },
      ];
      final vozes = filtrarVozesParaLeitura(bruto);
      expect(
        vozes.map((voz) => voz.name).toList(),
        ['pt-br-x-ftd-neural-local'],
      );
    });

    test('prefere voz de rede/qualidade alta à local quando ambas existem', () {
      final bruto = <Object>[
        <String, Object>{
          'name': 'pt-br-x-ptd-local',
          'locale': 'pt-BR',
          'gender': 'female',
          'quality': 400,
        },
        <String, Object>{
          'name': 'pt-br-x-ptd-network',
          'locale': 'pt-BR',
          'gender': 'female',
          'quality': 400,
          'network_required': true,
        },
      ];
      final vozes = filtrarVozesParaLeitura(bruto);
      expect(vozes.first.name, 'pt-br-x-ptd-network');
    });

    test('descarta voz eloquence (robótica) quando há alternativa', () {
      final bruto = <Object>[
        <String, Object>{
          'name': 'com.apple.eloquence.pt-BR.Fiona',
          'locale': 'pt-BR',
          'gender': 'female',
          'quality': 1,
        },
        <String, Object>{
          'name': 'com.apple.voice.enhanced.pt-BR.Luciana',
          'locale': 'pt-BR',
          'gender': 'female',
          'quality': 2,
        },
      ];
      final vozes = filtrarVozesParaLeitura(bruto);
      final nomes = vozes.map((voz) => voz.name).toList();
      expect(nomes, isNot(contains('com.apple.eloquence.pt-BR.Fiona')));
      expect(nomes, contains('com.apple.voice.enhanced.pt-BR.Luciana'));
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
