"""Configurações de negócio do app (Pix) e validações associadas.

Porte 1:1 de ``lib/config.dart`` — cobre o caso B3 da matriz de QA
(tool/QA_EDGE_CASES.md). O AdMob foi removido por não haver equivalente
web no servidor.
"""

import re

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
