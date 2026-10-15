"""Loaders de dados (impl sem cache) e resolução do diretório de dados."""

from core import data_source


def test_data_dir_existe():
    d = data_source.data_dir()
    assert (d / 'indice.json').exists()
    assert (d / 'livros' / 'Gênesis.json').exists()
    assert (d / 'contexto' / 'Salmos.json').exists()


def test_carregar_indice_impl():
    assert len(data_source._carregar_indice()) == 66


def test_carregar_mensagens_impl():
    assert data_source._carregar_mensagens()


def test_carregar_livro_impl():
    livro = data_source._carregar_livro('Gênesis')
    assert livro is not None
    assert livro.get('nome') == 'Gênesis'
    assert data_source._carregar_livro('Livro Inexistente') is None


def test_carregar_estudos_impl():
    indice = data_source._carregar_estudos_indice()
    assert indice
    assert all(r.id for r in indice)
    detalhe = data_source._carregar_estudos_livro('João')
    assert any(r.tem_corpo for r in detalhe)


def test_carregar_contexto_impl():
    contextos = data_source._carregar_contexto_livro('Salmos')
    assert len(contextos) == 150
