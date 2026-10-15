"""Conversões de referências bíblicas e textos para leitura em voz alta.

Porte 1:1 de ``lib/leitura_natural.dart`` — funções puras, sem I/O e sem
Streamlit. Cobre os casos E6, E7, E10, E11 e E12 da matriz de QA.
"""

import re

_ORDINAIS = [
    '',  # índice 0 não é usado
    'primeira',
    'segunda',
    'terceira',
    'quarta',
    'quinta',
    'sexta',
    'sétima',
    'oitava',
    'nona',
    'décima',
]

_UNIDADES = [
    'zero', 'um', 'dois', 'três', 'quatro', 'cinco', 'seis', 'sete',
    'oito', 'nove', 'dez', 'onze', 'doze', 'treze', 'catorze', 'quinze',
    'dezesseis', 'dezessete', 'dezoito', 'dezenove',
]

_DEZENAS = [
    '', '', 'vinte', 'trinta', 'quarenta', 'cinquenta', 'sessenta',
    'setenta', 'oitenta', 'noventa',
]

_CENTENAS = [
    '', 'cento', 'duzentos', 'trezentos', 'quatrocentos', 'quinhentos',
    'seiscentos', 'setecentos', 'oitocentos', 'novecentos',
]


def referencia_para_leitura(referencia: str) -> str:
    """Converte uma referência ("Gênesis 1:1", "1 Coríntios 2:3") em fala natural."""
    ref = referencia.strip()
    if not ref:
        return ''

    # O número do livro (prefixo) nunca é confundido com capítulo/versículo,
    # pois o número final é sempre a referência (regex ancorada ao fim).
    match = re.match(r'^(.+?)\s+(\d{1,3})(?::(\d{1,3}))?$', ref)
    if match is None:
        # Sem número ao final: é só o nome do livro.
        return nome_livro_para_leitura(ref)

    livro = nome_livro_para_leitura(match.group(1).strip())
    cap_ext = numero_por_extenso(match.group(2))
    versiculo = match.group(3)
    base = f'{livro}, capítulo {cap_ext}'
    if versiculo is not None:
        return f'{base}, versículo {numero_por_extenso(versiculo)}'
    return base


def nome_livro_para_leitura(nome: str) -> str:
    """Converte prefixo numérico ("1 Coríntios") em ordinal ("Primeira Coríntios")."""
    limpo = nome.strip()
    match = re.match(r'^(\d+)\s+(.+)$', limpo)
    if match is None:
        return limpo

    numero = int(match.group(1))
    if numero < 1:
        return limpo

    if numero < len(_ORDINAIS):
        ordinal = _ORDINAIS[numero]
        return f'{ordinal[0].upper()}{ordinal[1:]} {match.group(2)}'
    return limpo


def numero_por_extenso(numero: str) -> str:
    """Converte um inteiro (0 a 999) para sua forma por extenso em português."""
    try:
        n = int(numero)
    except (ValueError, TypeError):
        return numero
    return escrever_numero(n)


def escrever_numero(n: int) -> str:
    """Escrita por extenso (0–999); fora do intervalo devolve o número cru."""
    if n < 0 or n > 999:
        return str(n)

    if n < 20:
        return _UNIDADES[n]

    if n < 100:
        d = n // 10
        u = n % 10
        resto = '' if u == 0 else f' e {_UNIDADES[u]}'
        return f'{_DEZENAS[d]}{resto}'

    if n == 100:
        return 'cem'

    c = n // 100
    r = n % 100
    if r == 0:
        return _CENTENAS[c]
    return f'{_CENTENAS[c]} e {escrever_numero(r)}'


def texto_para_leitura_natural(texto: str) -> str:
    """Prepara um texto bíblico para o TTS, transformando "Livro N:M" em fala natural."""
    t = texto.replace(' - ', ', ').replace(';', ', ').replace('"', '')
    t = re.sub(r'\s+', ' ', t).strip()

    def _sub(match):
        livro_nome = match.group(1).lower()
        cap = numero_por_extenso(match.group(2))
        vers = numero_por_extenso(match.group(3))
        # Em meio de frase, mantém minúsculas para o fluxo natural da leitura.
        return (
            f'{nome_livro_para_leitura(livro_nome).lower()}, '
            f'capítulo {cap}, versículo {vers}'
        )

    t = re.sub(r'((?:\d{1,2}\s+)?[A-Za-zÀ-ÿ]+)\s+(\d{1,3}):(\d{1,3})', _sub, t)
    return t


def dividir_texto_para_fala(texto: str, max_caracteres: int = 1500) -> list:
    """Divide texto longo em segmentos com no máximo ``max_caracteres``."""
    t = texto.strip()
    if not t:
        return []
    if len(t) <= max_caracteres:
        return [t]

    segmentos = []
    inicio = 0
    while inicio < len(t):
        if inicio + max_caracteres >= len(t):
            resto = t[inicio:].strip()
            if resto:
                segmentos.append(resto)
            break
        janela = t[inicio:inicio + max_caracteres]
        corte = _ultimo_indice_de_pontuacao(janela)
        if corte >= 0:
            corte += 1  # inclui a pontuação no segmento
        else:
            corte = janela.rfind(' ')
        if corte <= 0:
            corte = max_caracteres
        segmento = t[inicio:inicio + corte].strip()
        if segmento:
            segmentos.append(segmento)
        inicio += corte
        while inicio < len(t) and t[inicio] == ' ':
            inicio += 1
    return segmentos


def _ultimo_indice_de_pontuacao(s: str) -> int:
    indice = -1
    for pontuacao in ('.', '!', '?', ';'):
        posicao = s.rfind(pontuacao)
        if posicao > indice:
            indice = posicao
    return indice
