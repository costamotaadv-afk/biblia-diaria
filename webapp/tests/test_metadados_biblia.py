"""Testes das funções puras do cruzamento de metadados históricos.

Não fazem download nem exigem o banco construído — apenas validam a lógica
de codificação de versículos, rótulos de ano e o mapeamento de livros.
"""

from core import metadados_biblia as md


def test_versiculo_id_codificacao():
    assert md.versiculo_id(43, 3, 16) == 43003016
    assert md.versiculo_id(1, 1, 1) == 1001001
    assert md.versiculo_id(19, 119, 176) == 19119176


def test_decodificar_versiculo_id():
    assert md.decodificar_versiculo_id(43003016) == (43, 3, 16)
    assert md.decodificar_versiculo_id(1001001) == (1, 1, 1)
    assert md.decodificar_versiculo_id(19119176) == (19, 119, 176)


def test_versiculo_id_ida_e_volta():
    for livro, cap, vers in [(1, 1, 1), (43, 3, 16), (66, 22, 21), (19, 119, 176)]:
        assert md.decodificar_versiculo_id(md.versiculo_id(livro, cap, vers)) == (livro, cap, vers)


def test_referencias():
    assert md.referencia_versiculo("João", 3, 16) == "João 3:16"
    assert md.referencia_capitulo("Gênesis", 1) == "Gênesis 1"


def test_rotulo_ano():
    assert md.rotulo_ano(-4003) == "4004 a.C."
    assert md.rotulo_ano(0) == "1 a.C."
    assert md.rotulo_ano(1) == "1 d.C."
    assert md.rotulo_ano(30) == "30 d.C."
    assert md.rotulo_ano(None) is None


def test_slug():
    assert md._slug("João") == "joao"
    assert md._slug("Egypt") == "egypt"
    assert md._slug("") == ""


def test_mapear_livros():
    indice = [{"nome": "Gênesis", "capitulos": 50}, {"nome": "Êxodo", "capitulos": 40}]
    livros = [
        {"id": "recA", "fields": {"bookOrder": 2, "osisName": "Exod",
                                  "bookName": "Exodus", "chapterCount": 40}},
        {"id": "recB", "fields": {"bookOrder": 1, "osisName": "Gen",
                                  "bookName": "Genesis", "chapterCount": 50}},
    ]
    livro_por_ordem, osis_para_ordem, record_para_livro, caps = md.mapear_livros(indice, livros)
    assert livro_por_ordem[1]["local_name"] == "Gênesis"
    assert livro_por_ordem[2]["local_name"] == "Êxodo"
    assert osis_para_ordem["gen"] == 1
    assert osis_para_ordem["exod"] == 2
    assert record_para_livro["recB"] == 1
    assert caps == {1: 50, 2: 40}


def test_extrair_ref_versiculo():
    osis = {"gen": 1, "john": 43}
    # Pelo verseID (BBCCCVVV).
    assert md._extrair_ref_versiculo({"verseID": "43003016"}, osis) == (43, 3, 16)
    assert md._extrair_ref_versiculo({"verseID": "01001001"}, osis) == (1, 1, 1)
    # Fallback pelo osisRef.
    assert md._extrair_ref_versiculo({"osisRef": "John.3.16"}, osis) == (43, 3, 16)
    # Irresolvível.
    assert md._extrair_ref_versiculo({}, osis) == (None, None, None)


def test_rotulo_ano_string_negativa():
    assert md.rotulo_ano("-1084") == "1085 a.C."
