"""Casos E1–E9, E13, B5 e E16 — porte de test/limites_dados_test.dart e
test/robustez_e16_test.dart.
"""

from datetime import date

from core.dados_seguros import (
    como_lista,
    dias_desde_epoca,
    mapas_seguros,
    normalizar_mensagens,
    selecionar_versiculo_do_dia,
    texto_de_capitulo_em_livros,
    texto_de_versiculo_em_livros,
)

LIVRO_GENESIS = {
    'nome': 'Gênesis',
    'capitulos': [
        {
            'numero': 1,
            'versiculos': [
                {'numero': 1, 'texto': 'No princípio, criou Deus o céu e a terra.'},
                {'numero': 2, 'texto': 'A terra, porém, estava sem forma e vazia.'},
            ],
        },
        {
            'numero': 2,
            'versiculos': [
                {'numero': 1, 'texto': 'Assim foram acabados os céus e a terra.'},
            ],
        },
    ],
}


def test_como_lista_aceita_lista():
    assert como_lista([1, 2, 3]) == [1, 2, 3]


def test_como_lista_tipo_errado_devuelve_none():
    assert como_lista({'errado': True}) is None
    assert como_lista('texto') is None
    assert como_lista(42) is None
    assert como_lista(None) is None


def test_dias_desde_epoca():
    assert dias_desde_epoca(date(2024, 1, 1)) == 0
    assert dias_desde_epoca(date(2024, 1, 2)) == 1
    assert dias_desde_epoca(date(2023, 12, 31)) == -1
    assert dias_desde_epoca(date(2023, 6, 15)) < 0
    assert dias_desde_epoca(date(9999, 12, 31)) > 0
    assert dias_desde_epoca(date(2025, 3, 10)) == dias_desde_epoca(date(2025, 3, 10))


def test_selecionar_livro_nulo():
    r = selecionar_versiculo_do_dia(dia=0, mensagens=[], livro=None)
    assert r['versiculo'] == 'Carregando conteúdo...'
    assert r['referencia'] == ''
    assert r['mensagem'] == 'Deus te fortaleça neste dia.'


def test_selecionar_capitulos_tipo_errado():
    r = selecionar_versiculo_do_dia(
        dia=0, mensagens=[], livro={'nome': 'Gênesis', 'capitulos': {'errado': True}}
    )
    assert r['versiculo'] == 'Sem conteúdo bíblico disponível.'


def test_selecionar_capitulos_ausente():
    r = selecionar_versiculo_do_dia(dia=0, mensagens=[], livro={'nome': 'Gênesis'})
    assert r['versiculo'] == 'Sem conteúdo bíblico disponível.'


def test_selecionar_versiculos_vazios():
    r = selecionar_versiculo_do_dia(
        dia=0,
        mensagens=[],
        livro={'nome': 'Gênesis', 'capitulos': [{'numero': 1, 'versiculos': []}]},
    )
    assert r['versiculo'] == 'Sem conteúdo bíblico disponível.'


def test_selecionar_texto_vazio():
    r = selecionar_versiculo_do_dia(
        dia=0,
        mensagens=[],
        livro={
            'nome': 'Gênesis',
            'capitulos': [{'numero': 1, 'versiculos': [{'numero': 1, 'texto': '   '}]}],
        },
    )
    assert r['versiculo'] == 'Sem conteúdo bíblico disponível.'
    assert r['referencia'] == ''


def test_b5_ciclo_deterministico():
    assert (
        selecionar_versiculo_do_dia(dia=0, mensagens=[], livro=LIVRO_GENESIS)['referencia']
        == 'Gênesis 1:1'
    )
    assert (
        selecionar_versiculo_do_dia(dia=66, mensagens=[], livro=LIVRO_GENESIS)['referencia']
        == 'Gênesis 2:1'
    )
    assert (
        selecionar_versiculo_do_dia(dia=132, mensagens=[], livro=LIVRO_GENESIS)['referencia']
        == 'Gênesis 1:2'
    )
    assert (
        selecionar_versiculo_do_dia(dia=264, mensagens=[], livro=LIVRO_GENESIS)['referencia']
        == 'Gênesis 1:1'
    )


def test_e13_dia_negativo_deterministico():
    r = selecionar_versiculo_do_dia(dia=-1, mensagens=[], livro=LIVRO_GENESIS)
    assert r['referencia']
    assert r == selecionar_versiculo_do_dia(dia=-1, mensagens=[], livro=LIVRO_GENESIS)


def test_mensagens_fallback_e_circular():
    assert (
        selecionar_versiculo_do_dia(dia=0, mensagens=[], livro=LIVRO_GENESIS)['mensagem']
        == 'Deus te fortaleça neste dia.'
    )
    assert (
        selecionar_versiculo_do_dia(dia=1, mensagens=['M1', 'M2'], livro=None)['mensagem']
        == 'M2'
    )


def test_normalizar_mensagens_descarta_nao_string():
    assert normalizar_mensagens([123, {'a': 1}, None, 'Ola  ', '  ']) == ['Ola  ']


def test_normalizar_mensagens_vazia():
    assert normalizar_mensagens([]) == []
    assert normalizar_mensagens('nao-e-lista') == []
    assert normalizar_mensagens(None) == []


def test_normalizar_mensagens_aceita_so_nao_vazias():
    assert normalizar_mensagens(['Deus te abençoe.', '', '   ', 'Segunda']) == [
        'Deus te abençoe.',
        'Segunda',
    ]


def test_mapas_seguros_descarta_nao_mapa():
    assert mapas_seguros(None) == []
    assert mapas_seguros([1, 'x', None, {'a': 1}, {'b': 2}]) == [{'a': 1}, {'b': 2}]


def test_e16_texto_de_versiculo_em_livros():
    assert texto_de_versiculo_em_livros([LIVRO_GENESIS], 'Gênesis 1:1') == (
        'No princípio, criou Deus o céu e a terra.'
    )
    assert texto_de_versiculo_em_livros([LIVRO_GENESIS], 'Gênesis 99:1') is None
    # Corrupção interna não lança (itens não-mapa são ignorados).
    corrompido = {
        'nome': 'X',
        'capitulos': [{'numero': 1, 'versiculos': ['sujo', {'numero': 1, 'texto': 'ok'}]}],
    }
    assert texto_de_versiculo_em_livros([corrompido], 'X 1:1') == 'ok'


def test_e16_texto_de_capitulo_em_livros():
    texto = texto_de_capitulo_em_livros([LIVRO_GENESIS], 'Gênesis 1')
    assert texto == (
        'Versículo um. No princípio, criou Deus o céu e a terra. '
        'Versículo dois. A terra, porém, estava sem forma e vazia.'
    )
    assert texto_de_capitulo_em_livros([LIVRO_GENESIS], 'Gênesis 99') is None
