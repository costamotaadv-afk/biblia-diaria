"""Formatação de datas em pt-BR sem depender de locale/babel no Cloud."""

_DIAS_SEMANA = [
    'segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira',
    'sexta-feira', 'sábado', 'domingo',
]

_MESES = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
]


def formatar_data_extenso(data) -> str:
    """``'segunda-feira, 14 de outubro'`` — equivalente ao padrão pt-BR.

    Reproduz ``DateFormat("EEEE, d 'de' MMMM", 'pt_BR')`` do Flutter.
    """
    return (
        f'{_DIAS_SEMANA[data.weekday()]}, '
        f'{data.day} de {_MESES[data.month - 1]}'
    )
