"""Testes do mapa curado PT ↔ EN dos nomes do Theographic."""

from core import nomes_pt


def test_traduz_pessoas():
    assert nomes_pt.traduzir('God') == 'Deus'
    assert nomes_pt.traduzir('Moses') == 'Moisés'
    assert nomes_pt.traduzir('Holy Spirit') == 'Espírito Santo'
    assert nomes_pt.traduzir('Pontius') == 'Pôncio Pilatos'


def test_traduz_lugares():
    assert nomes_pt.traduzir('Jerusalem') == 'Jerusalém'
    assert nomes_pt.traduzir('Red sea') == 'Mar Vermelho'
    assert nomes_pt.traduzir('mount Sinai') == 'monte Sinai'


def test_traduz_eventos():
    assert nomes_pt.traduzir('The Last Supper') == 'A Última Ceia'
    assert nomes_pt.traduzir("Job's Trial") == 'Provação de Jó'


def test_traduz_grupos():
    assert nomes_pt.traduzir('Pharisees') == 'Fariseus'
    assert nomes_pt.traduzir('Tribe of Judah') == 'Tribo de Judá'


def test_traduz_evento_narrativo():
    assert nomes_pt.traduzir('Creation of Adam and Eve') == 'Criação de Adão e Eva'
    assert nomes_pt.traduzir('Jesus and Nicodemus') == 'Jesus e Nicodemos'
    # fonte tem erro de digitação ("form" em vez de "from")
    assert nomes_pt.traduzir('Lazarus Raised form the Dead') == 'Lázaro Ressuscitado dos Mortos'


def test_traduz_novo_testamento():
    assert nomes_pt.traduzir('Timotheus') == 'Timóteo'
    assert nomes_pt.traduzir('Herod Antipas') == 'Herodes Antipas'
    assert nomes_pt.traduzir('Zacchaeus') == 'Zaqueu'
    assert nomes_pt.traduzir('mount of Olives') == 'monte das Oliveiras'
    assert nomes_pt.traduzir('Eden') == 'Éden'
    assert nomes_pt.traduzir('Birth of Jesus') == 'Nascimento de Jesus'


def test_nome_sem_traducao_mantem_original():
    assert nomes_pt.traduzir('Ziklag') == 'Ziklag'  # fora do mapa
    assert nomes_pt.traduzir('Samuel') == 'Samuel'  # igual nas duas línguas
