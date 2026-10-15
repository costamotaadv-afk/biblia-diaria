"""Integridade dos dados + goldens determinísticos do versículo do dia.

Cross-check com ``test/virada_dia_b4_test.dart`` (dia 0/1/2 → Gênesis/Êxodo/
Levítico 1:1) e ``test/limites_dados_test.dart`` (B5).
"""

import json
from pathlib import Path

from core.dados_seguros import (
    normalizar_mensagens,
    selecionar_versiculo_do_dia,
)

DATA_DIR = Path(__file__).resolve().parents[2] / 'assets' / 'data'


def _ler(nome):
    with open(DATA_DIR / nome, encoding='utf-8') as f:
        return json.load(f)


def test_66_livros_no_indice():
    indice = _ler('indice.json')
    assert len(indice) == 66


def test_verse_of_day_goldens():
    indice = _ler('indice.json')
    mensagens = normalizar_mensagens(_ler('mensagens.json'))
    casos = {0: 'Gênesis 1:1', 1: 'Êxodo 1:1', 2: 'Levítico 1:1'}
    for dia, esperado in casos.items():
        nome = f"{indice[dia % len(indice)]['nome']}"
        livro = _ler(f'livros/{nome}.json')
        r = selecionar_versiculo_do_dia(dia=dia, mensagens=mensagens, livro=livro)
        assert r['referencia'] == esperado, f'dia {dia} → {r["referencia"]} != {esperado}'


def test_mensagens_carregam():
    mensagens = normalizar_mensagens(_ler('mensagens.json'))
    assert mensagens
