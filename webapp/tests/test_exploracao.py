"""Testes da fachada de exploração e das funções puras novas do Theographic."""

import sqlite3

import pytest

from core import metadados_biblia as md
from core import exploracao


@pytest.fixture
def conn():
    conexao = sqlite3.connect(':memory:')
    conexao.row_factory = sqlite3.Row
    for stmt in md.ESQUEMA:
        conexao.execute(stmt)
    conexao.executemany(
        'INSERT INTO people VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',
        [
            (1, 'moses', 'Moses', None, 'Male', 1, -1570, -1450, -1570, -1450, 774, 'moses'),
            (2, 'god', 'God', None, 'Male', 1, None, None, None, None, 8587, 'god'),
            (3, 'abigail', 'Abigail', None, 'Female', 1, None, None, None, None, 3, 'abigail'),
        ],
    )
    conexao.executemany(
        'INSERT INTO places VALUES (?,?,?,?,?,?,?,?,?,?)',
        [
            (1, 'jerusalem', 'Jerusalem', None, None, None, 'city', None, 754, 'jerusalem'),
            (2, 'eden', 'Eden', None, None, None, 'garden', None, 4, 'eden'),
        ],
    )
    conexao.executemany(
        'INSERT INTO easton VALUES (?,?,?,?)',
        [
            (1, 'Aaron', 'Aaron', 'eldest son of Amram'),
            (2, 'Aaronites', 'Aaronites', 'descendants of Aaron'),
            (3, 'Abba', 'Abba', 'a Syriac word'),
            (4, 'Aaron-1', 'Aaron', 'outra entrada Aaron (homônima)'),
        ],
    )
    conexao.executemany(
        'INSERT INTO verse_metadata VALUES (?,?,?,?,?,?,?,?,?,?)',
        [
            (1001001, 1, 1, 1, 'Gen.1.1', 'Gênesis 1:1', -4003, 1, 0, None),
            (2002001, 2, 2, 1, 'Exod.2.1', 'Êxodo 2:1', -1570, 1, 0, None),
        ],
    )
    conexao.execute('INSERT INTO verse_people VALUES (1001001, 1)')
    conexao.execute('INSERT INTO verse_people VALUES (2002001, 1)')
    conexao.commit()
    yield conexao
    conexao.close()


def test_listar_pessoas_ordena_por_relevancia(conn):
    assert [r['name'] for r in md.listar_pessoas(conn)] == ['God', 'Moses', 'Abigail']


def test_listar_pessoas_com_limite(conn):
    assert [r['name'] for r in md.listar_pessoas(conn, 2)] == ['God', 'Moses']


def test_listar_lugares_ordena_por_relevancia(conn):
    assert [r['name'] for r in md.listar_lugares(conn)] == ['Jerusalem', 'Eden']


def test_buscar_easton_por_termo(conn):
    r = md.buscar_easton(conn, 'aaron')
    assert r is not None and r['term_label'] == 'Aaron'
    assert md.buscar_easton(conn, 'nao-existe') is None


def test_sugerir_easton_substring(conn):
    linhas = md.sugerir_easton(conn, 'aar')
    assert [r['term_label'] for r in linhas] == ['Aaron', 'Aaronites']


def test_versiculos_da_pessoa_ordenados(conn):
    linhas = md.versiculos_da_pessoa(conn, 1)
    assert [r['verse_reference'] for r in linhas] == ['Gênesis 1:1', 'Êxodo 2:1']


def test_facade_degrada_sem_banco(monkeypatch, tmp_path):
    monkeypatch.setenv('BIBLIA_METADADOS_DIR', str(tmp_path))
    assert exploracao.disponivel() is False
    assert exploracao.listar_pessoas() == []
    assert exploracao.listar_lugares() == []
    assert exploracao.cronologia() == []
    assert exploracao.buscar_easton('Aaron') is None
