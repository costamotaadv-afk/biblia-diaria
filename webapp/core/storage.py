"""Estado da sessão como fonte da verdade + escrita opcional em JSON.

Favoritos e preferências vivem em ``st.session_state``. Quando a variável de
ambiente ``BIBLIA_PERSIST`` vale ``1``/``true``, há write-through em
``webapp/.state/prefs.json`` (útil em dev local; desligado no Cloud, cujo
filesystem é efêmero e compartilhado).
"""

import json
import os
from pathlib import Path

import streamlit as st

_STATE_DIR = Path(__file__).resolve().parents[1] / '.state'
_PREFS_FILE = _STATE_DIR / 'prefs.json'

DEFAULTS = {
    'favoritos_versiculos': [],
    'favoritos_capitulos': [],
    'favoritos_estudos': [],
    'tema_escuro': False,
    'fonte_grande': True,
    'tts_lento': False,
    'aba': 'Início',
}

_ABAS = ('Início', 'Bíblia', 'Estudos', 'Salvos', 'Ajustes')


def _persist_enabled() -> bool:
    return os.environ.get('BIBLIA_PERSIST', '0').lower() in ('1', 'true', 'yes', 'on')


def inicializar() -> None:
    """Garante as chaves de estado e restaura do JSON, se habilitado."""
    for chave, valor in DEFAULTS.items():
        if chave not in st.session_state:
            st.session_state[chave] = valor

    if _persist_enabled() and _PREFS_FILE.exists():
        try:
            data = json.loads(_PREFS_FILE.read_text(encoding='utf-8'))
            for chave in DEFAULTS:
                if chave in data:
                    st.session_state[chave] = data[chave]
        except Exception:
            pass


def salvar() -> None:
    """Escreve o estado atual no JSON (somente se persistência habilitada)."""
    if not _persist_enabled():
        return
    try:
        _STATE_DIR.mkdir(parents=True, exist_ok=True)
        data = {chave: st.session_state[chave] for chave in DEFAULTS}
        _PREFS_FILE.write_text(
            json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8'
        )
    except Exception:
        pass


def alternar_lista(chave: str, valor) -> bool:
    """Alterna ``valor`` na lista ``st.session_state[chave]``; True se removeu."""
    lista = list(st.session_state.get(chave, []))
    if valor in lista:
        lista.remove(valor)
        removido = True
    else:
        lista.append(valor)
        removido = False
    st.session_state[chave] = lista
    salvar()
    return removido
