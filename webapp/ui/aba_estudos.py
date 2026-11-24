"""Aba Estudos: biblioteca de recursos + Explorar + contexto dos Salmos.

Navegação em 5 abas (como o Flutter): o acervo Explorar (exclusivo do Streamlit)
fica como uma seção dentro de Estudos, preservando todas as funções.
"""

import html

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
from . import aba_explorar, painel_contexto, painel_estudos


def render():
    if st.session_state.get('estudos_ver_contexto'):
        _render_contexto_tela()
        return

    if st.button(
        '🏛️ Contexto histórico dos Salmos',
        key='estudos_ctx_btn',
        type='secondary',
        width='stretch',
    ):
        st.session_state['estudos_ver_contexto'] = True
        st.rerun()

    secao = st.pills(
        'Seção',
        ['📚 Biblioteca', '🧭 Explorar'],
        key='estudos_secao',
        selection_mode='single',
        default='📚 Biblioteca',
        label_visibility='collapsed',
    )
    if secao == '🧭 Explorar':
        aba_explorar.render()
        return
    _render_biblioteca()


def _render_contexto_tela():
    if st.button('← Voltar', key='estudos_ctx_voltar'):
        st.session_state['estudos_ver_contexto'] = False
        st.rerun()
    contextos = data_source.carregar_contexto_livro('Salmos')
    if not contextos:
        st.info('Contexto histórico indisponível no momento.')
    else:
        painel_contexto.render_tela(
            contextos, tts_lento=st.session_state['tts_lento']
        )


def _render_biblioteca():
    indice = data_source.carregar_estudos_indice()
    if not indice:
        st.info('Nenhum recurso de estudo disponível ainda.')
        return

    busca = st.text_input('🔍 Buscar nos estudos', key='estudos_busca')
    tipos = tipos_disponiveis(indice)
    livros = livros_disponiveis(indice)

    tipo = st.pills(
        'Tipo',
        ['Todos os tipos'] + tipos,
        key='estudos_tipo',
        selection_mode='single',
        default='Todos os tipos',
        label_visibility='collapsed',
    )
    livro = st.selectbox(
        'Filtrar por livro',
        ['Todos os livros'] + livros,
        key='estudos_livro',
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
    for i, resumo in enumerate(filtrados):
        recurso = painel_estudos.recurso_completo(resumo)
        titulo = recurso.titulo if recurso.titulo else rotulo_tipo(recurso.tipo)
        subtitulo = (
            recurso.referencia if recurso.referencia else rotulo_tipo(recurso.tipo)
        )
        with st.container(border=True, key=f'card_estudo_{i}'):
            c1, c2 = st.columns([6, 1])
            with c1:
                st.markdown(f'**{html.escape(titulo)}**')
                st.markdown(
                    f'<span class="bd-sub">{html.escape(rotulo_tipo(recurso.tipo))}'
                    f' • {html.escape(subtitulo)}</span>',
                    unsafe_allow_html=True,
                )
            with c2:
                salvo = recurso.id in st.session_state['favoritos_estudos']
                if st.button(
                    '✅' if salvo else '🔖',
                    key=f'fav_estudo_{i}',
                    help='Salvo' if salvo else 'Salvar',
                    width='stretch',
                ):
                    alternar_lista('favoritos_estudos', recurso.id)
                    st.rerun()
            with st.expander('Ler recurso'):
                painel_estudos.render_recurso(
                    recurso,
                    st.session_state['favoritos_estudos'],
                    lambda id_: alternar_lista('favoritos_estudos', id_),
                    tts_lento=st.session_state['tts_lento'],
                )

