"""Loaders de dados sobre ``assets/data``, em cache via ``st.cache_data``.

Substituem os caches ``CacheDe*`` do Flutter (deduplicação/retry). Os dados são
reutilizados no lugar — sem duplicar os ~13 MB.
"""

import json
import os
from pathlib import Path

from . import dados_seguros as ds
from .catalogo_estudos import recursos_de_json
from .contexto_historico import contextos_de_json

try:
    import streamlit as st
except ImportError:  # pragma: no cover — testes podem rodar sem Streamlit
    st = None


def data_dir() -> Path:
    """Diretório raiz dos dados JSON (overrideável via ``BIBLIA_DATA_DIR``)."""
    override = os.environ.get('BIBLIA_DATA_DIR')
    if override:
        return Path(override)
    # webapp/core/data_source.py → repo/assets/data
    return Path(__file__).resolve().parents[2] / 'assets' / 'data'


def _ler_json(caminho: Path):
    with open(caminho, encoding='utf-8') as f:
        return json.load(f)


def _cache(fn):
    """Aplica ``st.cache_data`` quando Streamlit está disponível; senão usa a função."""
    if st is not None:
        return st.cache_data(show_spinner=False)(fn)
    return fn


def _carregar_indice():
    try:
        decod = _ler_json(data_dir() / 'indice.json')
        return [dict(m) for m in (ds.como_lista(decod) or []) if isinstance(m, dict)]
    except Exception:
        return []


def _carregar_mensagens():
    try:
        return ds.normalizar_mensagens(_ler_json(data_dir() / 'mensagens.json'))
    except Exception:
        return []


def _carregar_livro(nome):
    try:
        decod = _ler_json(data_dir() / 'livros' / f'{nome}.json')
        return dict(decod) if isinstance(decod, dict) else None
    except Exception:
        return None


def _carregar_estudos_indice():
    try:
        return recursos_de_json(_ler_json(data_dir() / 'estudos_indice.json'))
    except Exception:
        return []


def _carregar_estudos_livro(livro):
    try:
        return recursos_de_json(_ler_json(data_dir() / 'estudos' / f'{livro}.json'))
    except Exception:
        return []


def _carregar_contexto_livro(livro):
    try:
        return contextos_de_json(_ler_json(data_dir() / 'contexto' / f'{livro}.json'))
    except Exception:
        return []


# API pública em cache.
carregar_indice = _cache(_carregar_indice)
carregar_mensagens = _cache(_carregar_mensagens)
carregar_livro = _cache(_carregar_livro)
carregar_estudos_indice = _cache(_carregar_estudos_indice)
carregar_estudos_livro = _cache(_carregar_estudos_livro)
carregar_contexto_livro = _cache(_carregar_contexto_livro)
