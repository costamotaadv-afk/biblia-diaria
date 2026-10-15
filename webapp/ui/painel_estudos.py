"""Painel reutilizável de recursos de estudo (detalhe + lista agrupada).

Sem regra de negócio: recebe recursos já prontos e callbacks, espelhando
``lib/widgets/painel_estudos.dart``.
"""

import streamlit as st

from core import data_source
from core.catalogo_estudos import agrupar_por_tipo, rotulo_tipo
from . import tts


def recurso_completo(resumo):
    """Resolve o corpo completo de um recurso pelo detalhe por livro (cached)."""
    lista = data_source.carregar_estudos_livro(resumo.livro)
    for item in lista:
        if item.id == resumo.id:
            return item
    return resumo


def render_recurso(recurso, favoritos, on_alternar, tts_lento=False):
    """Cartão de um único recurso (título, corpo, período, fatos, fonte, ações)."""
    salvo = recurso.id in favoritos
    titulo = recurso.titulo if recurso.titulo else rotulo_tipo(recurso.tipo)
    credito = recurso.fonte.credito if recurso.tem_fonte else ''

    with st.container(border=True):
        st.markdown(f'**{titulo}**')
        if recurso.referencia:
            st.markdown(f'*{rotulo_tipo(recurso.tipo)} • {recurso.referencia}*')
        if recurso.tem_periodo:
            st.markdown(f'🕰️ {recurso.periodo}')
        st.markdown(recurso.corpo if recurso.tem_corpo else 'Conteúdo não disponível.')
        if recurso.tem_fatos:
            st.markdown('**Fatos que iluminam o texto**')
            for fato in recurso.fatos:
                st.markdown(f'• {fato}')
        if credito:
            st.caption(f'Fonte: {credito}')

        c1, c2 = st.columns([1, 1])
        if c1.button(
            '🔊 Ouvir',
            key=f'ouvir_{recurso.id}',
            disabled=not recurso.tem_corpo,
            use_container_width=True,
        ):
            tts.falar_recurso(recurso, tts_lento)
        if c2.button(
            '🔖 Salvo' if salvo else '🔖 Salvar',
            key=f'salvar_{recurso.id}',
            use_container_width=True,
        ):
            on_alternar(recurso.id)


def render(recursos, favoritos, on_alternar, tts_lento=False):
    """Lista agrupada por tipo, em ordem determinística."""
    if not recursos:
        st.info('Sem recursos de estudo para este trecho.')
        return

    grupos = agrupar_por_tipo(recursos)
    for tipo, lista in grupos.items():
        st.markdown(f'### {rotulo_tipo(tipo)}')
        for recurso in lista:
            render_recurso(recurso, favoritos, on_alternar, tts_lento)
