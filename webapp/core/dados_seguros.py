"""Helpers seguros para dados carregados de JSON (assets).

Porte 1:1 de ``lib/dados_seguros.dart``. Cobre os casos E1–E9, E13, B5 e E16
da matriz de QA (tool/QA_EDGE_CASES.md).
"""

from datetime import date

from .leitura_natural import numero_por_extenso


def _dart_str(valor):
    """Reproduz a interpolação de string do Dart (``'$valor'``): None → 'null'."""
    return 'null' if valor is None else str(valor)


def como_lista(valor):
    """Devolve ``valor`` se for uma ``list``; caso contrário, ``None``."""
    return valor if isinstance(valor, list) else None


def normalizar_mensagens(decodificado):
    """Normaliza a lista de mensagens, descartando itens não-string (E8/E9)."""
    if not isinstance(decodificado, list):
        return []
    return [m for m in decodificado if isinstance(m, str) and m.strip()]


def dias_desde_epoca(data) -> int:
    """Número de dias entre ``data`` e 01/01/2024 (época).

    Aceita um ``datetime.date`` (ou qualquer objeto com year/month/day).
    """
    dia = date(data.year, data.month, data.day)
    return (dia - date(2024, 1, 1)).days


def _div_trunc(a: int, b: int) -> int:
    """Equivalente ao operador ``~/`` do Dart (divisão truncada em direção a zero).

    O ``//`` do Python faz divisão de piso; para dias negativos (E13) o Dart
    trunca em direção a zero, então replicamos esse comportamento.
    """
    return a // b if a >= 0 else -((-a) // b)


def selecionar_versiculo_do_dia(dia, mensagens, livro):
    """Seleciona o conteúdo do "Versículo do Dia" de forma pura e determinística.

    Cobre E1 (índice vazio → livro nulo), E2 (livro nulo), E3 (capitulos com
    tipo errado), E4 (versículos vazios), E5 (texto vazio), E13 (dias
    negativos) e B5 (determinismo).
    """
    mensagem = (
        mensagens[dia % len(mensagens)]
        if mensagens
        else 'Deus te fortaleça neste dia.'
    )

    sem_conteudo = {
        'versiculo': 'Sem conteúdo bíblico disponível.',
        'referencia': '',
        'mensagem': mensagem,
    }

    if livro is None:
        return {
            'versiculo': 'Carregando conteúdo...',
            'referencia': '',
            'mensagem': mensagem,
        }

    capitulos = como_lista(livro.get('capitulos')) or []
    if not capitulos:
        return sem_conteudo

    cap_raw = capitulos[_div_trunc(dia, 66) % len(capitulos)]
    if not isinstance(cap_raw, dict):
        return sem_conteudo
    cap = dict(cap_raw)

    versiculos = como_lista(cap.get('versiculos')) or []
    if not versiculos:
        return sem_conteudo

    vers_raw = versiculos[
        _div_trunc(dia, 66 * len(capitulos)) % len(versiculos)
    ]
    if not isinstance(vers_raw, dict):
        return sem_conteudo

    texto = _dart_str(vers_raw.get('texto'))
    if not texto.strip():
        return sem_conteudo

    return {
        'versiculo': texto,
        'referencia': (
            f"{_dart_str(livro.get('nome'))} "
            f"{_dart_str(cap.get('numero'))}:{_dart_str(vers_raw.get('numero'))}"
        ),
        'mensagem': mensagem,
    }


def mapas_seguros(itens):
    """Converte uma lista bruta em mapas, descartando itens não-``dict`` (E16)."""
    if itens is None:
        return []
    return [dict(item) for item in itens if isinstance(item, dict)]


def texto_de_versiculo_em_livros(livros, chave):
    """Procura o texto de um versículo ("Livro N:M") entre os livros carregados."""
    for livro in livros:
        for capitulo in mapas_seguros(como_lista(livro.get('capitulos'))):
            for versiculo in mapas_seguros(como_lista(capitulo.get('versiculos'))):
                ref = (
                    f"{_dart_str(livro.get('nome'))} "
                    f"{_dart_str(capitulo.get('numero'))}:"
                    f"{_dart_str(versiculo.get('numero'))}"
                )
                if ref == chave:
                    return _dart_str(versiculo.get('texto'))
    return None


def texto_de_capitulo_em_livros(livros, chave_capitulo, anunciar_versiculos=True):
    """Procura o texto (falado) de um capítulo — "Versículo N. ...".

    ``anunciar_versiculos=False`` remove o prefixo "Versículo N." para uma
    narração mais fluida (as pausas vêm da pontuação dos próprios versículos).
    """
    for livro in livros:
        for capitulo in mapas_seguros(como_lista(livro.get('capitulos'))):
            chave = (
                f"{_dart_str(livro.get('nome'))} "
                f"{_dart_str(capitulo.get('numero'))}"
            )
            if chave != chave_capitulo:
                continue
            versiculos = mapas_seguros(como_lista(capitulo.get('versiculos')))
            textos = []
            for versiculo in versiculos:
                prefixo = (
                    f"Versículo {numero_por_extenso(_dart_str(versiculo.get('numero')))}. "
                    if anunciar_versiculos
                    else ''
                )
                textos.append(f"{prefixo}{_dart_str(versiculo.get('texto'))}")
            return ' '.join(textos)
    return None
