"""Cruzamentos históricos (Theographic) para a leitura de versículos.

Fachada fina sobre ``core.metadados_biblia`` voltada ao app Streamlit:
localiza o banco SQLite gerado (fora do git, em ``tool/theographic/``),
consulta pessoas/lugares/eventos/grupos de um versículo e degrada
graciosamente quando o banco não existe (ex.: Streamlit Cloud, cujo
filesystem é efêmero e não inclui o banco gerado).
"""

import os
from pathlib import Path

from . import metadados_biblia as md

_NOME_BANCO = "biblia_metadados.db"


def diretorio_dados() -> Path:
    """Diretório do banco (overrideável via ``BIBLIA_METADADOS_DIR``)."""
    override = os.environ.get("BIBLIA_METADADOS_DIR")
    if override:
        return Path(override).resolve()
    # webapp/core/cruzamentos.py → repo/tool/theographic
    return Path(__file__).resolve().parents[2] / "tool" / "theographic"


def caminho_banco() -> Path:
    """Caminho completo do SQLite gerado."""
    return diretorio_dados() / _NOME_BANCO


def metadados_disponiveis() -> bool:
    """True se o banco gerado existe e pode ser consultado."""
    return caminho_banco().is_file()


def cruzamentos_de(conn, referencia):
    """Devolve os cruzamentos de um versículo, ou ``None`` se não houver.

    Estrutura retornada::

        {
            'referencia': 'João 3:16',
            'pessoas': [dict, ...],
            'lugares': [dict, ...],
            'eventos': [dict, ...],
            'grupos': [dict, ...],
        }

    Cada item é uma linha (``sqlite3.Row``) convertida em ``dict``.
    """
    versiculo = md.buscar_versiculo_por_referencia(conn, referencia)
    if versiculo is None:
        return None
    vid = versiculo["verse_id"]
    return {
        "referencia": referencia,
        "pessoas": [dict(r) for r in md.pessoas_do_versiculo(conn, vid)],
        "lugares": [dict(r) for r in md.lugares_do_versiculo(conn, vid)],
        "eventos": [dict(r) for r in md.eventos_do_versiculo(conn, vid)],
        "grupos": [dict(r) for r in md.grupos_do_versiculo(conn, vid)],
    }


def cruzamentos_do_versiculo(referencia):
    """Consulta pronta para a UI; ``None`` se o banco não existir ou o
    versículo não tiver metadados."""
    if not metadados_disponiveis():
        return None
    conn = md.abrir_banco(str(caminho_banco()))
    try:
        return cruzamentos_de(conn, referencia)
    finally:
        conn.close()
