"""Compartilhamento (SH1/SH3) — porte de test/compartilhamento_test.dart."""

import urllib.parse

from core.config import (
    LINK_DOWNLOAD,
    link_valido,
    mensagem_capitulo,
    mensagem_compartilhamento,
    mensagem_salmo,
    mensagem_versiculo,
    url_whatsapp,
)


def test_link_comeca_vazio_e_validacao_so_aceita_url_http():
    assert LINK_DOWNLOAD == ''
    assert link_valido('') is False
    assert link_valido('   ') is False
    assert link_valido('ftp://exemplo.com') is False
    assert link_valido('https://biblia-diaria.streamlit.app') is True


def test_mensagem_contem_nome_e_link():
    link = 'https://biblia-diaria.streamlit.app'
    mensagem = mensagem_compartilhamento(link)
    assert 'Bíblia Diária' in mensagem
    assert link in mensagem


def test_url_whatsapp_faz_roundtrip_da_mensagem():
    link = 'https://biblia-diaria.streamlit.app'
    mensagem = mensagem_compartilhamento(link)
    url = url_whatsapp(mensagem)

    assert url.startswith('https://wa.me/?text=')
    parsed = urllib.parse.parse_qs(urllib.parse.urlparse(url).query)
    assert parsed['text'][0] == mensagem


def test_mensagem_versiculo_contem_referencia_e_texto():
    m = mensagem_versiculo(
        'João 3:16', 'Porque Deus amou o mundo', link='https://exemplo.com'
    )
    assert 'João 3:16' in m
    assert 'Porque Deus amou o mundo' in m
    assert 'Baixe grátis' in m


def test_mensagem_capitulo_e_salmo():
    cap = mensagem_capitulo('Salmo 23', '1. O Senhor é o meu pastor.')
    assert '*Salmo 23*' in cap
    assert '1. O Senhor é o meu pastor.' in cap
    assert 'Baixe grátis' not in cap

    salmo = mensagem_salmo(23, 'O Senhor é o meu pastor', 'Atribuído a Davi.')
    assert 'Salmo 23 — O Senhor é o meu pastor' in salmo
    assert 'Atribuído a Davi.' in salmo


def test_url_whatsapp_roundtrip_dos_conteudos():
    mensagens = [
        mensagem_versiculo('João 3:16', 'Porque Deus amou o mundo'),
        mensagem_capitulo('Gênesis 1', '1. No princípio'),
        mensagem_salmo(23, 'Pastor', 'Explicação.'),
    ]
    for m in mensagens:
        url = url_whatsapp(m)
        parsed = urllib.parse.parse_qs(urllib.parse.urlparse(url).query)
        assert parsed['text'][0] == m
