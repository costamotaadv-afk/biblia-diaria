"""Smoke test headless: o app Streamlit sobe e renderiza sem exceções.

Usa ``streamlit.testing.v1.AppTest`` para executar o script completo (tema,
navegação e aba Início) sem servidor.
"""

from streamlit.testing.v1 import AppTest


def test_app_inicio_renderiza_sem_excecao():
    at = AppTest.from_file('webapp/streamlit_app.py', default_timeout=90)
    at.run()
    assert not at.exception, at.exception

    textos = [m.value for m in at.markdown]
    assert any('Bíblia Diária' in t for t in textos)
    assert any('Versículo do Dia' in t for t in textos)
    assert any('Mensagem para você' in t for t in textos)
