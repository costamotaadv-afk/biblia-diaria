"""Lógica pura do progresso de leitura da Bíblia (sem I/O e sem Streamlit).

Porte 1:1 de ``lib/progresso_leitura.dart``. O progresso é medido por capítulos
lidos, no formato ``"Livro N"`` (mesmo padrão dos favoritos de capítulo).
"""


def total_de_capitulos(indice) -> int:
    """Soma o total de capítulos de todos os livros do índice."""
    total = 0
    for livro in indice:
        capitulos = livro.get('capitulos')
        if isinstance(capitulos, int):
            total += capitulos
        elif isinstance(capitulos, float):
            total += int(capitulos)
    return total


def contar_capitulos_lidos(indice, lidos) -> int:
    """Conta, entre ``lidos``, apenas chaves de capítulos reais do índice."""
    count = 0
    for livro in indice:
        nome = str(livro.get('nome'))
        capitulos = livro.get('capitulos')
        total = (
            capitulos
            if isinstance(capitulos, int)
            else (int(capitulos) if isinstance(capitulos, float) else 0)
        )
        for c in range(1, total + 1):
            if f'{nome} {c}' in lidos:
                count += 1
    return count


def fracao_lida(indice, lidos) -> float:
    """Fração (0..1) da Bíblia já lida, baseada nos capítulos lidos válidos."""
    total = total_de_capitulos(indice)
    if total == 0:
        return 0.0
    return max(0.0, min(1.0, contar_capitulos_lidos(indice, lidos) / total))
