import 'package:biblia_diaria/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SH1/SH3: link começa vazio e a validação só aceita URL http(s)', () {
    expect(linkDownloadApp, isEmpty);
    expect(linkCompartilhamentoValido(''), isFalse);
    expect(linkCompartilhamentoValido('   '), isFalse);
    expect(linkCompartilhamentoValido('ftp://exemplo.com'), isFalse);
    expect(
      linkCompartilhamentoValido('https://biblia-diaria.streamlit.app'),
      isTrue,
    );
  });

  test('mensagem de compartilhamento contém o nome do app e o link', () {
    const link = 'https://biblia-diaria.streamlit.app';
    final mensagem = mensagemCompartilhamento(link: link);

    expect(mensagem, contains('Bíblia Diária'));
    expect(mensagem, contains(link));
    expect(mensagem.trim(), isNotEmpty);
  });

  test('rodapé de divulgação só aparece com link válido (SH3)', () {
    expect(rodapeCompartilhamento(''), isEmpty);
    expect(
      rodapeCompartilhamento('https://biblia-diaria.streamlit.app'),
      contains('Baixe grátis'),
    );
  });

  test('SV1: mensagem de versículo contém referência e texto', () {
    final m = mensagemCompartilharVersiculo(
      referencia: 'João 3:16',
      texto: 'Porque Deus amou o mundo',
      link: 'https://exemplo.com',
    );
    expect(m, contains('João 3:16'));
    expect(m, contains('Porque Deus amou o mundo'));
    expect(m, contains('Baixe grátis'));
  });

  test('SC1: mensagem de capítulo usa referência natural e todo o texto', () {
    final m = mensagemCompartilharCapitulo(
      referencia: 'Salmo 23',
      texto: '1. O Senhor é o meu pastor.',
    );
    expect(m, contains('*Salmo 23*'));
    expect(m, contains('1. O Senhor é o meu pastor.'));
    expect(m, isNot(contains('Baixe grátis')));
  });

  test('SS1: mensagem de Salmo inclui título e explicação', () {
    final m = mensagemCompartilharSalmo(
      numero: 23,
      titulo: 'O Senhor é o meu pastor',
      explicacao: 'Atribuído a Davi, rei de Israel.',
    );
    expect(m, contains('Salmo 23 — O Senhor é o meu pastor'));
    expect(m, contains('Atribuído a Davi'));
  });

  test('SS1: Salmo sem título usa só o número no cabeçalho', () {
    final m = mensagemCompartilharSalmo(
      numero: 1,
      titulo: '',
      explicacao: '',
    );
    expect(m, contains('Salmo 1'));
    expect(m, isNot(contains('—')));
  });
}
