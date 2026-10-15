"""Contextualização histórica dos 150 Salmos (feature 003).

Porte 1:1 de ``lib/contexto_historico.dart`` — funções e classes puras (sem
I/O, sem Streamlit). Cobre os casos CTX1–CTX7 da matriz de QA.
"""

import re
import unicodedata
from enum import Enum

from .catalogo_estudos import FonteEstudo


class CertezaHistorica(Enum):
    documentado = 'documentado'
    tradicional = 'tradicional'
    hipotese = 'hipotese'
    indeterminado = 'indeterminado'


def certeza_de_codigo(codigo):
    """Converte o código textual do JSON no enum; desconhecido → indeterminado."""
    mapa = {
        'documentado': CertezaHistorica.documentado,
        'tradicional': CertezaHistorica.tradicional,
        'hipotese': CertezaHistorica.hipotese,
        'indeterminado': CertezaHistorica.indeterminado,
    }
    return mapa.get(codigo, CertezaHistorica.indeterminado)


def rotulo_certeza(certeza) -> str:
    """Rótulo curto do grau de certeza (exibido como selo)."""
    return {
        CertezaHistorica.documentado: 'Documentado no texto bíblico',
        CertezaHistorica.tradicional: 'Atribuição tradicional',
        CertezaHistorica.hipotese: 'Hipótese acadêmica',
        CertezaHistorica.indeterminado: 'Historicamente indeterminado',
    }[certeza]


def explicacao_certeza(certeza) -> str:
    """Descrição explicativa do grau de certeza."""
    return {
        CertezaHistorica.documentado:
            'Informação expressamente presente na narrativa ou no título do Salmo.',
        CertezaHistorica.tradicional:
            'Interpretação histórica ou autoria transmitida pela tradição judaico-cristã.',
        CertezaHistorica.hipotese:
            'Proposta de datação, autoria ou contexto discutida na pesquisa bíblica.',
        CertezaHistorica.indeterminado:
            'Não há elementos suficientes para estabelecer uma conclusão.',
    }[certeza]


class ReferenciaCruzada:
    def __init__(self, referencia='', tipo='', nota=''):
        self.referencia = referencia
        self.tipo = tipo
        self.nota = nota

    @property
    def tem_referencia(self) -> bool:
        return bool(self.referencia.strip())

    @property
    def tem_nota(self) -> bool:
        return bool(self.nota.strip())


class ContextoSalmo:
    def __init__(self, id, numero, titulo='', classificacao=None, autoria='',
                 origem_autoria='', autoria_incerta=False, periodo='',
                 periodo_retratado='', periodo_composicao='', contexto_politico='',
                 eventos=None, localizacao='', referencias_cruzadas=None,
                 certeza=CertezaHistorica.indeterminado, explicacao='',
                 fontes=None, temas=None, personagens=None, lugares=None):
        self.id = id
        self.numero = numero
        self.titulo = titulo
        self.classificacao = classificacao if classificacao is not None else []
        self.autoria = autoria
        self.origem_autoria = origem_autoria
        self.autoria_incerta = autoria_incerta
        self.periodo = periodo
        self.periodo_retratado = periodo_retratado
        self.periodo_composicao = periodo_composicao
        self.contexto_politico = contexto_politico
        self.eventos = eventos if eventos is not None else []
        self.localizacao = localizacao
        self.referencias_cruzadas = referencias_cruzadas if referencias_cruzadas is not None else []
        self.certeza = certeza
        self.explicacao = explicacao
        self.fontes = fontes if fontes is not None else []
        self.temas = temas if temas is not None else []
        self.personagens = personagens if personagens is not None else []
        self.lugares = lugares if lugares is not None else []

    @property
    def tem_titulo(self): return bool(self.titulo.strip())
    @property
    def tem_classificacao(self): return bool(self.classificacao)
    @property
    def tem_autoria(self): return bool(self.autoria.strip())
    @property
    def tem_origem_autoria(self): return bool(self.origem_autoria.strip())
    @property
    def tem_periodo(self): return bool(self.periodo.strip())
    @property
    def tem_periodo_retratado(self): return bool(self.periodo_retratado.strip())
    @property
    def tem_periodo_composicao(self): return bool(self.periodo_composicao.strip())
    @property
    def tem_contexto_politico(self): return bool(self.contexto_politico.strip())
    @property
    def tem_eventos(self): return bool(self.eventos)
    @property
    def tem_localizacao(self): return bool(self.localizacao.strip())
    @property
    def tem_referencias(self): return bool(self.referencias_cruzadas)
    @property
    def tem_explicacao(self): return bool(self.explicacao.strip())
    @property
    def tem_fontes(self): return bool(self.fontes)
    @property
    def tem_temas(self): return bool(self.temas)
    @property
    def tem_personagens(self): return bool(self.personagens)
    @property
    def tem_lugares(self): return bool(self.lugares)


class AlvoReferencia:
    def __init__(self, livro, capitulo=None, versiculo=None):
        self.livro = livro
        self.capitulo = capitulo
        self.versiculo = versiculo

    @property
    def navegavel(self) -> bool:
        return bool(self.livro) and self.capitulo is not None


def _texto(valor):
    return '' if valor is None else str(valor).strip()


def _inteiro(valor):
    try:
        return int(str(valor).strip())
    except (ValueError, TypeError):
        return 0


def _booleano(valor):
    # Dart: `valor == true` — sem coerção de tipos (1 == true é falso).
    return valor is True


def _int_ou_none(texto):
    try:
        return int(texto)
    except ValueError:
        return None


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


def _fontes(valor):
    if not isinstance(valor, list):
        return []
    fontes = []
    for item in valor:
        fonte = _fonte_de_mapa(item)
        if fonte is not None:
            fontes.append(fonte)
    return fontes


def _referencias(valor):
    if not isinstance(valor, list):
        return []
    referencias = []
    for item in valor:
        if not isinstance(item, dict):
            continue
        ref = ReferenciaCruzada(
            referencia=_texto(item.get('ref')),
            tipo=_texto(item.get('tipo')),
            nota=_texto(item.get('nota')),
        )
        if ref.tem_referencia:
            referencias.append(ref)
    return referencias


def contexto_salmo_de_mapa(valor):
    """Converte um item bruto em ``ContextoSalmo``; ``None`` para inválidos (CTX2)."""
    if not isinstance(valor, dict):
        return None
    id_ = _texto(valor.get('id'))
    numero = _inteiro(valor.get('salmo'))
    if not id_ or numero <= 0:
        return None

    return ContextoSalmo(
        id=id_,
        numero=numero,
        titulo=_texto(valor.get('titulo')),
        classificacao=_lista_de_texto(valor.get('classificacao')),
        autoria=_texto(valor.get('autoria')),
        origem_autoria=_texto(valor.get('origem_autoria')),
        autoria_incerta=_booleano(valor.get('autoria_incerta')),
        periodo=_texto(valor.get('periodo')),
        periodo_retratado=_texto(valor.get('periodo_retratado')),
        periodo_composicao=_texto(valor.get('periodo_composicao')),
        contexto_politico=_texto(valor.get('contexto_politico')),
        eventos=_lista_de_texto(valor.get('eventos')),
        localizacao=_texto(valor.get('localizacao')),
        referencias_cruzadas=_referencias(valor.get('referencias_cruzadas')),
        certeza=certeza_de_codigo(_texto(valor.get('certeza'))),
        explicacao=_texto(valor.get('explicacao')),
        fontes=_fontes(valor.get('fontes')),
        temas=_lista_de_texto(valor.get('temas')),
        personagens=_lista_de_texto(valor.get('personagens')),
        lugares=_lista_de_texto(valor.get('lugares')),
    )


def contextos_de_json(decodificado):
    """Converte lista bruta em contextos válidos; não-lista → lista vazia."""
    if not isinstance(decodificado, list):
        return []
    contextos = []
    for item in decodificado:
        contexto = contexto_salmo_de_mapa(item)
        if contexto is not None:
            contextos.append(contexto)
    return contextos


def contexto_do_salmo(todos, numero):
    """Devolve o contexto do Salmo ``numero``, ou ``None`` se não houver."""
    for contexto in todos:
        if contexto.numero == numero:
            return contexto
    return None


def _normalizar_busca(texto: str) -> str:
    texto = unicodedata.normalize('NFD', texto)
    texto = ''.join(c for c in texto if not unicodedata.combining(c))
    return texto.lower().strip()


def filtrar_contexto_por_busca(todos, busca):
    """Filtra por palavra-chave (sem caixa/acentos) contra os campos do contexto."""
    termo = _normalizar_busca(busca)
    if not termo:
        return list(todos)

    encontrados = []
    for contexto in todos:
        alvo = _normalizar_busca(
            f'salmo {contexto.numero} {contexto.titulo} {contexto.autoria} '
            f'{contexto.periodo} {contexto.periodo_retratado} '
            f'{contexto.periodo_composicao} {contexto.contexto_politico} '
            f'{" ".join(contexto.eventos)} {contexto.localizacao} '
            f'{contexto.explicacao} {" ".join(contexto.temas)} '
            f'{" ".join(contexto.personagens)} {" ".join(contexto.lugares)}'
        )
        if termo in alvo:
            encontrados.append(contexto)
    return encontrados


def analisar_referencia(referencia, nomes_livros):
    """Extrai livro/capítulo/versículo de uma referência (nome mais longo primeiro)."""
    ref = referencia.strip()
    if not ref:
        return None

    nomes = sorted(
        (n.strip() for n in nomes_livros if n.strip()),
        key=len,
        reverse=True,
    )

    for nome in nomes:
        if ref == nome:
            return AlvoReferencia(livro=nome)
        if not ref.startswith(nome + ' '):
            continue

        resto = ref[len(nome):].strip()

        versiculo_match = re.match(r'^(\d{1,3}):(\d{1,3})', resto)
        if versiculo_match:
            return AlvoReferencia(
                livro=nome,
                capitulo=_int_ou_none(versiculo_match.group(1)),
                versiculo=_int_ou_none(versiculo_match.group(2)),
            )

        capitulo_match = re.match(r'^(\d{1,3})', resto)
        if capitulo_match:
            return AlvoReferencia(
                livro=nome,
                capitulo=_int_ou_none(capitulo_match.group(1)),
            )

        return AlvoReferencia(livro=nome)

    return None


