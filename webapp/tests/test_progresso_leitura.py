"""Testes puros do progresso de leitura (porte de ``lib/progresso_leitura.dart``)."""

from core.progresso_leitura import (
    contar_capitulos_lidos,
    fracao_lida,
    total_de_capitulos,
)


def test_total_de_capitulos():
    indice = [{'nome': 'A', 'capitulos': 3}, {'nome': 'B', 'capitulos': 2}]
    assert total_de_capitulos(indice) == 5


def test_total_ignora_tipos_invalidos():
    indice = [{'nome': 'A', 'capitulos': 'x'}, {'nome': 'B', 'capitulos': None}]
    assert total_de_capitulos(indice) == 0


def test_contar_capitulos_lidos_validos():
    indice = [{'nome': 'A', 'capitulos': 3}]
    lidos = {'A 1', 'A 99', 'B 1'}
    assert contar_capitulos_lidos(indice, lidos) == 1


def test_fracao_lida_clampada():
    indice = [{'nome': 'A', 'capitulos': 2}]
    assert fracao_lida(indice, {'A 1', 'A 2'}) == 1.0
    assert fracao_lida(indice, set()) == 0.0
    assert fracao_lida([], set()) == 0.0
