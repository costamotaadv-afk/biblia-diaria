"""Catálogo de recursos de estudo do texto bíblico.

Porte 1:1 de ``lib/catalogo_estudos.dart`` — funções puras (sem I/O, sem
Streamlit). Cobre os casos EST1–EST8 da matriz de QA.
"""

import unicodedata


class FonteEstudo:
    """Fonte/atribuição de um recurso de estudo (autor, obra, ano, licença)."""

    def __init__(self, autor='', obra='', ano='', licenca=''):
        self.autor = autor
        self.obra = obra
        self.ano = ano
        self.licenca = licenca

    @property
    def vazio(self) -> bool:
        return not (
            self.autor.strip()
            or self.obra.strip()
            or self.ano.strip()
            or self.licenca.strip()
        )

    @property
    def credito(self) -> str:
        """Crédito legível montado apenas com os campos existentes."""
        a = self.autor.strip()
        o = self.obra.strip()
        ano = self.ano.strip()
        l = self.licenca.strip()

        partes = []
        if a:
            partes.append(a)
        if o:
            partes.append(f'{o} ({ano})' if ano else o)
        elif ano:
            partes.append(ano)

        base = ', '.join(partes)
        if l:
            return l if not base else f'{base} — {l}'
        return base


class RecursoEstudo:
    """Recurso de estudo associado (opcionalmente) a uma referência bíblica."""

    def __init__(self, id, tipo, titulo, corpo, referencia, livro,
                 temas=None, periodo='', fatos=None, fonte=None):
        self.id = id
        self.tipo = tipo
        self.titulo = titulo
        self.corpo = corpo
        self.referencia = referencia
        self.livro = livro
        self.temas = temas if temas is not None else []
        self.periodo = periodo
        self.fatos = fatos if fatos is not None else []
        self.fonte = fonte

    @property
    def tem_corpo(self) -> bool:
        return bool(self.corpo.strip())

    @property
    def tem_fonte(self) -> bool:
        return self.fonte is not None and not self.fonte.vazio

    @property
    def tem_periodo(self) -> bool:
        return bool(self.periodo.strip())

    @property
    def tem_fatos(self) -> bool:
        return bool(self.fatos)


def _texto(valor):
    return '' if valor is None else str(valor).strip()


def _lista_de_texto(valor):
    if not isinstance(valor, list):
        return []
    itens = []
    for item in valor:
        t = _texto(item)
        if t:
            itens.append(t)
    return itens


def _fonte_de_mapa(valor):
    if not isinstance(valor, dict):
        return None
    fonte = FonteEstudo(
        autor=_texto(valor.get('autor')),
        obra=_texto(valor.get('obra')),
        ano=_texto(valor.get('ano')),
        licenca=_texto(valor.get('licenca')),
    )
    return None if fonte.vazio else fonte


def recurso_de_mapa(valor):
    """Converte um item bruto em ``RecursoEstudo``; ``None`` para inválidos (EST2)."""
    if not isinstance(valor, dict):
        return None
    id_ = _texto(valor.get('id'))
    if not id_:
        return None

    return RecursoEstudo(
        id=id_,
        tipo=_texto(valor.get('tipo')),
        titulo=_texto(valor.get('titulo')),
        corpo=_texto(valor.get('corpo')),
        referencia=_texto(valor.get('ref')),
        livro=_texto(valor.get('livro')),
        temas=_lista_de_texto(valor.get('tema')),
        periodo=_texto(valor.get('periodo')),
        fatos=_lista_de_texto(valor.get('fatos')),
        fonte=_fonte_de_mapa(valor.get('fonte')),
    )


def recursos_de_json(decodificado):
    """Converte lista bruta em recursos válidos; não-lista → lista vazia."""
    if not isinstance(decodificado, list):
        return []
    recursos = []
    for item in decodificado:
        recurso = recurso_de_mapa(item)
        if recurso is not None:
            recursos.append(recurso)
    return recursos


TIPOS_CONHECIDOS = [
    'nota',
    'comentario',
    'artigo',
    'sermao',
    'palestra',
    'momento_historico',
]

_ROTULOS_FIXOS = {
    'nota': 'Nota',
    'comentario': 'Comentário',
    'artigo': 'Artigo',
    'sermao': 'Sermão',
    'palestra': 'Palestra',
    'momento_historico': 'Momento histórico',
}


def rotulo_tipo(tipo: str) -> str:
    """Rótulo legível do tipo; desconhecido vira capitalizado (EST6)."""
    t = tipo.strip()
    if not t:
        return 'Estudo'
    if t in _ROTULOS_FIXOS:
        return _ROTULOS_FIXOS[t]
    return f'{t[0].upper()}{t[1:]}'


def agrupar_por_tipo(recursos):
    """Agrupa recursos por tipo em ordem determinística (EST5)."""
    ordem_aparicao = []
    mapa = {}
    for recurso in recursos:
        if recurso.tipo not in mapa:
            ordem_aparicao.append(recurso.tipo)
            mapa[recurso.tipo] = []
        mapa[recurso.tipo].append(recurso)

    conhecidos = [t for t in TIPOS_CONHECIDOS if t in mapa]
    desconhecidos = [t for t in ordem_aparicao if t not in TIPOS_CONHECIDOS]
    ordenados = conhecidos + desconhecidos
    return {chave: mapa[chave] for chave in ordenados}


def capitulo_da_referencia(referencia: str):
    """``"João 3:16"`` → ``"João 3"``; referência de capítulo/livro → ``None``."""
    ref = referencia.strip()
    posicao = ref.rfind(':')
    if posicao <= 0:
        return None
    capitulo = ref[:posicao].strip()
    return capitulo if capitulo else None


def recurso_aplicavel(recurso, referencia, livro=None) -> bool:
    """True se ``recurso`` se aplica à ``referencia`` (igual, capítulo ou livro)."""
    ref = recurso.referencia.strip()
    alvo = referencia.strip()
    if not ref or not alvo:
        return False

    if ref == alvo:
        return True

    capitulo = capitulo_da_referencia(alvo)
    if capitulo is not None and ref == capitulo:
        return True

    nome_livro = (livro or '').strip()
    if nome_livro and ref == nome_livro:
        return True

    return False


def recursos_aplicaveis(todos, referencia, livro=None):
    """Filtra, de ``todos``, os recursos aplicáveis a ``referencia`` (e ``livro``)."""
    return [r for r in todos if recurso_aplicavel(r, referencia, livro=livro)]


def filtrar_recursos(todos, tipo=None, livro=None):
    """Filtra recursos por ``tipo`` e/ou ``livro`` (vazios → sem filtro)."""
    t = (tipo or '').strip()
    l = (livro or '').strip()
    filtrados = []
    for recurso in todos:
        if t and recurso.tipo != t:
            continue
        if l and recurso.livro != l:
            continue
        filtrados.append(recurso)
    return filtrados


def tipos_disponiveis(todos):
    """Tipos presentes, em ordem determinística (conhecidos primeiro)."""
    vistos = set()
    ordem_aparicao = []
    for recurso in todos:
        tipo = recurso.tipo.strip()
        if not tipo:
            continue
        if tipo not in vistos:
            vistos.add(tipo)
            ordem_aparicao.append(tipo)

    conhecidos = [t for t in TIPOS_CONHECIDOS if t in vistos]
    desconhecidos = [t for t in ordem_aparicao if t not in TIPOS_CONHECIDOS]
    return conhecidos + desconhecidos


def livros_disponiveis(todos):
    """Livros presentes, ordenados alfabeticamente (determinismo)."""
    livros = set()
    for recurso in todos:
        livro = recurso.livro.strip()
        if livro:
            livros.add(livro)
    return sorted(livros)


def filtrar_por_busca(todos, busca):
    """Filtra por palavra-chave (sem caixa/acentos) contra título, corpo e temas."""
    termo = _normalizar_busca(busca)
    if not termo:
        return list(todos)

    encontrados = []
    for recurso in todos:
        alvo = _normalizar_busca(
            f'{recurso.titulo} {recurso.corpo} {" ".join(recurso.temas)}'
        )
        if termo in alvo:
            encontrados.append(recurso)
    return encontrados


def _normalizar_busca(texto: str) -> str:
    """Normaliza para busca: minúsculas e sem acentos (busca tolerante)."""
    texto = unicodedata.normalize('NFD', texto)
    texto = ''.join(c for c in texto if not unicodedata.combining(c))
    return texto.lower().strip()

