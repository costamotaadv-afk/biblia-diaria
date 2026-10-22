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


def test_botao_ler_a_biblia_navega_sem_excecao():
    """Regressão: clicar em 'Ler a Bíblia' não pode lançar StreamlitAPIException."""
    at = AppTest.from_file(_APP_PATH, default_timeout=90)
    at.run()

    botao = next(b for b in at.button if b.label == '📖 Ler a Bíblia')
    botao.click().run()

    assert not at.exception, at.exception
    assert at.radio[0].value == 'Bíblia'
    assert any(sb.label == 'Livro' for sb in at.selectbox)


def test_botao_salvos_navega_sem_excecao():
    """Regressão: clicar em 'Salvos' não pode lançar StreamlitAPIException."""
    at = AppTest.from_file(_APP_PATH, default_timeout=90)
    at.run()

    botao = next(b for b in at.button if b.label == '🔖 Salvos')
    botao.click().run()

    assert not at.exception, at.exception
    assert at.radio[0].value == 'Salvos'


def test_referencia_cruzada_navega_para_biblia_sem_excecao():
    """Regressão: referência cruzada do contexto histórico troca a aba sem erro."""
    at = AppTest.from_file(_APP_PATH, default_timeout=90)
    at.run()

    at.radio[0].set_value('Estudos').run()
    assert not at.exception, at.exception

    botao_contexto = next(
        b for b in at.button if 'Contexto histórico' in b.label
    )
    botao_contexto.click().run()
    assert not at.exception, at.exception

    referencia = next(
        b for b in at.button if b.key and b.key.startswith('ctx_ref_')
    )
    referencia.click().run()

    assert not at.exception, at.exception
    assert at.radio[0].value == 'Bíblia'
    assert at.selectbox[0].value  # livro da referência já pré-selecionado


def test_botao_compartilhar_oculto_com_link_vazio():
    """SH3: sem link definido, o botão de compartilhar não é renderizado."""
    at = AppTest.from_file(_APP_PATH, default_timeout=90)
    at.run()
    assert not at.exception, at.exception
    assert at.get('link_button') == []


def test_botao_compartilhar_renderiza_quando_link_definido(monkeypatch):
    """SH1: com link definido, o botão aponta para o WhatsApp com a mensagem."""
    import core.config as config

    monkeypatch.setattr(
        config, 'LINK_DOWNLOAD', 'https://biblia-diaria.streamlit.app'
    )

    at = AppTest.from_file(_APP_PATH, default_timeout=90)
    at.run()
    assert not at.exception, at.exception

    links = at.get('link_button')
    assert len(links) == 1
    assert links[0].proto.label == '📲 Compartilhar no WhatsApp'
    assert links[0].proto.url == config.url_whatsapp(
        config.mensagem_compartilhamento()
    )
