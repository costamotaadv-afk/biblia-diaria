"""Aba Início: data, versículo do dia, mensagem e atalhos."""

import datetime

import streamlit as st

from core import data_source
from core.dados_seguros import dias_desde_epoca, selecionar_versiculo_do_dia
from core.formato_data import formatar_data_extenso
from core.storage import alternar_lista
from . import tts


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

    st.markdown(f'*{formatar_data_extenso(hoje)}*')

    with st.container(border=True):
        st.markdown('### 📖 Versículo do Dia')
        st.markdown(f'*"{versiculo}"*')
        st.markdown(f'**{referencia}**')
        c1, c2 = st.columns([1, 1])
        if c1.button(
            '🔊 Ouvir versículo',
            disabled=not referencia,
            use_container_width=True,
        ):
            tts.falar_versiculo(referencia, versiculo, lento)
        if c2.button(
            '❤️ Salvo' if is_fav else '❤️ Salvar versículo',
            disabled=not referencia,
            use_container_width=True,
        ):
            alternar_lista('favoritos_versiculos', referencia)
            st.rerun()

    with st.container(border=True):
        st.markdown('### 💌 Mensagem para você')
        st.markdown(mensagem)

    c3, c4 = st.columns([1, 1])
    if c3.button('📖 Ler a Bíblia', use_container_width=True):
        st.session_state['aba'] = 'Bíblia'
        st.rerun()
    if c4.button('🔖 Salvos', use_container_width=True):
        st.session_state['aba'] = 'Salvos'
        st.rerun()
