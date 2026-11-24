"""Bíblia Diária — app Streamlit (porte do app Flutter).

Executar: ``streamlit run webapp/streamlit_app.py``
"""

import sys
from pathlib import Path

# O Streamlit insere no ``sys.path`` o caminho do *script* (``webapp/streamlit_app.py``),
# não o diretório ``webapp/``. Sem isto, ``from core import ...`` / ``from ui import ...``
# falham com ``ModuleNotFoundError`` quando o app é iniciado por ``streamlit run`` a
# partir da raiz do repositório. Garantimos o diretório do script no ``sys.path``.
_APP_DIR = Path(__file__).resolve().parent
if str(_APP_DIR) not in sys.path:
    sys.path.insert(0, str(_APP_DIR))

import streamlit as st

from core import storage
from ui import aba_ajustes, aba_biblia, aba_estudos, aba_inicio, aba_salvos, tema

st.set_page_config(
    page_title='Bíblia Diária',
    page_icon='📖',
    layout='wide',
    initial_sidebar_state='collapsed',
)

storage.inicializar()

_ABAS = ['Início', 'Bíblia', 'Estudos', 'Salvos', 'Ajustes']


def _injetar_tema() -> None:
    """Tema (claro/escuro/sépia), escala e espaçamento via CSS injetado."""
    modo = st.session_state.get('tema', 'claro')
    escala = st.session_state.get('escala_pct', 118) / 100.0
    altura_linha = st.session_state.get('altura_linha', 1.65)
    st.markdown(tema.css(modo, escala, altura_linha), unsafe_allow_html=True)


_injetar_tema()
st.markdown('<div class="app-title">Bíblia Diária</div>', unsafe_allow_html=True)

# Navegação horizontal ligada ao estado (substitui a NavigationBar; permite
# navegação programática — ex.: referência cruzada → aba Bíblia).
st.radio('Navegação', _ABAS, key='aba', horizontal=True, label_visibility='collapsed')

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
