"""Testes da fachada de cruzamentos históricos (core.cruzamentos).

Validam a agregação sobre um banco em memória e a degradação graciosa
quando o banco não existe (caso do Streamlit Cloud).
"""

import sqlite3

import pytest

from core import metadados_biblia as md
from core import cruzamentos


@pytest.fixture
def conn():
    """Banco em memória com o schema Theographic + um versículo de exemplo."""
    conexao = sqlite3.connect(':memory:')
    conexao.row_factory = sqlite3.Row
    for stmt in md.ESQUEMA:
        conexao.execute(stmt)
    conexao.executemany(
        'INSERT INTO verse_metadata VALUES (?,?,?,?,?,?,?,?,?,?)',
        [
            (43003016, 43, 3, 16, 'John.3.16', 'João 3:16', 27, 2, 1, None),
            (1001001, 1, 1, 1, 'Gen.1.1', 'Gênesis 1:1', -4003, 1, 0, None),
        ],
    )
    conexao.executemany(
        'INSERT INTO people VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',
        [
            (1, 'jesus', 'Jesus', None, 'Male', 1, -4, 30, -4, 30, 0, 'jesus'),
            (2, 'god', 'God', None, 'Male', 1, None, None, None, None, 0, 'god'),
        ],
    )
    conexao.executemany(
        'INSERT INTO places VALUES (?,?,?,?,?,?,?,?,?,?)',
        [(1, 'world', 'World', None, None, None, None, None, 0, 'world')],
    )
    conexao.executemany(
        'INSERT INTO events VALUES (?,?,?,?,?,?,?,?,?)',
        [(1, 'Jesus and Nicodemus', '27', None, 27.0, None, None, None, None)],
    )
    conexao.executemany(
        'INSERT INTO people_groups VALUES (?,?,?)',
        [(1, 'Jews', 'jews')],
    )
    conexao.execute('INSERT INTO verse_people VALUES (43003016, 1)')
    conexao.execute('INSERT INTO verse_people VALUES (43003016, 2)')
    conexao.execute('INSERT INTO verse_places VALUES (43003016, 1)')
    conexao.execute('INSERT INTO verse_events VALUES (43003016, 1)')
    conexao.execute('INSERT INTO verse_people_groups VALUES (43003016, 1)')
    conexao.commit()
    yield conexao
    conexao.close()


def test_cruzamentos_de_agrega(conn):
    dados = cruzamentos.cruzamentos_de(conn, 'João 3:16')
    assert dados is not None
    assert dados['referencia'] == 'João 3:16'
    assert [p['name'] for p in dados['pessoas']] == ['God', 'Jesus']
    assert [l['name'] for l in dados['lugares']] == ['World']
    assert [e['title'] for e in dados['eventos']] == ['Jesus and Nicodemus']
    assert [g['group_name'] for g in dados['grupos']] == ['Jews']


def test_cruzamentos_de_versiculo_sem_metadados(conn):
    assert cruzamentos.cruzamentos_de(conn, 'João 3:17') is None


def test_indisponivel_sem_banco(monkeypatch, tmp_path):
    monkeypatch.setenv('BIBLIA_METADADOS_DIR', str(tmp_path))
    assert cruzamentos.metadados_disponiveis() is False
    assert cruzamentos.cruzamentos_do_versiculo('João 3:16') is None
