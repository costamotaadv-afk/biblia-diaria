"""Aba Bíblia: livro → capítulo → versículos, com ações por versículo e capítulo."""

import streamlit as st

from core import dados_seguros as ds
from core import config
from core import data_source
from core.catalogo_estudos import recursos_aplicaveis
from core.contexto_historico import contexto_do_salmo
from core.dados_seguros import texto_de_capitulo_em_livros
from core.storage import alternar_lista
from . import painel_contexto, painel_estudos, tts


def render():
    indice = data_source.carregar_indice()
    nomes = [f"{i.get('nome')}" for i in indice]
    if not nomes:
        st.info('Nenhum livro disponível.')
        return

    nome = st.selectbox('Livro', nomes, key='biblia_livro')
    livro = data_source.carregar_livro(nome)
    if livro is None:
        st.info('Não foi possível carregar este livro.')
        return

    capitulos = [
        c for c in (ds.como_lista(livro.get('capitulos')) or [])
        if isinstance(c, dict)
    ]
    if not capitulos:
        st.info('Sem conteúdo bíblico disponível.')
        return

    numeros_cap = [c.get('numero') for c in capitulos]
    idx_cap = st.selectbox(
        'Capítulo',
        range(len(capitulos)),
        format_func=lambda i: f'Capítulo {numeros_cap[i]}',
        key='biblia_capitulo_idx',
    )
    capitulo = capitulos[idx_cap]
    numero_cap = capitulo.get('numero')
    versiculos = [
        v for v in (ds.como_lista(capitulo.get('versiculos')) or [])
        if isinstance(v, dict)
    ]
    chave_capitulo = f'{nome} {numero_cap}'

    if versiculos:
        linhas = [f'**{v.get("numero")}.** {v.get("texto")}' for v in versiculos]
        st.markdown('  \n'.join(linhas))
    else:
        st.info('Sem conteúdo bíblico disponível.')

    st.divider()

    lento = st.session_state['tts_lento']

    # Ações de versículo (selectbox + Ouvir/Salvar/Compartilhar).
    c_v, c_o, c_s, c_sh = st.columns([1.8, 1, 1, 1.3])
    with c_v:
        if versiculos:
            idx_vers = st.selectbox(
                'Versículo',
                range(len(versiculos)),
                format_func=lambda i: f'{versiculos[i].get("numero")}',
                key='biblia_versiculo_idx',
                label_visibility='collapsed',
            )
            vers = versiculos[idx_vers]
            chave_versiculo = f'{nome} {numero_cap}:{vers.get("numero")}'
        else:
            vers = None
            chave_versiculo = ''
    with c_o:
        if st.button('🔊 Ouvir versículo', key='ouvir_vers', disabled=not versiculos, use_container_width=True):
            tts.falar_versiculo(chave_versiculo, vers.get('texto') or '', lento)
    with c_s:
        fav_v = chave_versiculo in st.session_state['favoritos_versiculos']
        if st.button('❤️ Salvo' if fav_v else '❤️ Salvar', key='salvar_vers', disabled=not versiculos, use_container_width=True):
            alternar_lista('favoritos_versiculos', chave_versiculo)
            st.rerun()
    with c_sh:
        if versiculos:
            st.link_button(
                '📤 Compartilhar',
                config.url_whatsapp(
                    config.mensagem_versiculo(
                        chave_versiculo, vers.get('texto') or ''
                    )
                ),
                type='secondary',
                width='stretch',
            )

    # Compartilhar capítulo inteiro (oculto se sem versículos).
    if versiculos:
        referencia_capitulo = (
            f'Salmo {numero_cap}' if nome == 'Salmos' else chave_capitulo
        )
        texto_capitulo = '\n'.join(
            f'{v.get("numero")}. {v.get("texto")}' for v in versiculos
        )
        st.link_button(
            '📤 Compartilhar capítulo',
            config.url_whatsapp(
                config.mensagem_capitulo(referencia_capitulo, texto_capitulo)
            ),
            type='secondary',
            width='stretch',
        )

    # Ações de capítulo.
    c1, c2, c3, c4 = st.columns(4)
    with c1:
        if st.button('🔊 Ouvir capítulo', key='ouvir_cap', use_container_width=True):
            texto_falado = texto_de_capitulo_em_livros([livro], chave_capitulo)
            if texto_falado:
                tts.falar_capitulo(chave_capitulo, texto_falado, lento)
    with c2:
        fav_c = chave_capitulo in st.session_state['favoritos_capitulos']
        if st.button('🔖 Salvo' if fav_c else '🔖 Salvar capítulo', key='salvar_cap', use_container_width=True):
            alternar_lista('favoritos_capitulos', chave_capitulo)
            st.rerun()
    with c3:
        if st.button('📚 Estudos', key='estudos_cap', use_container_width=True):
            st.session_state['biblia_painel'] = ('estudos', chave_capitulo)
    with c4:
        if nome == 'Salmos':
            if st.button('🏛️ Contexto histórico', key='contexto_cap', use_container_width=True):
                st.session_state['biblia_painel'] = ('contexto', chave_capitulo)

    # Painel (Estudos ou Contexto) do capítulo atual.
    painel = st.session_state.get('biblia_painel')
    if painel and painel[1] == chave_capitulo:
        st.divider()
        if painel[0] == 'estudos':
            indice_estudos = data_source.carregar_estudos_indice()
            do_livro = [r for r in indice_estudos if r.livro == nome]
            aplicaveis = recursos_aplicaveis(do_livro, chave_capitulo, livro=nome)
            completos = [painel_estudos.recurso_completo(r) for r in aplicaveis]
            painel_estudos.render(
                completos,
                st.session_state['favoritos_estudos'],
                lambda id_: alternar_lista('favoritos_estudos', id_),
                tts_lento=lento,
            )
        else:
            numero = None
            if chave_capitulo.startswith('Salmos '):
                try:
                    numero = int(chave_capitulo.split(' ', 1)[1])
                except ValueError:
                    numero = None
            contextos = data_source.carregar_contexto_livro('Salmos')
            contexto = contexto_do_salmo(contextos, numero) if numero else None
            if contexto:
                painel_contexto.render_detalhe(contexto, tts_lento=lento)
            else:
                st.info('Contexto histórico indisponível para este Salmo.')
