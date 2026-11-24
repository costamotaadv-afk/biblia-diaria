"""Aba Salvos: capítulos, versículos e recursos de estudo salvos."""

import html

import streamlit as st

from core import data_source
from core.catalogo_estudos import rotulo_tipo
from core.dados_seguros import (
    texto_de_capitulo_em_livros,
    texto_de_versiculo_em_livros,
)
from core.storage import alternar_lista
from . import painel_estudos, tts


def _nome_livro_da_chave(indice, chave):
    """Resolve o nome do livro a partir da chave (prefixo mais longo)."""
    for item in reversed(indice):
        nome = f"{item.get('nome')}"
        if chave.startswith(nome + ' '):
            return nome
    return None


def render():
    indice = data_source.carregar_indice()
    versiculos = sorted(st.session_state['favoritos_versiculos'])
    capitulos = sorted(st.session_state['favoritos_capitulos'])
    estudos = sorted(st.session_state['favoritos_estudos'])

    if not (versiculos or capitulos or estudos):
        st.info('Nenhum versículo, capítulo ou estudo salvo ainda.')
        return

    lento = st.session_state['tts_lento']

    if capitulos:
        st.markdown(
            '<div class="bd-section">Capítulos salvos</div>',
            unsafe_allow_html=True,
        )
        for chave in capitulos:
            nome = _nome_livro_da_chave(indice, chave)
            livro = data_source.carregar_livro(nome) if nome else None
            texto = texto_de_capitulo_em_livros([livro], chave) if livro else None
            with st.container(border=True, key=f'card_salvo_cap_{chave}'):
                st.markdown(f'**{html.escape(chave)}**')
                if texto is None:
                    st.markdown('Conteúdo não encontrado.')
                c1, c2 = st.columns(2)
                with c1:
                    if st.button(
                        '🔊 Ouvir',
                        key=f'ouvir_cap_{chave}',
                        disabled=not texto,
                        width='stretch',
                    ):
                        tts.falar_capitulo(chave, texto, lento)
                with c2:
                    if st.button('🗑️ Remover', key=f'rem_cap_{chave}', width='stretch'):
                        alternar_lista('favoritos_capitulos', chave)
                        st.rerun()

    if versiculos:
        st.markdown(
            '<div class="bd-section">Versículos salvos</div>',
            unsafe_allow_html=True,
        )
        for chave in versiculos:
            nome = _nome_livro_da_chave(indice, chave)
            livro = data_source.carregar_livro(nome) if nome else None
            texto = texto_de_versiculo_em_livros([livro], chave) if livro else None
            with st.container(border=True, key=f'card_salvo_vers_{chave}'):
                st.markdown(f'**{html.escape(chave)}**')
                if texto:
                    st.markdown(
                        f'<div class="bd-verse">{html.escape(texto)}</div>',
                        unsafe_allow_html=True,
                    )
                else:
                    st.markdown('Conteúdo não encontrado.')
                c1, c2 = st.columns(2)
                with c1:
                    if st.button(
                        '🔊 Ouvir',
                        key=f'ouvir_vers_{chave}',
                        disabled=not texto,
                        width='stretch',
                    ):
                        tts.falar_versiculo(chave, texto, lento)
                with c2:
                    if st.button('🗑️ Remover', key=f'rem_vers_{chave}', width='stretch'):
                        alternar_lista('favoritos_versiculos', chave)
                        st.rerun()

    if estudos:
        st.markdown(
            '<div class="bd-section">Recursos de estudo salvos</div>',
            unsafe_allow_html=True,
        )
        indice_estudos = data_source.carregar_estudos_indice()
        for id_ in estudos:
            resumo = next((r for r in indice_estudos if r.id == id_), None)
            with st.container(border=True, key=f'card_salvo_est_{id_}'):
                if resumo is None:
                    st.markdown(f'**{html.escape(id_)}**')
                    st.markdown('Conteúdo não encontrado.')
                    if st.button('🗑️ Remover', key=f'rem_est_{id_}', width='stretch'):
                        alternar_lista('favoritos_estudos', id_)
                        st.rerun()
                else:
                    titulo = resumo.titulo if resumo.titulo else rotulo_tipo(resumo.tipo)
                    subtitulo = (
                        resumo.referencia
                        if resumo.referencia
                        else rotulo_tipo(resumo.tipo)
                    )
                    st.markdown(f'**{html.escape(titulo)}**')
                    st.markdown(
                        f'<span class="bd-sub">{html.escape(rotulo_tipo(resumo.tipo))}'
                        f' • {html.escape(subtitulo)}</span>',
                        unsafe_allow_html=True,
                    )
                    c1, c2 = st.columns(2)
                    with c1:
                        if st.button('🔊 Ouvir', key=f'ouvir_est_{id_}', width='stretch'):
                            recurso = painel_estudos.recurso_completo(resumo)
                            tts.falar_recurso(recurso, lento)
                    with c2:
                        if st.button('🗑️ Remover', key=f'rem_est_{id_}', width='stretch'):
                            alternar_lista('favoritos_estudos', id_)
                            st.rerun()
                    with st.expander('📖 Abrir recurso'):
                        recurso = painel_estudos.recurso_completo(resumo)
                        painel_estudos.render_recurso(
                            recurso,
                            st.session_state['favoritos_estudos'],
                            lambda i: alternar_lista('favoritos_estudos', i),
                            tts_lento=lento,
                        )

