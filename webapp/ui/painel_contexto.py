"""Painel e tela de contextualização histórica dos Salmos.

Sem regra de negócio; espelha ``lib/widgets/painel_contexto_historico.dart`` e
``lib/widgets/tela_contexto_historico.dart``.
"""

import streamlit as st

from core import dados_seguros as ds
from core import data_source
from core.contexto_historico import (
    analisar_referencia,
    explicacao_certeza,
    filtrar_contexto_por_busca,
    rotulo_certeza,
)
from . import tts


def ir_para_referencia(referencia: str) -> None:
    """Navega para uma referência cruzada: volta à aba Bíblia e seleciona o capítulo."""
    indice = data_source.carregar_indice()
    nomes = [f"{i.get('nome')}" for i in indice]
    alvo = analisar_referencia(referencia, nomes)
    if alvo is None or alvo.capitulo is None:
        st.warning('Referência não disponível no aplicativo.')
        return

    livro = data_source.carregar_livro(alvo.livro)
    idx = 0
    if livro:
        capitulos = [
            c for c in (ds.como_lista(livro.get('capitulos')) or [])
            if isinstance(c, dict)
        ]
        for i, cap in enumerate(capitulos):
            if str(cap.get('numero')) == str(alvo.capitulo):
                idx = i
                break

    st.session_state['aba'] = 'Bíblia'
    st.session_state['biblia_livro'] = alvo.livro
    st.session_state['biblia_capitulo_idx'] = idx
    st.rerun()


def render_detalhe(contexto, tts_lento=False):
    """Contextualização completa de um Salmo."""
    st.markdown(f'### Salmo {contexto.numero}')
    if contexto.tem_titulo:
        st.markdown(f'**{contexto.titulo}**')
    if contexto.tem_classificacao:
        st.markdown(' • '.join(contexto.classificacao))

    st.markdown(f'*{rotulo_certeza(contexto.certeza)}*')

    if contexto.tem_autoria:
        st.markdown('**Autoria**')
        linhas = [contexto.autoria]
        if contexto.tem_origem_autoria:
            linhas.append(f'Origem da atribuição: {contexto.origem_autoria}')
        if contexto.autoria_incerta:
            linhas.append('A autoria é incerta.')
        st.markdown('  \n'.join(linhas))

    if contexto.tem_periodo or contexto.tem_periodo_retratado or contexto.tem_periodo_composicao:
        st.markdown('**Período histórico**')
        if contexto.tem_periodo:
            st.markdown(f'Período: {contexto.periodo}')
        if contexto.tem_periodo_retratado:
            st.markdown(f'Período retratado: {contexto.periodo_retratado}')
        if contexto.tem_periodo_composicao:
            st.markdown(f'Provável época de composição: {contexto.periodo_composicao}')

    if contexto.tem_contexto_politico:
        st.markdown('**Contexto político e social**')
        st.markdown(contexto.contexto_politico)

    if contexto.tem_eventos:
        st.markdown('**Acontecimentos históricos relacionados**')
        for evento in contexto.eventos:
            st.markdown(f'• {evento}')

    if contexto.tem_localizacao:
        st.markdown('**Localização geográfica**')
        st.markdown(contexto.localizacao)

    if contexto.tem_referencias:
        st.markdown('**Referências bíblicas cruzadas**')
        for ref in contexto.referencias_cruzadas:
            label = ref.referencia + (f' — {ref.nota}' if ref.tem_nota else '')
            if st.button(label, key=f'ctx_ref_{contexto.id}_{ref.referencia}'):
                ir_para_referencia(ref.referencia)

    if contexto.tem_explicacao:
        st.markdown('**Explicação histórica**')
        st.markdown(contexto.explicacao)

    st.caption(explicacao_certeza(contexto.certeza))

    if contexto.tem_fontes:
        st.markdown('**Fontes**')
        for fonte in contexto.fontes:
            st.caption(fonte.credito or 'Fonte não identificada.')

    if contexto.tem_explicacao and st.button(
        '🔊 Ouvir contexto', key=f'ouvir_ctx_{contexto.id}'
    ):
        tts.falar_contexto(contexto, tts_lento)


def render_tela(contextos, tts_lento=False):
    """Tela consultável/buscável dos 150 Salmos."""
    busca = st.text_input(
        '🔍 Buscar por personagem, evento, lugar ou período',
        key='contexto_busca',
    )
    filtrados = filtrar_contexto_por_busca(contextos, busca)
    if not filtrados:
        st.info('Nenhum Salmo encontrado com essa busca.')
        return

    labels = [
        (f'Salmo {c.numero} — {c.titulo}' if c.titulo else f'Salmo {c.numero}')
        for c in filtrados
    ]
    escolha = st.selectbox(
        'Salmo',
        range(len(filtrados)),
        format_func=lambda i: labels[i],
        key='contexto_selecionado_idx',
    )
    contexto = filtrados[escolha]

    subtitulo = ' • '.join(
        p for p in (
            contexto.autoria if contexto.tem_autoria else '',
            contexto.periodo if contexto.tem_periodo else '',
        ) if p
    )
    if subtitulo:
        st.markdown(f'*{subtitulo}*')

    render_detalhe(contexto, tts_lento)
