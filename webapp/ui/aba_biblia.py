"""Aba Bíblia: busca, livro → capítulo → versículos, ações por versículo/capítulo.

Espelha ``lib/main.dart`` (_montarTelaLeitura, _cabecalhoCapitulo,
_linhaVersiculo, _abrirAcoesVersiculo): o versículo é uma linha tocável que abre
o cartão de ações (ouvir, copiar, compartilhar, favoritar, anotar, estudos,
cruzamentos + 5 cores de destaque).
"""

import html

import streamlit as st

from core import busca_biblia as busca
from core import config
from core import cruzamentos
from core import dados_seguros as ds
from core import data_source
from core import destaques
from core import storage
from core.catalogo_estudos import recurso_aplicavel, recursos_aplicaveis
from core.contexto_historico import contexto_do_salmo
from core.dados_seguros import texto_de_capitulo_em_livros
from core.storage import alternar_lista
from . import clipboard, painel_contexto, painel_cruzamentos, painel_estudos, tts


def _indice_por_numero(itens, numero) -> int:
    for i, item in enumerate(itens):
        if str(item.get('numero')) == str(numero):
            return i
    return 0


def _tem_estudos(nome: str, referencia: str) -> bool:
    indice = data_source.carregar_estudos_indice()
    for recurso in indice:
        if recurso.livro == nome and recurso_aplicavel(recurso, referencia, livro=nome):
            return True
    return False


def _navegar_para(livro_nome: str, capitulo, versiculo) -> None:
    """Define livro/capítulo/versículo no estado (usado por busca e cruzamentos)."""
    nomes = [f"{i.get('nome')}" for i in data_source.carregar_indice()]
    if livro_nome not in nomes:
        return
    livro = data_source.carregar_livro(livro_nome)
    if not livro:
        return
    capitulos = [
        c for c in (ds.como_lista(livro.get('capitulos')) or []) if isinstance(c, dict)
    ]
    idx_cap = _indice_por_numero(capitulos, capitulo)
    versiculos = [
        v
        for v in (ds.como_lista(capitulos[idx_cap].get('versiculos')) or [])
        if isinstance(v, dict)
    ]
    st.session_state['biblia_livro'] = livro_nome
    st.session_state['biblia_capitulo_idx'] = idx_cap
    st.session_state['biblia_versiculo_idx'] = _indice_por_numero(versiculos, versiculo)


def _render_resultados(termo: str) -> None:
    with st.spinner('Buscando…'):
        resultados = busca.buscar_na_biblia(
            data_source.carregar_todos_os_livros(), termo, limite=100
        )
    if not resultados:
        st.info('Nenhum resultado encontrado.')
        return

    st.markdown(f'**{len(resultados)} resultado(s)**')
    with st.container(key='busca_resultados'):
        for i, r in enumerate(resultados[:50]):
            if st.button(
                f'**{r.referencia}** — {r.texto[:80]}',
                key=f'busca_{i}',
                width='stretch',
            ):
                st.session_state['biblia_busca'] = ''
                _navegar_para(r.livro, r.capitulo, r.versiculo)
                st.rerun()
    if len(resultados) > 50:
        st.caption(f'Mostrando 50 de {len(resultados)}.')

def render():
    termo = st.text_input(
        'Buscar na Bíblia',
        key='biblia_busca',
        label_visibility='collapsed',
        placeholder='🔍 Buscar na Bíblia…',
    )
    if (termo or '').strip():
        _render_resultados(termo.strip())
        return

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
        c for c in (ds.como_lista(livro.get('capitulos')) or []) if isinstance(c, dict)
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
        v
        for v in (ds.como_lista(capitulo.get('versiculos')) or [])
        if isinstance(v, dict)
    ]
    chave_capitulo = f'{nome} {numero_cap}'

    lento = st.session_state['tts_lento']

    # Cabeçalho do capítulo com ações.
    cap_fav = chave_capitulo in st.session_state['favoritos_capitulos']
    cap_lido = chave_capitulo in st.session_state['capitulos_lidos']
    with st.container(border=True, key='card_cabecalho_capitulo'):
        st.markdown(
            f'<div class="bd-section">Capítulo {numero_cap}</div>',
            unsafe_allow_html=True,
        )
        r1 = st.columns(3)
        with r1[0]:
            if _tem_estudos(nome, chave_capitulo) and st.button(
                '📚 Estudos', key='cap_estudos', width='stretch'
            ):
                st.session_state['biblia_painel'] = ('estudos', chave_capitulo)
        with r1[1]:
            if nome == 'Salmos' and st.button(
                '🏛️ Contexto', key='cap_contexto', width='stretch'
            ):
                st.session_state['biblia_painel'] = ('contexto', chave_capitulo)
        with r1[2]:
            if st.button('🔊 Ouvir', key='cap_ouvir', width='stretch'):
                texto_falado = texto_de_capitulo_em_livros([livro], chave_capitulo)
                if texto_falado:
                    tts.falar_capitulo(chave_capitulo, texto_falado, lento)
        r2 = st.columns(3)
        with r2[0]:
            if st.button('🔖 Salvo' if cap_fav else '🔖 Salvar', key='cap_salvar', width='stretch'):
                alternar_lista('favoritos_capitulos', chave_capitulo)
                st.rerun()
        with r2[1]:
            if st.button('✅ Lido' if cap_lido else '☑️ Marcar lido', key='cap_lido', width='stretch'):
                alternar_lista('capitulos_lidos', chave_capitulo)
                st.rerun()
        with r2[2]:
            if versiculos:
                referencia_capitulo = (
                    f'Salmo {numero_cap}' if nome == 'Salmos' else chave_capitulo
                )
                texto_capitulo = '\n'.join(
                    f'{v.get("numero")}. {v.get("texto")}' for v in versiculos
                )
                st.link_button(
                    '📤 Compartilhar',
                    config.url_whatsapp(
                        config.mensagem_capitulo(referencia_capitulo, texto_capitulo)
                    ),
                    type='secondary',
                    width='stretch',
                )

    # Versículos como linhas tocáveis.
    idx_vers = st.session_state.get('biblia_versiculo_idx', 0)
    if not (0 <= idx_vers < len(versiculos)):
        idx_vers = 0

    _injetar_estilos_versiculos(versiculos, nome, numero_cap, idx_vers)

    for i, v in enumerate(versiculos):
        n = v.get('numero')
        texto = str(v.get('texto'))
        chave_vers = f'{nome} {numero_cap}:{n}'
        marcacoes = ''
        if chave_vers in st.session_state['favoritos_versiculos']:
            marcacoes += ' ❤️'
        if chave_vers in st.session_state['notas_versiculos']:
            marcacoes += ' 📝'
        with st.container(key=f'verse_{i}'):
            if st.button(
                f'**{n}.** {texto}{marcacoes}',
                key=f'versebtn_{i}',
                width='stretch',
            ):
                st.session_state['biblia_versiculo_idx'] = i
                st.rerun()

    # Cartão de ações do versículo selecionado.
    _render_acoes_versiculo(nome, numero_cap, versiculos, idx_vers)

    # Painel (Estudos ou Contexto).
    painel = st.session_state.get('biblia_painel')
    if painel:
        st.divider()
        with st.container(border=True, key='card_biblia_painel'):
            if st.button('✖ Fechar', key='fechar_painel'):
                st.session_state['biblia_painel'] = None
                st.rerun()
            if painel[0] == 'estudos':
                _render_estudos(nome, painel[1])
            else:
                _render_contexto(painel[1])

    # Painel de cruzamentos do versículo selecionado.
    chave_vers = f'{nome} {numero_cap}:{versiculos[idx_vers].get("numero")}'
    ref_cruz = st.session_state.get('biblia_cruzamentos_ref')
    if ref_cruz and ref_cruz == chave_vers:
        st.divider()
        with st.container(border=True, key='card_biblia_cruzamentos'):
            if st.button('✖ Fechar', key='fechar_cruz'):
                st.session_state['biblia_cruzamentos_ref'] = None
                st.rerun()
            if not cruzamentos.metadados_disponiveis():
                st.info(
                    'Base de dados histórica indisponível neste ambiente. '
                    'Gere-a com `python tool/construir_metadados.py`.'
                )
            else:
                painel_cruzamentos.render(cruzamentos.cruzamentos_do_versiculo(ref_cruz))

def _injetar_estilos_versiculos(versiculos, nome, numero_cap, idx_vers) -> None:
    """CSS dinâmico: fundo dos destaques + anel no versículo selecionado."""
    destaques_map = st.session_state.get('destaques_versiculos', {})
    regras = []
    for i, v in enumerate(versiculos):
        chave = f'{nome} {numero_cap}:{v.get("numero")}'
        cor = destaques_map.get(chave)
        hex_cor = destaques.PALETA_DESTAQUES.get(cor) if cor else None
        if hex_cor:
            regras.append(
                f'.st-key-verse_{i} {{ background: {hex_cor} !important; }}'
            )
    regras.append(
        f'.st-key-verse_{idx_vers} {{ '
        f'box-shadow: inset 0 0 0 1.5px var(--bd-primary) !important; }}'
    )
    st.markdown(f'<style>{" ".join(regras)}</style>', unsafe_allow_html=True)


def _render_acoes_versiculo(nome, numero_cap, versiculos, idx_vers) -> None:
    vers = versiculos[idx_vers]
    n = vers.get('numero')
    texto = str(vers.get('texto'))
    chave_vers = f'{nome} {numero_cap}:{n}'
    is_fav = chave_vers in st.session_state['favoritos_versiculos']
    nota = st.session_state['notas_versiculos'].get(chave_vers, '')
    lento = st.session_state['tts_lento']

    with st.container(border=True, key='card_acao_versiculo'):
        st.markdown(
            f'<div class="bd-ref">{html.escape(chave_vers)}</div>',
            unsafe_allow_html=True,
        )
        st.markdown(
            f'<div class="bd-verse">“{html.escape(texto)}”</div>',
            unsafe_allow_html=True,
        )

        dest_atual = st.session_state['destaques_versiculos'].get(chave_vers)
        rotulos = {
            'amarelo': '🟡',
            'verde': '🟢',
            'azul': '🔵',
            'rosa': '🌸',
            'laranja': '🟠',
        }
        c = st.columns(5)
        for j, (cor, rotulo) in enumerate(rotulos.items()):
            with c[j]:
                if st.button(
                    ('✓ ' if dest_atual == cor else '') + rotulo,
                    key=f'dest_{j}',
                    help=f'Destaque {cor}',
                    width='stretch',
                ):
                    storage.alternar_destaque(chave_vers, cor)
                    st.rerun()

        a1 = st.columns(3)
        with a1[0]:
            if st.button('🔊 Ouvir', key='v_ouvir', width='stretch'):
                tts.falar_versiculo(chave_vers, texto, lento)
        with a1[1]:
            clipboard.botao_copiar(f'{chave_vers}\n{texto}', label='📋 Copiar')
        with a1[2]:
            st.link_button(
                '📤 Compartilhar',
                config.url_whatsapp(config.mensagem_versiculo(chave_vers, texto)),
                type='secondary',
                width='stretch',
            )

        a2 = st.columns(3)
        with a2[0]:
            if st.button('⭐ Salvo' if is_fav else '⭐ Favoritar', key='v_fav', width='stretch'):
                alternar_lista('favoritos_versiculos', chave_vers)
                st.rerun()
        with a2[1]:
            if _tem_estudos(nome, chave_vers):
                if st.button('📚 Estudos', key='v_estudos', width='stretch'):
                    st.session_state['biblia_painel'] = ('estudos', chave_vers)
        with a2[2]:
            if st.button('🔎 Cruzamentos', key='v_cruz', width='stretch'):
                ref_atual = st.session_state.get('biblia_cruzamentos_ref')
                st.session_state['biblia_cruzamentos_ref'] = (
                    None if ref_atual == chave_vers else chave_vers
                )

        with st.expander('📝 Anotação', expanded=bool(nota)):
            novo = st.text_area(
                'Anotação',
                value=nota,
                key=f'nota_{chave_vers}',
                label_visibility='collapsed',
                placeholder='Escreva sua anotação…',
            )
            bn1, bn2 = st.columns(2)
            with bn1:
                if st.button('Salvar anotação', key=f'nota_salvar_{chave_vers}', width='stretch'):
                    storage.definir_nota(chave_vers, novo)
                    st.rerun()
            with bn2:
                if nota and st.button('Excluir', key=f'nota_excluir_{chave_vers}', width='stretch'):
                    storage.definir_nota(chave_vers, '')
                    st.rerun()


def _render_estudos(nome, referencia) -> None:
    indice = data_source.carregar_estudos_indice()
    do_livro = [r for r in indice if r.livro == nome]
    aplicaveis = recursos_aplicaveis(do_livro, referencia, livro=nome)
    completos = [painel_estudos.recurso_completo(r) for r in aplicaveis]
    painel_estudos.render(
        completos,
        st.session_state['favoritos_estudos'],
        lambda id_: alternar_lista('favoritos_estudos', id_),
        tts_lento=st.session_state['tts_lento'],
    )


def _render_contexto(chave_capitulo) -> None:
    numero = None
    if chave_capitulo.startswith('Salmos '):
        try:
            numero = int(chave_capitulo.split(' ', 1)[1])
        except ValueError:
            numero = None
    contextos = data_source.carregar_contexto_livro('Salmos')
    contexto = contexto_do_salmo(contextos, numero) if numero else None
    if contexto:
        painel_contexto.render_detalhe(contexto, tts_lento=st.session_state['tts_lento'])
    else:
        st.info('Contexto histórico indisponível para este Salmo.')


