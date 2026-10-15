"""Casos E6/E7/E10/E11/E12 — porte de test/edge_cases_e10_test.dart."""

from core.leitura_natural import (
    dividir_texto_para_fala,
    escrever_numero,
    nome_livro_para_leitura,
    numero_por_extenso,
    referencia_para_leitura,
    texto_para_leitura_natural,
)


def test_e10_referencia_prefixo_numerico():
    assert referencia_para_leitura('1 Coríntios 2:3') == (
        'Primeira Coríntios, capítulo dois, versículo três'
    )
    assert referencia_para_leitura('1 João 3:16') == (
        'Primeira João, capítulo três, versículo dezesseis'
    )
    assert referencia_para_leitura('2 Reis 4:1') == (
        'Segunda Reis, capítulo quatro, versículo um'
    )
    assert referencia_para_leitura('3 João 1') == 'Terceira João, capítulo um'
    assert referencia_para_leitura('1 Samuel 2:1') == (
        'Primeira Samuel, capítulo dois, versículo um'
    )
    assert referencia_para_leitura('Salmos 119:176') == (
        'Salmos, capítulo cento e dezenove, versículo cento e setenta e seis'
    )


def test_referencia_casos_gerais():
    assert referencia_para_leitura('Gênesis 1:1') == 'Gênesis, capítulo um, versículo um'
    assert referencia_para_leitura('Salmos 23') == 'Salmos, capítulo vinte e três'
    assert referencia_para_leitura('Lamentações de Jeremias 3:22') == (
        'Lamentações de Jeremias, capítulo três, versículo vinte e dois'
    )
    assert referencia_para_leitura('Apocalipse') == 'Apocalipse'
    assert referencia_para_leitura('') == ''
    assert referencia_para_leitura('   ') == ''


def test_e11_texto_com_referencias_cruzadas():
    assert 'joão, capítulo três, versículo dezesseis' in texto_para_leitura_natural(
        'Disse-lhe Jesus: João 3:16, com amor.'
    )
    assert 'primeira co, capítulo dois, versículo três' in texto_para_leitura_natural(
        'Veja 1 Co 2:3 no contexto.'
    )
    assert (
        'salmos, capítulo cento e dezenove, versículo cento e setenta e seis'
        in texto_para_leitura_natural('Compare com Salmos 119:176.')
    )


def test_e11_referencia_malformada_4_digitos():
    resultado = texto_para_leitura_natural('Veja Salmos 1190:12, amigo.')
    assert resultado
    assert '1190:12' in resultado
    assert 'primeira co, capítulo dois, versículo três' in texto_para_leitura_natural(
        'Veja 1 Co 2:3 no contexto.'
    )


def test_e6_e7_numero_invalido():
    assert referencia_para_leitura('Gênesis abc:1') == 'Gênesis abc:1'
    assert referencia_para_leitura('Gênesis 1000:1') == 'Gênesis 1000:1'


def test_escrever_numero_limites():
    assert escrever_numero(0) == 'zero'
    assert escrever_numero(999) == 'novecentos e noventa e nove'
    assert escrever_numero(100) == 'cem'
    assert escrever_numero(101) == 'cento e um'
    assert escrever_numero(1000) == '1000'
    assert escrever_numero(-1) == '-1'


def test_numero_por_extenso_nao_numerico():
    assert numero_por_extenso('abc') == 'abc'
    assert numero_por_extenso('') == ''


def test_nome_livro_sem_prefixo_intacto():
    assert nome_livro_para_leitura('Gênesis') == 'Gênesis'
    assert nome_livro_para_leitura('1 Coríntios') == 'Primeira Coríntios'
    assert nome_livro_para_leitura('10 Livro') == 'Décima Livro'


def test_e12_dividir_texto_para_fala():
    assert dividir_texto_para_fala('Olá mundo.') == ['Olá mundo.']
    assert dividir_texto_para_fala('') == []

    frases = ' '.join(
        f'Versículo {i}. Esta é uma frase de teste que continua.'
        for i in range(200)
    )
    segmentos = dividir_texto_para_fala(frases, max_caracteres=200)
    assert len(segmentos) > 1
    assert all(len(s) <= 200 for s in segmentos)
    assert all(s.strip() for s in segmentos)


def test_e12_corta_em_pontuacao():
    segmentos = dividir_texto_para_fala(
        'Primeira frase. Segunda frase! Terceira? Quarta; Quinta.',
        max_caracteres=30,
    )
    for segmento in segmentos[:-1]:
        assert segmento[-1] in ('.', '!', '?', ';')
