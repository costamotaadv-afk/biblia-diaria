"""Aba Estudos: biblioteca de recursos + tela de contexto histórico dos Salmos."""

import streamlit as st

from core import data_source
from core.catalogo_estudos import (
    filtrar_por_busca,
    filtrar_recursos,
    livros_disponiveis,
    rotulo_tipo,
    tipos_disponiveis,
)
from core.storage import alternar_lista
from . import painel_contexto, painel_estudos


def render():
    if st.button('🏛️ Contexto histórico dos Salmos', key='estudos_ctx_btn'):
        st.session_state['estudos_ver_contexto'] = not st.session_state.get(
            'estudos_ver_contexto', False
        )

    if st.session_state.get('estudos_ver_contexto'):
        contextos = data_source.carregar_contexto_livro('Salmos')
        if not contextos:
            st.info('Contexto histórico indisponível no momento.')
        else:
            painel_contexto.render_tela(
                contextos, tts_lento=st.session_state['tts_lento']
            )
        return

    indice = data_source.carregar_estudos_indice()
    if not indice:
        st.info('Nenhum recurso de estudo disponível ainda.')
        return

    busca = st.text_input('🔍 Buscar nos estudos', key='estudos_busca')
    tipos = tipos_disponiveis(indice)
    livros = livros_disponiveis(indice)

    col1, col2 = st.columns([1, 1])
    with col1:
        tipo = st.selectbox('Tipo', ['Todos os tipos'] + tipos, key='estudos_tipo')
    with col2:
        livro = st.selectbox(
            'Filtrar por livro', ['Todos os livros'] + livros, key='estudos_livro'
        )

    filtrados = filtrar_por_busca(
        filtrar_recursos(
            indice,
            tipo=None if tipo == 'Todos os tipos' else tipo,
            livro=None if livro == 'Todos os livros' else livro,
        ),
        busca,
    )

    if not filtrados:
        st.info('Nenhum recurso encontrado com esse filtro.')
        return

    st.markdown(f'**{len(filtrados)} recurso(s)**')
    for resumo in filtrados:
        recurso = painel_estudos.recurso_completo(resumo)
        titulo = recurso.titulo if recurso.titulo else rotulo_tipo(recurso.tipo)
        with st.expander(f'{rotulo_tipo(recurso.tipo)} • {titulo}'):
            painel_estudos.render_recurso(
                recurso,
                st.session_state['favoritos_estudos'],
                lambda id_: alternar_lista('favoritos_estudos', id_),
                tts_lento=st.session_state['tts_lento'],
            )
