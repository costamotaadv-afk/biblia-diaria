"""Bíblia Diária — app Streamlit (porte do app Flutter).

Executar: ``streamlit run webapp/streamlit_app.py``
"""

import streamlit as st

from core import storage
from ui import aba_ajustes, aba_biblia, aba_estudos, aba_inicio, aba_salvos

st.set_page_config(
    page_title='Bíblia Diária',
    page_icon='📖',
    layout='wide',
    initial_sidebar_state='collapsed',
)

storage.inicializar()

_ABAS = ['Início', 'Bíblia', 'Estudos', 'Salvos', 'Ajustes']


def _injetar_css() -> None:
    """Tema (claro/escuro) e escala de fonte via CSS injetado."""
    fonte_grande = st.session_state.get('fonte_grande', True)
    tema_escuro = st.session_state.get('tema_escuro', False)
    base = '18.9px' if fonte_grande else '16px'  # textScaler 1.18 do Flutter

    css = f'<style>html, :root {{ font-size: {base}; }} '
    if tema_escuro:
        css += (
            '[data-testid="stAppViewContainer"], '
            '[data-testid="stAppViewBlockContainer"] '
            '{ background-color: #0e1117; } '
            '[data-testid="stHeader"] { background: rgba(14,17,23,0.9); } '
            '[data-testid="stMarkdownContainer"] { color: #fafafa; } '
            'h1, h2, h3, h4 { color: #fafafa !important; } '
            'label, p, li { color: #fafafa; } '
        )
    css += '</style>'
    st.markdown(css, unsafe_allow_html=True)


st.markdown('# 📖 Bíblia Diária')
_injetar_css()

# Navegação horizontal ligada ao estado (substitui a NavigationBar; permite
# navegação programática — ex.: referência cruzada → aba Bíblia).
st.radio('', _ABAS, key='aba', horizontal=True, label_visibility='collapsed')

aba = st.session_state['aba']
if aba == 'Início':
    aba_inicio.render()
elif aba == 'Bíblia':
    aba_biblia.render()
elif aba == 'Estudos':
    aba_estudos.render()
elif aba == 'Salvos':
    aba_salvos.render()
else:
    aba_ajustes.render()
