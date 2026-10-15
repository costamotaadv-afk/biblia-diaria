"""Aba Ajustes: aparência, leitura lenta, doação via Pix e sobre o app."""

import streamlit as st
import streamlit.components.v1 as components

from core import storage
from core.config import CHAVE_PIX


def render():
    st.markdown('### Aparência')
    st.toggle('Tema escuro', key='tema_escuro')
    st.toggle('Fonte grande', key='fonte_grande')

    st.markdown('### Leitura em voz alta')
    st.toggle('Leitura lenta', key='tts_lento')

    storage.salvar()

    st.divider()

    st.markdown('### ❤️ Apoiar o projeto via Pix')
    st.markdown(
        'Sua contribuição é voluntária e ajuda a manter este aplicativo gratuito. '
        'A doação será recebida em uma conta Nubank.'
    )

    st.markdown('**CHAVE PIX — E-MAIL**')
    st.code(CHAVE_PIX, language=None)
    _botao_copiar(CHAVE_PIX)

    st.markdown('**Como fazer a doação**')
    passos = [
        'Abra o aplicativo do seu banco.',
        'Toque em “Pix” e depois em “Transferir”.',
        'Cole a chave, escolha o valor e confira os dados.',
        'Confirme a doação somente se estiver tudo correto.',
    ]
    for i, passo in enumerate(passos, start=1):
        st.markdown(f'{i}. {passo}')

    st.caption('Antes de confirmar, confira no banco o nome de quem receberá.')

    st.divider()

    st.markdown('### Sobre o app')
    st.markdown('**Uso simples e legível**')
    st.caption(
        'Este app foi ajustado para facilitar leitura e toque para todas as idades.'
    )
    st.markdown('**Bíblia Diária • Offline • Gratuito**')


def _botao_copiar(texto: str) -> None:
    """Botão de copiar usando a Clipboard API do navegador (degradação graciosa)."""
    html = f"""
    <button onclick="navigator.clipboard.writeText('{texto}')
        .then(function(){{ this.innerText = 'Copiado!'; }}.bind(this))
        .catch(function(){{ this.innerText = 'Copie manualmente acima'; }}.bind(this))"
        style="padding:10px 18px; border:none; border-radius:8px;
               background:#3F51B5; color:#fff; cursor:pointer; font-size:15px;
               font-weight:600;">
      Copiar chave Pix
    </button>
    """
    components.html(html, height=46)
