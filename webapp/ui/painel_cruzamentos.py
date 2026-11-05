"""Painel de cruzamentos históricos de um versículo (Theographic).

Sem regra de negócio; apenas exibe o resultado de
``core.cruzamentos.cruzamentos_do_versiculo``.
"""

import streamlit as st

from core import metadados_biblia as md


def render(cruzamentos):
    """Exibe pessoas/lugares/eventos/grupos; mensagem amigável se vazio."""
    if not cruzamentos:
        st.info('Sem cruzamentos históricos para este versículo.')
        return

    st.markdown(f'### 🔎 Cruzamentos — {cruzamentos["referencia"]}')

    if cruzamentos['pessoas']:
        st.markdown('**Pessoas**')
        for p in cruzamentos['pessoas']:
            st.markdown(f'• {p["name"]}')

    if cruzamentos['lugares']:
        st.markdown('**Lugares**')
        for l in cruzamentos['lugares']:
            st.markdown(f'• {l["name"]}')

    if cruzamentos['eventos']:
        st.markdown('**Eventos**')
        for e in cruzamentos['eventos']:
            ano = md.rotulo_ano(e.get('start_date'))
            st.markdown(f'• {e["title"]}' + (f' — {ano}' if ano else ''))

    if cruzamentos['grupos']:
        st.markdown('**Grupos**')
        for g in cruzamentos['grupos']:
            st.markdown(f'• {g["group_name"]}')

    st.caption('Fonte: Theographic Bible Metadata (CC BY-SA 4.0).')
