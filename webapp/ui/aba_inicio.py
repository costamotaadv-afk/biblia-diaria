"""Aba Início: data, versículo do dia, mensagem, progresso e atalhos."""

import datetime
import html

import streamlit as st

from core import config
from core import data_source
from core import progresso_leitura
from core.dados_seguros import dias_desde_epoca, selecionar_versiculo_do_dia
from core.formato_data import formatar_data_extenso
from core.storage import alternar_lista
from . import tts


def _ir_para_aba(aba: str) -> None:
    """Callback de navegação: troca a aba sem violar o estado do widget ``aba``."""
    st.session_state['aba'] = aba


def render():
    indice = data_source.carregar_indice()
    mensagens = data_source.carregar_mensagens()

    hoje = datetime.date.today()
    dia = dias_desde_epoca(hoje)

    nome_livro = f"{indice[dia % len(indice)].get('nome')}" if indice else None
    livro = data_source.carregar_livro(nome_livro) if nome_livro else None
    conteudo = selecionar_versiculo_do_dia(dia=dia, mensagens=mensagens, livro=livro)

    referencia = conteudo['referencia']
    versiculo = conteudo['versiculo']
    mensagem = conteudo['mensagem']
    is_fav = referencia in st.session_state['favoritos_versiculos']
    lento = st.session_state['tts_lento']

    st.markdown(
        f'<div class="bd-data">{html.escape(formatar_data_extenso(hoje))}</div>',
        unsafe_allow_html=True,
    )

    # Cartão do Versículo do Dia (gradiente + aspas + 3 ações).
    with st.container(border=True, key='card_inicio_versiculo'):
        st.markdown(
            '<div class="bd-rotulo">📖 VERSÍCULO DO DIA</div>',
            unsafe_allow_html=True,
        )
        st.markdown(
            f'<div class="bd-quote">“{html.escape(versiculo)}”</div>',
            unsafe_allow_html=True,
        )
        st.markdown(
            f'<div class="bd-ref">{html.escape(referencia)}</div>',
            unsafe_allow_html=True,
        )
        st.divider()
        c1, c2, c3 = st.columns(3)
        with c1:
            if st.button(
                '🔊 Ouvir',
                key='ouvir_dia',
                disabled=not referencia,
                width='stretch',
            ):
                tts.falar_versiculo(referencia, versiculo, lento)
        with c2:
            if st.button(
                '⭐ Salvo' if is_fav else '⭐ Favoritar',
                key='fav_dia',
                disabled=not referencia,
                width='stretch',
            ):
                alternar_lista('favoritos_versiculos', referencia)
                st.rerun()
        with c3:
            if referencia:
                st.link_button(
                    '📤 Compartilhar',
                    config.url_whatsapp(config.mensagem_versiculo(referencia, versiculo)),
                    type='secondary',
                    width='stretch',
                )

    # Cartão "Mensagem para você" centralizado.
    with st.container(border=True, key='card_inicio_mensagem'):
        st.markdown(
            '<div style="text-align:center; font-weight:700;">'
            '❤️ Mensagem para você</div>',
            unsafe_allow_html=True,
        )
        st.markdown(
            f'<div style="text-align:center; font-size:1.06rem; '
            f'line-height:1.45;">{html.escape(mensagem)}</div>',
            unsafe_allow_html=True,
        )

    # Cartão de progresso de leitura.
    lidos_set = set(st.session_state['capitulos_lidos'])
    total = progresso_leitura.total_de_capitulos(indice)
    lidos = progresso_leitura.contar_capitulos_lidos(indice, lidos_set)
    fracao = progresso_leitura.fracao_lida(indice, lidos_set)
    percentual = round(fracao * 100)
    with st.container(border=True, key='card_inicio_progresso'):
        st.markdown(
            f'<div class="bd-section">📈 Progresso de leitura '
            f'<span style="float:right; color:var(--bd-primary);">{percentual}%</span></div>',
            unsafe_allow_html=True,
        )
        st.progress(fracao)
        st.caption(f'{lidos} de {total} capítulos lidos')

    # Ações principais (preenchida + contornada).
    c3, c4 = st.columns([1, 1])
    c3.button(
        '📖 Ler a Bíblia',
        type='primary',
        width='stretch',
        on_click=_ir_para_aba,
        args=('Bíblia',),
    )
    c4.button(
        '🔖 Salvos',
        type='secondary',
        width='stretch',
        on_click=_ir_para_aba,
        args=('Salvos',),
    )

    if config.link_valido(config.LINK_DOWNLOAD):
        st.link_button(
            '📲 Compartilhar no WhatsApp',
            config.url_whatsapp(config.mensagem_compartilhamento()),
            type='primary',
            width='stretch',
        )

