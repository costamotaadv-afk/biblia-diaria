"""Síntese de voz neural (Google Cloud TTS / Azure Speech) via REST — stdlib only.

Backend **opcional** atrás da fachada ``ui.tts``. Quando configurado por
variáveis de ambiente, substitui a voz robótica do gTTS por uma voz neural com
licença comercial e latência baixa (uma única chamada HTTP). Sem configuração,
``sintetizar`` devolve ``None`` e o gTTS continua sendo o fallback.

Configuração (variáveis de ambiente, lidas no deploy):

    TTS_PROVEDOR        'google' | 'azure'  (ausente/vazio → backend desligado)
    TTS_VOZ             nome da voz (opcional; há padrão pt-BR por provedor)

    Google:  TTS_GOOGLE_API_KEY  (chave de API do Cloud Text-to-Speech)
    Azure:   TTS_AZURE_KEY + TTS_AZURE_REGION  (ex.: 'eastus')

Vozes padrão:
    Google  →  pt-BR-Neural2-C
    Azure   →  pt-BR-FranciscaNeural

Dependências: nenhuma além da stdlib (``urllib``, ``json``, ``base64``).
"""

import base64
import json
import os
import urllib.parse
import urllib.request

VOZ_PADRAO = {
    'google': 'pt-BR-Neural2-C',
    'azure': 'pt-BR-FranciscaNeural',
}

# Fator de "leitura lenta" (toggle já existente no app).
_TAXA_LENTA_GOOGLE = 0.85
_TAXA_LENTA_AZURE = '-15%'


def provedor() -> str:
    """Nome do provedor configurado (``'google'``/``'azure'``), ou ``''``."""
    return (os.environ.get('TTS_PROVEDOR') or '').strip().lower()


def configurado() -> bool:
    """True se há credenciais suficientes para usar o backend neural."""
    p = provedor()
    if p == 'google':
        return bool(os.environ.get('TTS_GOOGLE_API_KEY'))
    if p == 'azure':
        return bool(os.environ.get('TTS_AZURE_KEY')) and bool(os.environ.get('TTS_AZURE_REGION'))
    return False


def sintetizar(texto: str, lento: bool = False):
    """Devolve bytes de áudio MP3 pelo provedor configurado, ou ``None``.

    ``None`` significa "backend indisponível" (não configurado ou provedor
    desconhecido); o chamador deve usar o fallback (gTTS). Erros de rede/HTTP
    sobem como exceção e também são tratados pelo chamador.
    """
    if not configurado():
        return None
    p = provedor()
    if p == 'google':
        return _google(texto, lento)
    if p == 'azure':
        return _azure(texto, lento)
    return None


def _voz(p: str) -> str:
    return os.environ.get('TTS_VOZ') or VOZ_PADRAO[p]


def _google(texto: str, lento: bool):
    """Cloud Text-to-Speech v1 (REST) → MP3 (base64 em ``audioContent``)."""
    chave = os.environ['TTS_GOOGLE_API_KEY']
    url = 'https://texttospeech.googleapis.com/v1/text:synthesize?key=' + urllib.parse.quote(chave)
    payload = {
        'input': {'text': texto},
        'voice': {'languageCode': 'pt-BR', 'name': _voz('google')},
        'audioConfig': {
            'audioEncoding': 'MP3',
            'speakingRate': _TAXA_LENTA_GOOGLE if lento else 1.0,
        },
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode('utf-8'),
        headers={'Content-Type': 'application/json; charset=utf-8'},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        dados = json.load(resp)
    return base64.b64decode(dados['audioContent'])


def _azure(texto: str, lento: bool):
    """Azure Speech (REST, SSML) → MP3 direto no corpo da resposta."""
    regiao = os.environ['TTS_AZURE_REGION']
    url = f'https://{regiao}.tts.speech.microsoft.com/cognitiveservices/v1'
    taxa = _TAXA_LENTA_AZURE if lento else '+0%'
    ssml = (
        "<speak version='1.0' xml:lang='pt-BR'>"
        f"<voice name='{_voz('azure')}'>"
        f"<prosody rate='{taxa}'>{_escapa_xml(texto)}</prosody>"
        "</voice></speak>"
    )
    req = urllib.request.Request(
        url,
        data=ssml.encode('utf-8'),
        headers={
            'Content-Type': 'application/ssml+xml',
            'Ocp-Apim-Subscription-Key': os.environ['TTS_AZURE_KEY'],
            'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read()


def _escapa_xml(texto: str) -> str:
    """Escapa os caracteres que quebrariam o SSML do Azure."""
    return (texto.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))
