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
    'tema': 'claro',
    'escala_pct': 118,
    'altura_linha': 1.65,
    'tts_lento': False,
    'capitulos_lidos': [],
    'notas_versiculos': {},
    'destaques_versiculos': {},
    'aba': 'Início',
    'estudos_secao': '📚 Biblioteca',
    'explorar_modo': 'Pessoas',
}

_ABAS = ('Início', 'Bíblia', 'Estudos', 'Salvos', 'Ajustes')

# Preferências persistidas (a navegação — aba/seção/modo — fica só na sessão,
# para o app abrir sempre na aba Início, como o Flutter).
_PERSIST_KEYS = (
    'favoritos_versiculos',
    'favoritos_capitulos',
    'favoritos_estudos',
    'tema',
    'escala_pct',
    'altura_linha',
    'tts_lento',
    'capitulos_lidos',
    'notas_versiculos',
    'destaques_versiculos',
)


def _persist_enabled() -> bool:
    return os.environ.get('BIBLIA_PERSIST', '0').lower() in ('1', 'true', 'yes', 'on')


def inicializar() -> None:
    """Garante as chaves de estado e restaura do JSON apenas uma vez por sessão."""
    for chave, valor in DEFAULTS.items():
        if chave not in st.session_state:
            st.session_state[chave] = valor

    # Restaura as preferências uma única vez (não a cada rerun): re-ler aqui
    # sobrescreveria, por exemplo, a aba recém-clicada com o valor persistido.
    if st.session_state.get('_inicializado'):
        return

    if _persist_enabled() and _PREFS_FILE.exists():
        try:
            data = json.loads(_PREFS_FILE.read_text(encoding='utf-8'))
            for chave in _PERSIST_KEYS:
                if chave in data:
                    st.session_state[chave] = data[chave]
            _migrar_legado(data)
        except Exception:
            pass

    st.session_state['_inicializado'] = True


def _migrar_legado(data):
    """Converte preferências antigas (tema_escuro/fonte_grande/aba Explorar)."""
    if 'tema' not in data and 'tema_escuro' in data:
        st.session_state['tema'] = 'escuro' if data['tema_escuro'] else 'claro'
    if 'escala_pct' not in data and 'fonte_grande' in data:
        st.session_state['escala_pct'] = 118 if data['fonte_grande'] else 100
    if data.get('aba') == 'Explorar':
        st.session_state['aba'] = 'Estudos'
        st.session_state['estudos_secao'] = '🧭 Explorar'


def salvar() -> None:
    """Escreve as preferências no JSON (somente se persistência habilitada)."""
    if not _persist_enabled():
        return
    try:
        _STATE_DIR.mkdir(parents=True, exist_ok=True)
        data = {
            chave: st.session_state[chave]
            for chave in _PERSIST_KEYS
            if chave in st.session_state
        }
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


def definir_nota(chave: str, texto: str) -> None:
    """Salva/remove a anotação de um versículo (texto vazio remove)."""
    notas = dict(st.session_state.get('notas_versiculos', {}))
    texto = (texto or '').strip()
    if texto:
        notas[chave] = texto
    else:
        notas.pop(chave, None)
    st.session_state['notas_versiculos'] = notas
    salvar()


def alternar_destaque(chave: str, cor: str) -> None:
    """Alterna a cor de destaque de um versículo (mesma cor remove)."""
    destaques = dict(st.session_state.get('destaques_versiculos', {}))
    if destaques.get(chave) == cor:
        destaques.pop(chave, None)
    else:
        destaques[chave] = cor
    st.session_state['destaques_versiculos'] = destaques
    salvar()
