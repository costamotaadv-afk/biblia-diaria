"""Configurações de negócio do app (Pix) e validações associadas.

Porte 1:1 de ``lib/config.dart`` — cobre o caso B3 da matriz de QA
(tool/QA_EDGE_CASES.md). O AdMob foi removido por não haver equivalente
web no servidor.
"""

import re
import urllib.parse

# Chave Pix (e-mail) que recebe as doações do projeto.
CHAVE_PIX = 'costamota@gmail.com'

# Formato exigido pelo Pix: e-mail válido.
_REGEX_EMAIL = re.compile(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')


def chave_pix_valida(chave: str) -> bool:
    """True se ``chave`` tem formato de e-mail (formato exigido pelo Pix).

    Caso B3 da matriz: a chave fixa no código não pode ser trocada por um
    valor inválido em manutenção futura sem que um teste acuse imediatamente.
    """
    return _REGEX_EMAIL.match(chave) is not None


# Link público de download/uso do app, usado na mensagem de compartilhamento.
# Deixe vazio até publicar o site/loja: com o link vazio, o botão fica oculto.
LINK_DOWNLOAD = ''


def link_valido(link: str = LINK_DOWNLOAD) -> bool:
    """True se ``link`` é um URL absoluto http/https com domínio (caso SH1)."""
    url = urllib.parse.urlparse(link.strip())
    return url.scheme in ('http', 'https') and bool(url.netloc)


def mensagem_compartilhamento(link: str = LINK_DOWNLOAD) -> str:
    """Mensagem pronta para o WhatsApp (ou qualquer rede escolhida)."""
    return (
        '📖 *Bíblia Diária* — a Bíblia completa, gratuita e offline, '
        'com leitura em voz alta.\n\nAcesse: ' + link
    )


def url_whatsapp(texto: str) -> str:
    """Deep link do WhatsApp com ``texto`` já codificado (sem copiar manual)."""
    return 'https://wa.me/?text=' + urllib.parse.quote(texto, safe='')


def _rodape(link: str) -> str:
    """Rodapé de divulgação do app; vazio enquanto o link não foi publicado."""
    return f'\n\n📲 Baixe grátis: {link}' if link_valido(link) else ''


def mensagem_versiculo(referencia: str, texto: str, link: str = LINK_DOWNLOAD) -> str:
    """Mensagem para compartilhar um versículo (caso SV1)."""
    return f'📖 *{referencia}*\n\n“{texto}”{_rodape(link)}'


def mensagem_capitulo(referencia: str, texto: str, link: str = LINK_DOWNLOAD) -> str:
    """Mensagem para compartilhar um capítulo inteiro (caso SC1)."""
    return f'📖 *{referencia}*\n\n{texto}{_rodape(link)}'


def mensagem_salmo(numero: int, titulo: str, explicacao: str, link: str = LINK_DOWNLOAD) -> str:
    """Mensagem para compartilhar a contextualização histórica de um Salmo (SS1)."""
    cabecalho = f'Salmo {numero}' if not titulo.strip() else f'Salmo {numero} — {titulo}'
    partes = [f'📖 *{cabecalho}*']
    explic = explicacao.strip()
    if explic:
        partes.append(explic)
    return '\n\n'.join(partes) + _rodape(link)
