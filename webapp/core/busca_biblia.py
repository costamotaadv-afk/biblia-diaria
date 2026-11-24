"""Busca textual na Bíblia (funções puras, sem I/O e sem Streamlit).

Porte 1:1 de ``lib/busca_biblia.dart``: normalização tolerante (minúsculas e
sem acentos) e varredura dos livros já carregados, limitada a ``limite``
resultados.
"""

import unicodedata
from dataclasses import dataclass

from . import dados_seguros as ds


@dataclass(frozen=True)
class ResultadoBusca:
    """Um versículo que casa com o termo pesquisado."""

    livro: str
    capitulo: str
    versiculo: str
    texto: str

    @property
    def referencia(self) -> str:
        return f'{self.livro} {self.capitulo}:{self.versiculo}'


def normalizar_para_busca(texto: str) -> str:
    """Normaliza para busca: minúsculas e sem acentos (busca tolerante)."""
    texto = unicodedata.normalize('NFD', texto or '')
    texto = ''.join(c for c in texto if not unicodedata.combining(c))
    return texto.lower().strip()


def buscar_na_biblia(livros, termo: str, limite: int = 100):
    """Varre ``livros`` (JSON já carregados) e devolve versículos cujo texto
    contém ``termo``, limitado a ``limite`` resultados."""
    alvo = normalizar_para_busca(termo)
    if not alvo:
        return []

    resultados = []
    for livro in livros:
        nome = str(livro.get('nome'))
        capitulos = ds.mapas_seguros(ds.como_lista(livro.get('capitulos')))
        for capitulo in capitulos:
            numero_capitulo = str(capitulo.get('numero'))
            versiculos = ds.mapas_seguros(ds.como_lista(capitulo.get('versiculos')))
            for versiculo in versiculos:
                texto = str(versiculo.get('texto'))
                if alvo in normalizar_para_busca(texto):
                    resultados.append(
                        ResultadoBusca(
                            livro=nome,
                            capitulo=numero_capitulo,
                            versiculo=str(versiculo.get('numero')),
                            texto=texto,
                        )
                    )
                    if len(resultados) >= limite:
                        return resultados
    return resultados
