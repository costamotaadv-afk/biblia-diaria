"""Síntese de fala via gTTS (pt-BR) → MP3 → st.audio.

Substitui o flutter_tts: uma única voz pt-BR no servidor; reprodução manual e
não-contínua (o áudio fica no player, sem encadear versículos). O picker de voz
masculina/feminina do dispositivo dá lugar ao toggle "leitura lenta".
"""

import io

import streamlit as st

from core.catalogo_estudos import rotulo_tipo
from core.leitura_natural import referencia_para_leitura, texto_para_leitura_natural


@st.cache_data(show_spinner=False)
def _sintetizar(texto: str, lento: bool) -> bytes:
    """Gera o MP3 (gTTS divide internamente textos longos — cobre Salmos 119)."""
    from gtts import gTTS  # import lazy: gTTS é opcional e precisa de rede

    tts = gTTS(text=texto, lang='pt-br', slow=lento)
    buf = io.BytesIO()
    tts.write_to_fp(buf)
    return buf.getvalue()


def falar(texto: str, lento: bool = False) -> None:
    """Gera e exibe o áudio MP3 de ``texto`` (falha graciosa sem rede)."""
    texto = (texto or '').strip()
    if not texto:
        return
    try:
        mp3 = _sintetizar(texto, lento)
    except Exception:
        st.warning('Não foi possível gerar o áudio (verifique a conexão com a internet).')
        return
    st.audio(mp3, format='audio/mp3')


def falar_versiculo(referencia: str, texto: str, lento: bool = False) -> None:
    """Lê "João 3:16" como "João, capítulo três, versículo dezesseis" (E10/E11)."""
    falar(
        f'{referencia_para_leitura(referencia)}. {texto_para_leitura_natural(texto)}',
        lento,
    )


def falar_capitulo(chave_capitulo: str, texto_falado: str, lento: bool = False) -> None:
    """Lê um capítulo inteiro (texto já preparado por ``texto_de_capitulo_em_livros``)."""
    falar(f'{referencia_para_leitura(chave_capitulo)}. {texto_falado}', lento)


def falar_recurso(recurso, lento: bool = False) -> None:
    """Monta a leitura de um recurso de estudo (título, período, corpo, fatos)."""
    titulo = recurso.titulo if recurso.titulo else rotulo_tipo(recurso.tipo)
    corpo = texto_para_leitura_natural(recurso.corpo)
    periodo = texto_para_leitura_natural(recurso.periodo) if recurso.tem_periodo else ''
    fatos = ' '.join(texto_para_leitura_natural(f) for f in recurso.fatos)

    partes = [titulo]
    if periodo:
        partes.append(f'Período histórico: {periodo}')
    if corpo:
        partes.append(corpo)
    if fatos:
        partes.append(f'Fatos que iluminam o texto: {fatos}')
    falar('. '.join(partes), lento)


def falar_contexto(contexto, lento: bool = False) -> None:
    """Monta a leitura de um contexto histórico de Salmo."""
    titulo = (
        f'Salmo {contexto.numero}'
        if not contexto.titulo
        else f'Salmo {contexto.numero}. {contexto.titulo}'
    )
    partes = [titulo]
    if contexto.tem_autoria:
        partes.append(f'Autoria tradicional: {contexto.autoria}')
    if contexto.tem_periodo:
        partes.append(f'Período histórico: {contexto.periodo}')
    if contexto.tem_explicacao:
        partes.append(contexto.explicacao)
    falar('. '.join(partes), lento)
