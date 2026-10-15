"""Casos EST1–EST8 — porte de test/catalogo_estudos_test.dart."""

from core.catalogo_estudos import (
    RecursoEstudo,
    filtrar_por_busca,
    filtrar_recursos,
    livros_disponiveis,
    recursos_aplicaveis,
    recursos_de_json,
    tipos_disponiveis,
)


def test_est1_entrada_nao_lista():
    assert recursos_de_json(None) == []
    assert recursos_de_json('texto') == []
    assert recursos_de_json([]) == []


def test_est2_itens_invalidos_ignorados():
    entrada = [
        'texto',
        42,
        None,
        {'id': '', 'titulo': 'sem id'},
        {'titulo': 'sem id 2'},
        {'id': 'ok', 'tipo': 'nota', 'titulo': 'Válido', 'corpo': 'x'},
    ]
    recursos = recursos_de_json(entrada)
    assert len(recursos) == 1
    assert recursos[0].id == 'ok'


def test_est2_tipos_errados_nao_lancam():
    recursos = recursos_de_json([
        {'id': 'a', 'tipo': 7, 'titulo': True, 'tema': 'não-lista', 'fonte': 'x'},
    ])
    assert len(recursos) == 1
    assert recursos[0].temas == []
    assert recursos[0].fonte is None


def test_est4_corpo_vazio():
    vazio = recursos_de_json([{'id': 'a', 'corpo': '   '}])[0]
    assert vazio.tem_corpo is False

    cheio = recursos_de_json([{'id': 'a', 'corpo': 'Olá'}])[0]
    assert cheio.tem_corpo is True


def test_est4_fonte_parcial():
    com_fonte = recursos_de_json([
        {'id': 'a', 'fonte': {'autor': 'Autor', 'obra': 'Obra', 'ano': '2026'}},
    ])[0]
    assert com_fonte.tem_fonte is True
    assert com_fonte.fonte.credito == 'Autor, Obra (2026)'

    sem_fonte = recursos_de_json([{'id': 'b'}])[0]
    assert sem_fonte.tem_fonte is False


def _recursos_est3():
    return [
        RecursoEstudo(id='v', tipo='nota', titulo='', corpo='c', referencia='João 3:16', livro='João'),
        RecursoEstudo(id='c', tipo='comentario', titulo='', corpo='c', referencia='João 3', livro='João'),
        RecursoEstudo(id='l', tipo='artigo', titulo='', corpo='c', referencia='João', livro='João'),
        RecursoEstudo(id='n', tipo='nota', titulo='', corpo='c', referencia='1 João 4:8', livro='1 João'),
    ]


def test_est3_versiculo_herda_capitulo_e_livro():
    ids = {r.id for r in recursos_aplicaveis(_recursos_est3(), 'João 3:16', livro='João')}
    assert ids == {'v', 'c', 'l'}


def test_est3_prefixo_numerico_nao_confunde():
    ids = {r.id for r in recursos_aplicaveis(_recursos_est3(), '1 João 4:8', livro='1 João')}
    assert ids == {'n'}


def test_est5_filtros():
    recursos = recursos_de_json([
        {'id': '1', 'tipo': 'nota', 'livro': 'João'},
        {'id': '2', 'tipo': 'artigo', 'livro': 'Salmos'},
    ])
    assert filtrar_recursos(recursos, tipo='nota')[0].id == '1'
    assert filtrar_recursos(recursos, livro='Salmos')[0].id == '2'
    assert filtrar_recursos(recursos, tipo='sermao') == []
    assert tipos_disponiveis(recursos) == ['nota', 'artigo']
    assert livros_disponiveis(recursos) == ['João', 'Salmos']


def test_est7_busca():
    recursos = recursos_de_json([
        {'id': '1', 'tipo': 'nota', 'titulo': 'Criação',
         'corpo': 'No princípio, Deus criou os céus e a terra.', 'temas': ['origem', 'mundo']},
        {'id': '2', 'tipo': 'artigo', 'titulo': 'Salvação',
         'corpo': 'Pela graça sois salvos, por meio da fé.', 'temas': ['graça', 'fé']},
        {'id': '3', 'tipo': 'sermao', 'titulo': 'Amor',
         'corpo': 'Deus é amor.', 'temas': ['amor']},
    ])
    assert filtrar_por_busca(recursos, 'criação')[0].id == '1'
    assert filtrar_por_busca(recursos, 'GRACA')[0].id == '2'
    assert filtrar_por_busca(recursos, 'fé')[0].id == '2'
    assert filtrar_por_busca(recursos, 'amor')[0].id == '3'
    assert len(filtrar_por_busca(recursos, '')) == 3
    assert len(filtrar_por_busca(recursos, '   ')) == 3
    assert filtrar_por_busca(recursos, 'inexistente') == []


def test_est8_periodo_e_fatos():
    com_contexto = recursos_de_json([
        {'id': 'a', 'tipo': 'momento_historico',
         'periodo': 'Novo Império Egípcio (c. 1550–1069 a.C.)',
         'fatos': ['Fato um', 'Fato dois']},
    ])[0]
    assert com_contexto.tem_periodo is True
    assert com_contexto.periodo == 'Novo Império Egípcio (c. 1550–1069 a.C.)'
    assert com_contexto.tem_fatos is True
    assert com_contexto.fatos == ['Fato um', 'Fato dois']

    sem_contexto = recursos_de_json([{'id': 'b', 'tipo': 'nota'}])[0]
    assert sem_contexto.tem_periodo is False
    assert sem_contexto.periodo == ''
    assert sem_contexto.tem_fatos is False
    assert sem_contexto.fatos == []


def test_est8_periodo_fatos_invalidos():
    recurso = recursos_de_json([{'id': 'a', 'periodo': None, 'fatos': 'não-lista'}])[0]
    assert recurso.tem_periodo is False
    assert recurso.periodo == ''
    assert recurso.tem_fatos is False
    assert recurso.fatos == []

    recurso2 = recursos_de_json([{'id': 'a', 'periodo': '   ', 'fatos': [' ', 'ok', '  ']}])[0]
    assert recurso2.tem_periodo is False
    assert recurso2.fatos == ['ok']
