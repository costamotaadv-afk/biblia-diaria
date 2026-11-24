"""Aba Ajustes: aparência, leitura em voz alta, doação via Pix e sobre o app."""

import streamlit as st

from core import storage
from core.config import CHAVE_PIX
from . import clipboard


_ROTULOS_TEMA = {
    'claro': '☀️ Claro',
    'escuro': '🌙 Escuro',
    'sepia': '📜 Sépia',
}


def render():
    st.markdown('<div class="bd-section">Aparência</div>', unsafe_allow_html=True)
    st.radio(
        'Tema',
        ['claro', 'escuro', 'sepia'],
        key='tema',
        horizontal=True,
        format_func=lambda m: _ROTULOS_TEMA.get(m, m),
        label_visibility='collapsed',
    )

    st.slider(
        'Tamanho do texto',
        min_value=100,
        max_value=160,
        step=2,
        format='%d%%',
        key='escala_pct',
    )
    st.slider(
        'Espaçamento de linha',
        min_value=1.4,
        max_value=1.8,
        step=0.05,
        format='%.2fx',
        key='altura_linha',
    )

    st.markdown(
        '<div class="bd-section">Leitura em voz alta</div>',
        unsafe_allow_html=True,
    )
    st.caption(
        'Leitura manual, não-contínua. O som para ao final de cada trecho '
        '(voz pt-BR do servidor).'
    )
    st.toggle('Leitura lenta', key='tts_lento')

    st.divider()

    with st.container(border=True, key='card_ajustes_pix'):
        st.markdown(
            '<div class="bd-rotulo">❤️ APOIAR O PROJETO VIA PIX</div>',
            unsafe_allow_html=True,
        )
        st.markdown(
            'Sua contribuição é voluntária e ajuda a manter este aplicativo '
            'gratuito. A doação será recebida em uma conta Nubank.'
        )
        st.markdown('**CHAVE PIX — E-MAIL**')
        st.code(CHAVE_PIX, language=None)
        clipboard.botao_copiar(CHAVE_PIX, label='📋 Copiar chave Pix', primario=True)
        with st.expander('❔ Como fazer a doação'):
            for i, passo in enumerate(
                [
                    'Abra o aplicativo do seu banco.',
                    'Toque em “Pix” e depois em “Transferir”.',
                    'Cole a chave, escolha o valor e confira os dados.',
                    'Confirme a doação somente se estiver tudo correto.',
                ],
                start=1,
            ):
                st.markdown(f'{i}. {passo}')
        st.caption('Antes de confirmar, confira no banco o nome de quem receberá.')

    st.divider()
    st.markdown('### Sobre o app')
    st.markdown('**Uso simples e legível**')
    st.caption(
        'Este app foi ajustado para facilitar leitura e toque para todas as idades.'
    )
    st.markdown('**Bíblia Diária • Offline • Gratuito**')

    storage.salvar()

