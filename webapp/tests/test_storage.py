"""Regressão: navegação não é persistida e preferências são persistidas."""

import core.storage as storage


def test_navegacao_nao_e_persistida():
    """A aba/seção/modo ficam só na sessão (app abre sempre na aba Início)."""
    for chave in ('aba', 'estudos_secao', 'explorar_modo'):
        assert chave not in storage._PERSIST_KEYS


def test_preferencias_persistidas():
    """Preferências do leitor são persistidas."""
    for chave in (
        'tema',
        'escala_pct',
        'altura_linha',
        'tts_lento',
        'favoritos_versiculos',
        'favoritos_capitulos',
        'favoritos_estudos',
        'capitulos_lidos',
        'notas_versiculos',
        'destaques_versiculos',
    ):
        assert chave in storage._PERSIST_KEYS
