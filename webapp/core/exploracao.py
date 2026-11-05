"""Fachada de exploração do acervo histórico do Theographic.

Consulta pessoas/lugares/cronologia/dicionário (Easton) para a aba Explorar.
Reusa ``cruzamentos`` para localizar o banco e degrada graciosamente quando
ele não existe (ex.: Streamlit Cloud).
"""

from . import metadados_biblia as md
from . import cruzamentos


def disponivel() -> bool:
    """True se o banco gerado existe e pode ser consultado."""
    return cruzamentos.metadados_disponiveis()


def _conexao():
    if not disponivel():
        return None
    return md.abrir_banco(str(cruzamentos.caminho_banco()))


def _linhas(fn, *args, **kwargs):
    """Executa ``fn(conn, ...)`` e devolve as linhas como lista de dicts."""
    conn = _conexao()
    if conn is None:
        return []
    try:
        return [dict(r) for r in fn(conn, *args, **kwargs)]
    finally:
        conn.close()


def listar_pessoas(limite=None):
    return _linhas(md.listar_pessoas, limite)


def listar_lugares(limite=None):
    return _linhas(md.listar_lugares, limite)


def versiculos_da_pessoa(person_id, limite=100):
    return _linhas(md.versiculos_da_pessoa, person_id, limite)


def versiculos_do_lugar(place_id, limite=100):
    return _linhas(md.versiculos_do_lugar, place_id, limite)


def cronologia(limite=None):
    return _linhas(md.cronologia, limite)


def buscar_easton(termo):
    """Verbete exato (por termo), ou ``None``."""
    conn = _conexao()
    if conn is None:
        return None
    try:
        r = md.buscar_easton(conn, termo)
        return dict(r) if r else None
    finally:
        conn.close()


def sugerir_easton(termo, limite=20):
    return _linhas(md.sugerir_easton, termo, limite)
