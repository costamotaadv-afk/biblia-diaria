"""Smoke test headless: o app Streamlit sobe e renderiza sem exceções.

Usa ``streamlit.testing.v1.AppTest`` para executar o script completo (tema,
navegação e aba Início) sem servidor.
"""

from pathlib import Path

from streamlit.testing.v1 import AppTest

# Caminho absoluto do app — independe do diretório de trabalho do pytest.
_APP_PATH = str(Path(__file__).resolve().parents[1] / 'streamlit_app.py')


def test_app_inicio_renderiza_sem_excecao():
    at = AppTest.from_file(_APP_PATH, default_timeout=90)
    at.run()
    assert not at.exception, at.exception

    textos = [m.value for m in at.markdown]
    assert any('Bíblia Diária' in t for t in textos)
    assert any('Versículo do Dia' in t for t in textos)
    assert any('Mensagem para você' in t for t in textos)
