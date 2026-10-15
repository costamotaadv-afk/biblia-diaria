"""Aba Salvos: capítulos, versículos e recursos de estudo salvos."""

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
    """Resolve o nome do livro a partir da chave, varrendo o índice de trás para
    frente e casando o prefixo mais longo (B11/E14)."""
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
        st.markdown('### Capítulos salvos')
        for chave in capitulos:
            nome = _nome_livro_da_chave(indice, chave)
            livro = data_source.carregar_livro(nome) if nome else None
            texto = texto_de_capitulo_em_livros([livro], chave) if livro else None
            with st.container(border=True):
                st.markdown(f'**{chave}**')
                if texto is None:
                    st.markdown('Conteúdo não encontrado.')
                c1, c2 = st.columns([1, 1])
                if c1.button('🔊 Ouvir capítulo', key=f'ouvir_cap_{chave}', disabled=not texto, use_container_width=True):
                    tts.falar_capitulo(chave, texto, lento)
                if c2.button('🗑️ Remover capítulo salvo', key=f'rem_cap_{chave}', use_container_width=True):
                    alternar_lista('favoritos_capitulos', chave)
                    st.rerun()

    if versiculos:
        st.markdown('### Versículos salvos')
        for chave in versiculos:
            nome = _nome_livro_da_chave(indice, chave)
            livro = data_source.carregar_livro(nome) if nome else None
            texto = texto_de_versiculo_em_livros([livro], chave) if livro else None
            with st.container(border=True):
                st.markdown(f'**{chave}**')
                st.markdown(texto if texto else 'Conteúdo não encontrado.')
                c1, c2 = st.columns([1, 1])
                if c1.button('🔊 Ouvir versículo', key=f'ouvir_vers_{chave}', disabled=not texto, use_container_width=True):
                    tts.falar_versiculo(chave, texto, lento)
                if c2.button('🗑️ Remover versículo salvo', key=f'rem_vers_{chave}', use_container_width=True):
                    alternar_lista('favoritos_versiculos', chave)
                    st.rerun()

    if estudos:
        st.markdown('### Recursos de estudo salvos')
        indice_estudos = data_source.carregar_estudos_indice()
        for id_ in estudos:
            resumo = next((r for r in indice_estudos if r.id == id_), None)
            with st.container(border=True):
                if resumo is None:
                    st.markdown(f'**{id_}**')
                    st.markdown('Conteúdo não encontrado.')
                    if st.button('🗑️ Remover recurso salvo', key=f'rem_est_{id_}'):
                        alternar_lista('favoritos_estudos', id_)
                        st.rerun()
                else:
                    titulo = resumo.titulo if resumo.titulo else rotulo_tipo(resumo.tipo)
                    subtitulo = (
                        resumo.referencia
                        if resumo.referencia
                        else rotulo_tipo(resumo.tipo)
                    )
                    st.markdown(f'**{titulo}**')
                    st.markdown(f'*{rotulo_tipo(resumo.tipo)} • {subtitulo}*')
                    c1, c2 = st.columns([1, 1])
                    if c1.button('🔊 Ouvir', key=f'ouvir_est_{id_}', use_container_width=True):
                        recurso = painel_estudos.recurso_completo(resumo)
                        tts.falar_recurso(recurso, lento)
                    if c2.button('🗑️ Remover recurso salvo', key=f'rem_est_{id_}', use_container_width=True):
                        alternar_lista('favoritos_estudos', id_)
                        st.rerun()
