"""Aba Explorar: pessoas, lugares, cronologia e dicionário (Theographic).

Expõe no webapp os recursos já disponíveis no núcleo (``metadados_biblia``):
pessoas/lugares mais citados com os versículos onde aparecem, a linha do
tempo cronológica e o dicionário Easton.
"""

import re

import streamlit as st

from core import dados_seguros as ds
from core import data_source, exploracao, nomes_pt
from core import metadados_biblia as md

_REF_RE = re.compile(r'^(.*?)\s+(\d+):(\d+)$')


def render():
    if not exploracao.disponivel():
        st.info(
            'Base de dados histórica indisponível neste ambiente. '
            'Gere-a com `python tool/construir_metadados.py`.'
        )
        return

    modo = st.radio(
        'Explorar',
        ['Pessoas', 'Lugares', 'Linha do tempo', 'Dicionário'],
        key='explorar_modo',
        horizontal=True,
        label_visibility='collapsed',
    )
    if modo == 'Pessoas':
        _render_pessoas()
    elif modo == 'Lugares':
        _render_lugares()
    elif modo == 'Linha do tempo':
        _render_cronologia()
    else:
        _render_dicionario()

    st.caption('Fonte: Theographic Bible Metadata (CC BY-SA 4.0).')


def _render_pessoas():
    pessoas = exploracao.listar_pessoas()
    termo = st.text_input('🔍 Buscar pessoa', key='explorar_pessoa_busca')
    if termo:
        alvo = md._slug(termo)
        filtradas = [p for p in pessoas if alvo in md._slug(p['name'])][:200]
    else:
        filtradas = pessoas[:100]  # mais citadas
    if not filtradas:
        st.info('Nenhuma pessoa encontrada.')
        return
    labels = [f"{nomes_pt.traduzir(p['name'])} ({p['verse_count']} v.)" for p in filtradas]
    idx = st.selectbox('Pessoa', range(len(filtradas)), format_func=lambda i: labels[i],
                       key='explorar_pessoa_idx')
    p = filtradas[idx]
    st.markdown(f"### {nomes_pt.traduzir(p['name'])}")
    if p.get('display_title'):
        st.markdown(f"*{p['display_title']}*")
    anos = []
    if p.get('birth_year') is not None:
        anos.append(f"Nasc.: {md.rotulo_ano(p['birth_year'])}")
    if p.get('death_year') is not None:
        anos.append(f"Morte: {md.rotulo_ano(p['death_year'])}")
    if anos:
        st.markdown(' · '.join(anos))
    st.markdown(f"Mencionada em **{p['verse_count']}** versículo(s).")
    _render_versiculos(exploracao.versiculos_da_pessoa(p['person_id']), 'pessoa')


def _render_lugares():
    lugares = exploracao.listar_lugares()
    termo = st.text_input('🔍 Buscar lugar', key='explorar_lugar_busca')
    if termo:
        alvo = md._slug(termo)
        filtradas = [l for l in lugares if alvo in md._slug(l['name'])][:200]
    else:
        filtradas = lugares[:100]
    if not filtradas:
        st.info('Nenhum lugar encontrado.')
        return
    labels = [f"{nomes_pt.traduzir(l['name'])} ({l['verse_count']} v.)" for l in filtradas]
    idx = st.selectbox('Lugar', range(len(filtradas)), format_func=lambda i: labels[i],
                       key='explorar_lugar_idx')
    l = filtradas[idx]
    st.markdown(f"### {nomes_pt.traduzir(l['name'])}")
    if l.get('display_title'):
        st.markdown(f"*{l['display_title']}*")
    if l.get('feature_type'):
        st.markdown(f"Tipo: {l['feature_type']}")
    st.markdown(f"Mencionado em **{l['verse_count']}** versículo(s).")
    _render_versiculos(exploracao.versiculos_do_lugar(l['place_id']), 'lugar')


def _render_cronologia():
    eventos = exploracao.cronologia()
    st.markdown(f'### Linha do tempo ({len(eventos)} eventos)')
    linhas = []
    for e in eventos:
        ano = md.rotulo_ano(e.get('start_date')) or '?'
        linhas.append(f"- **{ano}** — {nomes_pt.traduzir(e['title'])}")
    st.markdown('\n'.join(linhas))


def _render_dicionario():
    termo = st.text_input('🔍 Buscar verbete (ex.: Aaron, Jericho, Tabernacle)',
                          key='explorar_easton_busca')
    if not termo:
        st.info('Digite um termo para consultar o dicionário Easton (6.519 verbetes).')
        return
    verbete = exploracao.buscar_easton(termo)
    if verbete:
        _render_verbete(verbete)
        return
    sugestoes = exploracao.sugerir_easton(termo)
    if not sugestoes:
        st.info('Verbete não encontrado.')
        return
    labels = [s['term_label'] for s in sugestoes]
    st.markdown('Verbete exato não encontrado — sugestões:')
    escolha = st.selectbox('Sugestão', range(len(sugestoes)), format_func=lambda i: labels[i],
                           key='explorar_easton_sugestao')
    verbete = exploracao.buscar_easton(labels[escolha])
    if verbete:
        _render_verbete(verbete)


def _render_verbete(verbete):
    st.markdown(f"### {verbete['term_label']}")
    st.markdown(verbete['dict_text'] or '')


def _render_versiculos(versos, prefixo):
    if not versos:
        st.info('Sem versículos associados.')
        return
    refs = [v['verse_reference'] for v in versos]
    st.markdown(f'**Versículos associados** — {len(refs)} no total:')
    c1, c2 = st.columns([3, 1])
    with c1:
        alvo = st.selectbox('Abrir versículo na aba Bíblia', refs,
                            key=f'{prefixo}_ref_alvo')
    with c2:
        if st.button('🔎 Abrir', key=f'{prefixo}_ref_abrir', use_container_width=True):
            _ir_para_versiculo(alvo)
    st.markdown('  \n'.join(f'• {r}' for r in refs[:40]))
    if len(refs) > 40:
        st.caption(f'Mostrando 40 de {len(refs)}.')


def _ir_para_versiculo(referencia):
    m = _REF_RE.match((referencia or '').strip())
    if not m:
        return
    livro_nome, capitulo, versiculo = m.group(1), m.group(2), m.group(3)
    nomes = [f"{i.get('nome')}" for i in data_source.carregar_indice()]
    if livro_nome not in nomes:
        return
    livro = data_source.carregar_livro(livro_nome)
    if not livro:
        return
    capitulos = [c for c in (ds.como_lista(livro.get('capitulos')) or [])
                 if isinstance(c, dict)]
    idx_cap = _indice_por_numero(capitulos, capitulo)
    versiculos = [v for v in (ds.como_lista(capitulos[idx_cap].get('versiculos')) or [])
                  if isinstance(v, dict)]
    idx_ver = _indice_por_numero(versiculos, versiculo)
    st.session_state['aba'] = 'Bíblia'
    st.session_state['biblia_livro'] = livro_nome
    st.session_state['biblia_capitulo_idx'] = idx_cap
    st.session_state['biblia_versiculo_idx'] = idx_ver


def _indice_por_numero(itens, numero):
    for i, item in enumerate(itens):
        if str(item.get('numero')) == str(numero):
            return i
    return 0

