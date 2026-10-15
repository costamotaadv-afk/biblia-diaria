"""Casos CTX1–CTX7 — porte de test/contexto_historico_test.dart."""

import json
from pathlib import Path

from core.contexto_historico import (
    CertezaHistorica,
    analisar_referencia,
    certeza_de_codigo,
    contexto_do_salmo,
    contextos_de_json,
    explicacao_certeza,
    filtrar_contexto_por_busca,
    rotulo_certeza,
)

DATA_DIR = Path(__file__).resolve().parents[2] / 'assets' / 'data'


def test_ctx1_entrada_nao_lista():
    assert contextos_de_json(None) == []
    assert contextos_de_json('texto') == []
    assert contextos_de_json([]) == []


def test_ctx2_itens_invalidos_ignorados():
    contextos = contextos_de_json([
        'texto',
        42,
        None,
        {'id': '', 'salmo': 3},
        {'id': 'a', 'salmo': 0},
        {'id': 'ok', 'salmo': 3, 'titulo': 'T', 'certeza': 'tradicional'},
    ])
    assert len(contextos) == 1
    assert contextos[0].id == 'ok'


def test_ctx2_tipos_errados_em_listas():
    contexto = contextos_de_json([
        {
            'id': 'a',
            'salmo': 1,
            'classificacao': 'não-lista',
            'referencias_cruzadas': 'não-lista',
            'fontes': 'não-lista',
            'eventos': 'não-lista',
            'temas': 7,
        },
    ])[0]
    assert contexto.classificacao == []
    assert contexto.referencias_cruzadas == []
    assert contexto.fontes == []
    assert contexto.eventos == []
    assert contexto.temas == []


def test_ctx3_grau_de_certeza():
    assert certeza_de_codigo('documentado') == CertezaHistorica.documentado
    assert certeza_de_codigo('tradicional') == CertezaHistorica.tradicional
    assert certeza_de_codigo('hipotese') == CertezaHistorica.hipotese
    assert certeza_de_codigo('indeterminado') == CertezaHistorica.indeterminado
    assert certeza_de_codigo('outro') == CertezaHistorica.indeterminado
    assert certeza_de_codigo(None) == CertezaHistorica.indeterminado
    assert certeza_de_codigo('') == CertezaHistorica.indeterminado

    for certeza in CertezaHistorica:
        assert rotulo_certeza(certeza)
        assert explicacao_certeza(certeza)


def test_ctx4_analise_referencia():
    livros = ['Salmos', '2 Samuel', '1 Samuel', 'João', '1 Coríntios']

    a = analisar_referencia('2 Samuel 15', livros)
    assert a is not None and a.livro == '2 Samuel' and a.capitulo == 15 and a.versiculo is None

    b = analisar_referencia('2 Samuel 15–18', livros)
    assert b is not None and b.livro == '2 Samuel' and b.capitulo == 15

    c = analisar_referencia('João 3:16', livros)
    assert c is not None and c.livro == 'João' and c.capitulo == 3 and c.versiculo == 16

    d = analisar_referencia('1 Coríntios 13:4', livros)
    assert d is not None and d.livro == '1 Coríntios' and d.capitulo == 13 and d.versiculo == 4

    assert analisar_referencia('Hebreus 11', livros) is None
    assert analisar_referencia('', livros) is None


def test_ctx5_ctx6_busca_e_consulta():
    contextos = contextos_de_json([
        {
            'id': 's3', 'salmo': 3, 'titulo': 'Confiança em Deus', 'autoria': 'Davi',
            'personagens': ['Absalão'], 'lugares': ['Jerusalém'],
            'explicacao': 'Fuga durante a revolta.',
        },
        {
            'id': 's90', 'salmo': 90, 'titulo': 'Oração de Moisés', 'autoria': 'Moisés',
            'periodo': 'Período do deserto', 'lugares': ['Sinai'],
        },
    ])
    assert filtrar_contexto_por_busca(contextos, 'Absalão')[0].id == 's3'
    assert filtrar_contexto_por_busca(contextos, 'Sinai')[0].id == 's90'
    assert filtrar_contexto_por_busca(contextos, 'MOISÉS')[0].id == 's90'
    assert filtrar_contexto_por_busca(contextos, 'confianca')[0].id == 's3'
    assert filtrar_contexto_por_busca(contextos, 'salmo 3')[0].id == 's3'
    assert [c.numero for c in filtrar_contexto_por_busca(contextos, '')] == [3, 90]
    assert contexto_do_salmo(contextos, 90).id == 's90'
    assert contexto_do_salmo(contextos, 999) is None


def test_ctx7_integridade_150_salmos():
    arquivo = DATA_DIR / 'contexto' / 'Salmos.json'
    assert arquivo.exists()
    contextos = contextos_de_json(json.loads(arquivo.read_text(encoding='utf-8')))
    assert len(contextos) == 150

    ids = set()
    numeros = set()
    for c in contextos:
        assert c.id not in ids, f'id duplicado {c.id}'
        ids.add(c.id)
        numeros.add(c.numero)
        assert 1 <= c.numero <= 150
        assert c.titulo
        assert c.classificacao
        assert c.periodo
        assert c.contexto_politico
        assert c.localizacao
        assert c.explicacao
        assert c.fontes
    assert numeros == set(range(1, 151))


def test_ctx7_referencias_resolvem():
    indice = json.loads((DATA_DIR / 'indice.json').read_text(encoding='utf-8'))
    nomes = [f"{m['nome']}" for m in indice if isinstance(m, dict)]
    arquivo = DATA_DIR / 'contexto' / 'Salmos.json'
    contextos = contextos_de_json(json.loads(arquivo.read_text(encoding='utf-8')))
    for c in contextos:
        for ref in c.referencias_cruzadas:
            assert analisar_referencia(ref.referencia, nomes) is not None, (
                f'ref não resolvida: {ref.referencia}'
            )
