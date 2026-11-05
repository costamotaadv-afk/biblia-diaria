"""Testes do backend de voz neural (Google/Azure) atrás da fachada ``tts``."""

import base64
import json
import urllib.request

import pytest

from core import tts_neural


@pytest.fixture
def limpar_env(monkeypatch):
    for v in ('TTS_PROVEDOR', 'TTS_VOZ', 'TTS_GOOGLE_API_KEY',
              'TTS_AZURE_KEY', 'TTS_AZURE_REGION'):
        monkeypatch.delenv(v, raising=False)


class _Resp:
    """Fake de ``urlopen`` que age como context manager e expõe ``read()``."""

    def __init__(self, dados):
        self._dados = dados

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False

    def read(self):
        return self._dados


def test_sem_configuracao_nao_usa_neural(limpar_env):
    assert tts_neural.provedor() == ''
    assert tts_neural.configurado() is False
    assert tts_neural.sintetizar('olá') is None


def test_google_requer_chave(monkeypatch, limpar_env):
    monkeypatch.setenv('TTS_PROVEDOR', 'google')
    assert tts_neural.configurado() is False
    monkeypatch.setenv('TTS_GOOGLE_API_KEY', 'chave')
    assert tts_neural.configurado() is True


def test_azure_requer_chave_e_regiao(monkeypatch, limpar_env):
    monkeypatch.setenv('TTS_PROVEDOR', 'azure')
    assert tts_neural.configurado() is False
    monkeypatch.setenv('TTS_AZURE_KEY', 'chave')
    monkeypatch.setenv('TTS_AZURE_REGION', 'eastus')
    assert tts_neural.configurado() is True


def test_escapa_xml():
    assert tts_neural._escapa_xml('a < b & c > d') == 'a &lt; b &amp; c &gt; d'


def test_google_sintetiza_mp3(monkeypatch, limpar_env):
    monkeypatch.setenv('TTS_PROVEDOR', 'google')
    monkeypatch.setenv('TTS_GOOGLE_API_KEY', 'chave')
    audio = b'\x00\x01\x02'
    capturado = {}

    def fake_urlopen(req, timeout=None):
        capturado['url'] = req.full_url
        capturado['payload'] = json.loads(req.data.decode('utf-8'))
        resp = json.dumps({'audioContent': base64.b64encode(audio).decode()}).encode()
        return _Resp(resp)

    monkeypatch.setattr(urllib.request, 'urlopen', fake_urlopen)
    assert tts_neural.sintetizar('olá') == audio
    assert capturado['payload']['voice']['name'] == 'pt-BR-Neural2-C'


def test_azure_sintetiza_mp3(monkeypatch, limpar_env):
    monkeypatch.setenv('TTS_PROVEDOR', 'azure')
    monkeypatch.setenv('TTS_AZURE_KEY', 'chave')
    monkeypatch.setenv('TTS_AZURE_REGION', 'eastus')
    audio = b'\x01\x02'
    capturado = {}

    def fake_urlopen(req, timeout=None):
        capturado['url'] = req.full_url
        capturado['ssml'] = req.data.decode('utf-8')
        return _Resp(audio)

    monkeypatch.setattr(urllib.request, 'urlopen', fake_urlopen)
    assert tts_neural.sintetizar('olá') == audio
    assert 'eastus.tts.speech.microsoft.com' in capturado['url']
    assert 'FranciscaNeural' in capturado['ssml']
    assert 'olá' in capturado['ssml']
