"""Base de dados histórica: pessoas, lugares e cronologia cruzados com versículos.

Fonte dos dados (gratuita, aberta, offline-first):

    https://github.com/robertrouse/theographic-bible-metadata  (CC BY-SA 4.0)

O repositório Theographic liga *todos os versículos* da King James Version
(KJV, 66 livros / 1.189 capítulos / 31.102 versículos) às pessoas (3.067),
aos lugares (1.298), aos eventos/cronologia (450, segundo Dr. Floyd Nolen
Jones) e a grupos de pessoas (23), além do dicionário Easton (6.519).

Este módulo é **puro** (apenas a biblioteca padrão do Python: ``sqlite3``,
``json``, ``os``, ``unicodedata``). Ele:

1. Converte os JSONs brutos do Theographic em um banco SQLite normalizado.
2. Cruza cada versículo com pessoas, lugares, eventos e grupos por meio de
   tabelas de junção indexadas.
3. Oferece funções de consulta para o cruzamento em tempo de leitura.

Como o canon protestante local (``assets/data/indice.json``) tem os mesmos
66 livros, na mesma ordem, o vínculo é feito por **número** de livro,
capítulo e versículo — independente do idioma (a Bíblia local é em
português; os nomes do Theographic seguem o KJV, em inglês).

Convenção de ``verse_id`` (inteiro estável e decodificável)::

    verse_id = livro * 1_000_000 + capítulo * 1_000 + versículo

Ex.: João 3:16 -> 43*1e6 + 3*1e3 + 16 = 43.003.016.

Datas seguem o ISO 8601 astronômico do Theographic (``-4003`` = 4004 a.C.;
``0`` = 1 a.C.; ``30`` = 30 d.C.). Ver ``rotulo_ano``.
"""

import json
import os
import sqlite3
import unicodedata

# ---------------------------------------------------------------------------
# Identificadores e referências
# ---------------------------------------------------------------------------

MULT_BOOK = 1_000_000
MULT_CHAPTER = 1_000


def versiculo_id(livro, capitulo, versiculo):
    """Codifica livro/capítulo/versículo num inteiro estável e decodificável."""
    return int(livro) * MULT_BOOK + int(capitulo) * MULT_CHAPTER + int(versiculo)


def decodificar_versiculo_id(verse_id):
    """Devolve ``(livro, capitulo, versiculo)`` a partir de ``verse_id``."""
    verse_id = int(verse_id)
    livro = verse_id // MULT_BOOK
    resto = verse_id % MULT_BOOK
    capitulo = resto // MULT_CHAPTER
    versiculo = resto % MULT_CHAPTER
    return livro, capitulo, versiculo


def referencia_versiculo(nome_livro, capitulo, versiculo):
    """Referência legível no formato do aplicativo: ``"João 3:16"``."""
    return f"{nome_livro} {capitulo}:{versiculo}"


def referencia_capitulo(nome_livro, capitulo):
    """Referência de capítulo: ``"João 3"``."""
    return f"{nome_livro} {capitulo}"


def rotulo_ano(ano):
    """Converte um ano ISO astronômico em rótulo ``"4004 a.C."`` / ``"30 d.C."``.

    ``None`` (sem data) é devolvido como ``None``.
    """
    if ano is None:
        return None
    try:
        ano = int(ano)
    except (TypeError, ValueError):
        return str(ano)
    if ano <= 0:
        return f"{1 - ano} a.C."
    return f"{ano} d.C."


def _slug(nome):
    """Versão url-friendly (sem acentos) de um nome, para índices/busca."""
    normalizado = unicodedata.normalize("NFD", str(nome or ""))
    normalizado = "".join(c for c in normalizado if not unicodedata.combining(c))
    normalizado = normalizado.lower()
    return "".join(c if c.isalnum() else "_" for c in normalizado).strip("_")


def _como_int(valor):
    """Converte valores int/str/float (incl. negativos) em ``int`` ou ``None``."""
    if valor is None:
        return None
    if isinstance(valor, bool):
        return 1 if valor else 0
    try:
        if isinstance(valor, float):
            return int(valor)
        return int(str(valor).strip())
    except (ValueError, TypeError):
        return None


def _como_real(valor):
    """Converte valores numéricos (ou strings) em ``float`` ou ``None``."""
    if valor is None:
        return None
    try:
        return float(valor)
    except (ValueError, TypeError):
        return None


def _carregar_json(caminho):
    """Lê um arquivo JSON aceitando BOM (utf-8-sig)."""
    with open(caminho, encoding="utf-8-sig") as f:
        return json.load(f)

# ---------------------------------------------------------------------------
# Mapeamento de livros
# ---------------------------------------------------------------------------

def mapear_livros(indice_local, livros_theographic):
    """Cruza o índice local (nomes PT, em ordem) com os livros do Theographic.

    Retorna ``(livro_por_ordem, osis_para_ordem, record_para_livro,
    capitulos_locais)``:

    - ``livro_por_ordem``: ``{ordem: {osis_name, book_name, local_name,
      testament, chapter_count, verse_count}}``;
    - ``osis_para_ordem``: ``{osisName minúsculo: ordem}``;
    - ``record_para_livro``: ``{id Airtable do livro: ordem}``;
    - ``capitulos_locais``: ``{ordem: nº de capítulos na Bíblia local}``.
    """
    nomes_locais = [str(item.get("nome", "")).strip()
                    for item in indice_local if isinstance(item, dict)]
    caps_locais = [_como_int(item.get("capitulos"))
                   for item in indice_local if isinstance(item, dict)]

    livro_por_ordem = {}
    osis_para_ordem = {}
    record_para_livro = {}
    capitulos_locais = {}

    for rec in livros_theographic:
        if not isinstance(rec, dict):
            continue
        f = rec.get("fields") or {}
        ordem = _como_int(f.get("bookOrder"))
        if ordem is None or ordem < 1:
            continue
        osis = f.get("osisName")
        local_name = nomes_locais[ordem - 1] if 0 <= ordem - 1 < len(nomes_locais) \
            else f.get("bookName")
        livro_por_ordem[ordem] = {
            "osis_name": osis,
            "book_name": f.get("bookName"),
            "local_name": local_name,
            "testament": f.get("testament"),
            "chapter_count": _como_int(f.get("chapterCount")),
            "verse_count": _como_int(f.get("verseCount")),
        }
        if osis:
            osis_para_ordem[str(osis).lower()] = ordem
        record_para_livro[rec.get("id")] = ordem
        if 0 <= ordem - 1 < len(caps_locais):
            capitulos_locais[ordem] = caps_locais[ordem - 1]

    return livro_por_ordem, osis_para_ordem, record_para_livro, capitulos_locais


# ---------------------------------------------------------------------------
# Conversão das tabelas do Theographic em linhas normalizadas
# ---------------------------------------------------------------------------

def _lista_ids(array, record_map):
    """Traduz um array de ids Airtable em pks mapeados (ignora desconhecidos)."""
    if not isinstance(array, list):
        return []
    saida = []
    for x in array:
        if x in record_map:
            saida.append(record_map[x])
    return saida


def _proximo_livre(usados):
    """Próximo id inteiro livre, usado quando a fonte não tem id numérico."""
    candidato = (max(usados) + 1) if usados else 1
    while candidato in usados:
        candidato += 1
    return candidato


def _registros_pessoas(pessoas_tg):
    record_para_pessoa = {}
    linhas = []
    usados = set()
    for rec in pessoas_tg:
        if not isinstance(rec, dict):
            continue
        f = rec.get("fields") or {}
        pid = _como_int(f.get("personID"))
        if pid is None or pid in usados:
            pid = _proximo_livre(usados)
        usados.add(pid)
        record_para_pessoa[rec.get("id")] = pid
        linhas.append((
            pid,
            f.get("personLookup"),
            f.get("name"),
            f.get("displayTitle"),
            f.get("gender"),
            1 if f.get("isProperName") else 0,
            _como_int(f.get("birthYear")),
            _como_int(f.get("deathYear")),
            _como_int(f.get("minYear")),
            _como_int(f.get("maxYear")),
            _como_int(f.get("verseCount")),
            f.get("slug"),
        ))
    return record_para_pessoa, linhas

def _registros_lugares(lugares_tg):
    record_para_lugar = {}
    linhas = []
    usados = set()
    for rec in lugares_tg:
        if not isinstance(rec, dict):
            continue
        f = rec.get("fields") or {}
        pid = _como_int(f.get("placeID"))
        if pid is None or pid in usados:
            pid = _proximo_livre(usados)
        usados.add(pid)
        record_para_lugar[rec.get("id")] = pid
        linhas.append((
            pid,
            f.get("placeLookup"),
            f.get("kjvName"),
            f.get("displayTitle"),
            _como_real(f.get("latitude")),
            _como_real(f.get("longitude")),
            f.get("featureType"),
            f.get("featureSubType"),
            _como_int(f.get("verseCount")),
            f.get("slug"),
        ))
    return record_para_lugar, linhas


def _registros_eventos(eventos_tg):
    record_para_evento = {}
    linhas = []
    usados = set()
    for rec in eventos_tg:
        if not isinstance(rec, dict):
            continue
        f = rec.get("fields") or {}
        eid = _como_int(f.get("eventID"))
        if eid is None or eid in usados:
            eid = _proximo_livre(usados)
        usados.add(eid)
        record_para_evento[rec.get("id")] = eid
        predecessor = f.get("predecessor") or []
        part_of = f.get("partOf") or []
        linhas.append((
            eid,
            f.get("title"),
            f.get("startDate"),
            f.get("duration"),
            _como_real(f.get("sortKey")),
            1 if f.get("rangeFlag") else 0,
            predecessor[0] if isinstance(predecessor, list) and predecessor else None,
            part_of[0] if isinstance(part_of, list) and part_of else None,
            f.get("verseSort"),
        ))
    # Segunda passada: resolve predecessor/partOf (ids Airtable) para event_id.
    for i, linha in enumerate(linhas):
        linhas[i] = (
            linha[0], linha[1], linha[2], linha[3], linha[4], linha[5],
            record_para_evento.get(linha[6]),
            record_para_evento.get(linha[7]),
            linha[8],
        )
    return record_para_evento, linhas


def _registros_grupos(grupos_tg):
    record_para_grupo = {}
    linhas = []
    gid = 1
    for rec in grupos_tg:
        if not isinstance(rec, dict):
            continue
        f = rec.get("fields") or {}
        record_para_grupo[rec.get("id")] = gid
        nome = f.get("groupName")
        linhas.append((gid, nome, _slug(nome)))
        gid += 1
    return record_para_grupo, linhas


def _registros_easton(easton_tg):
    linhas = []
    usados = set()
    for rec in easton_tg:
        if not isinstance(rec, dict):
            continue
        f = rec.get("fields") or {}
        idx = _como_int(f.get("index"))
        if idx is None or idx in usados:
            idx = _proximo_livre(usados)
        usados.add(idx)
        linhas.append((idx, f.get("dictLookup"), f.get("termLabel"), f.get("dictText")))
    return linhas


def _ordem_capitulo_de_ref(ref, osis_para_ordem):
    """Extrai ``(ordem_do_livro, capítulo)`` de um osisRef tipo ``"Gen.1"``."""
    if not isinstance(ref, str):
        return None, None
    partes = ref.split(".")
    ordem = osis_para_ordem.get(partes[0].lower()) if partes else None
    cap = _como_int(partes[1]) if len(partes) >= 2 else None
    return ordem, cap


def _extrair_ref_versiculo(f, osis_para_ordem):
    """Devolve ``(livro, capitulo, versiculo)`` de um versículo Theographic.

    Prefere o ``verseID`` (``"01002008"`` = BBCCCVVV) e cai para o ``osisRef``.
    """
    vid = f.get("verseID")
    if isinstance(vid, str) and len(vid) == 8 and vid.isdigit():
        return int(vid[0:2]), int(vid[2:5]), int(vid[5:8])
    ref = f.get("osisRef")
    if isinstance(ref, str):
        partes = ref.split(".")
        if len(partes) >= 3:
            ordem = osis_para_ordem.get(partes[0].lower())
            cap = _como_int(partes[1])
            vers = _como_int(partes[2])
            if ordem is not None and cap is not None and vers is not None:
                return ordem, cap, vers
    return None, None, None

# ---------------------------------------------------------------------------
# Schema (DDL + índices)
# ---------------------------------------------------------------------------

ESQUEMA = [
    """CREATE TABLE IF NOT EXISTS books (
        book_order    INTEGER PRIMARY KEY,
        osis_name     TEXT,
        book_name     TEXT,
        local_name    TEXT,
        testament     TEXT,
        chapter_count INTEGER,
        verse_count   INTEGER
    )""",
    """CREATE TABLE IF NOT EXISTS chapters (
        chapter_id    INTEGER PRIMARY KEY,
        book_order    INTEGER NOT NULL,
        chapter       INTEGER NOT NULL,
        chapter_ref   TEXT NOT NULL,
        people_count  INTEGER,
        places_count  INTEGER
    )""",
    """CREATE TABLE IF NOT EXISTS verse_metadata (
        verse_id        INTEGER PRIMARY KEY,
        book_order      INTEGER NOT NULL,
        chapter         INTEGER NOT NULL,
        verse           INTEGER NOT NULL,
        osis_ref        TEXT,
        verse_reference TEXT NOT NULL,
        year            INTEGER,
        people_count    INTEGER,
        places_count    INTEGER,
        text_kjv        TEXT
    )""",
    """CREATE TABLE IF NOT EXISTS people (
        person_id      INTEGER PRIMARY KEY,
        person_lookup  TEXT,
        name           TEXT,
        display_title  TEXT,
        gender         TEXT,
        is_proper_name INTEGER,
        birth_year     INTEGER,
        death_year     INTEGER,
        min_year       INTEGER,
        max_year       INTEGER,
        verse_count    INTEGER,
        slug           TEXT
    )""",
    """CREATE TABLE IF NOT EXISTS places (
        place_id         INTEGER PRIMARY KEY,
        place_lookup     TEXT,
        name             TEXT,
        display_title    TEXT,
        latitude         REAL,
        longitude        REAL,
        feature_type     TEXT,
        feature_sub_type TEXT,
        verse_count      INTEGER,
        slug             TEXT
    )""",
    """CREATE TABLE IF NOT EXISTS events (
        event_id       INTEGER PRIMARY KEY,
        title          TEXT,
        start_date     TEXT,
        duration       TEXT,
        sort_key       REAL,
        range_flag     INTEGER,
        predecessor_id INTEGER,
        part_of_id     INTEGER,
        verse_sort     TEXT
    )""",
    """CREATE TABLE IF NOT EXISTS people_groups (
        group_id   INTEGER PRIMARY KEY,
        group_name TEXT,
        slug       TEXT
    )""",
    """CREATE TABLE IF NOT EXISTS easton (
        easton_id   INTEGER PRIMARY KEY,
        dict_lookup TEXT,
        term_label  TEXT,
        dict_text   TEXT
    )""",
    """CREATE TABLE IF NOT EXISTS verse_people (
        verse_id  INTEGER NOT NULL REFERENCES verse_metadata(verse_id),
        person_id INTEGER NOT NULL REFERENCES people(person_id),
        PRIMARY KEY (verse_id, person_id)
    )""",
    """CREATE TABLE IF NOT EXISTS verse_places (
        verse_id INTEGER NOT NULL REFERENCES verse_metadata(verse_id),
        place_id INTEGER NOT NULL REFERENCES places(place_id),
        PRIMARY KEY (verse_id, place_id)
    )""",
    """CREATE TABLE IF NOT EXISTS verse_events (
        verse_id INTEGER NOT NULL REFERENCES verse_metadata(verse_id),
        event_id INTEGER NOT NULL REFERENCES events(event_id),
        PRIMARY KEY (verse_id, event_id)
    )""",
    """CREATE TABLE IF NOT EXISTS verse_people_groups (
        verse_id INTEGER NOT NULL REFERENCES verse_metadata(verse_id),
        group_id INTEGER NOT NULL REFERENCES people_groups(group_id),
        PRIMARY KEY (verse_id, group_id)
    )""",
    """CREATE TABLE IF NOT EXISTS event_participants (
        event_id  INTEGER NOT NULL REFERENCES events(event_id),
        person_id INTEGER NOT NULL REFERENCES people(person_id),
        PRIMARY KEY (event_id, person_id)
    )""",
    """CREATE TABLE IF NOT EXISTS event_locations (
        event_id INTEGER NOT NULL REFERENCES events(event_id),
        place_id INTEGER NOT NULL REFERENCES places(place_id),
        PRIMARY KEY (event_id, place_id)
    )""",
]

INDICES = [
    # Índices pedidos na especificação do cruzamento em tempo de leitura.
    "CREATE INDEX IF NOT EXISTS idx_verse_metadata_ref ON verse_metadata(verse_reference)",
    "CREATE INDEX IF NOT EXISTS idx_verse_people_verse ON verse_people(verse_id)",
    "CREATE INDEX IF NOT EXISTS idx_verse_places_verse ON verse_places(verse_id)",
    # Índices de apoio para o sentido inverso e varreduras por intervalo.
    "CREATE INDEX IF NOT EXISTS idx_verse_metadata_intervalo ON verse_metadata(book_order, chapter, verse)",
    "CREATE INDEX IF NOT EXISTS idx_verse_metadata_ano ON verse_metadata(year)",
    "CREATE INDEX IF NOT EXISTS idx_verse_people_pessoa ON verse_people(person_id)",
    "CREATE INDEX IF NOT EXISTS idx_verse_places_lugar ON verse_places(place_id)",
    "CREATE INDEX IF NOT EXISTS idx_verse_events_verso ON verse_events(verse_id)",
    "CREATE INDEX IF NOT EXISTS idx_verse_events_evento ON verse_events(event_id)",
    "CREATE INDEX IF NOT EXISTS idx_verse_groups_grupo ON verse_people_groups(group_id)",
    "CREATE INDEX IF NOT EXISTS idx_eventos_ordem ON events(sort_key)",
    "CREATE INDEX IF NOT EXISTS idx_pessoas_lookup ON people(person_lookup)",
    "CREATE INDEX IF NOT EXISTS idx_pessoas_nome ON people(name)",
    "CREATE INDEX IF NOT EXISTS idx_lugares_lookup ON places(place_lookup)",
    "CREATE INDEX IF NOT EXISTS idx_lugares_nome ON places(name)",
]

# ---------------------------------------------------------------------------
# Construção do banco
# ---------------------------------------------------------------------------

def construir_banco(raw_dir, indice_path, db_path):
    """Constrói (ou reconstrói) o SQLite a partir dos JSONs brutos.

    ``raw_dir`` deve conter os arquivos ``books.json``, ``chapters.json``,
    ``verses.json``, ``people.json``, ``places.json``, ``events.json``,
    ``peopleGroups.json`` e ``easton.json`` (baixados do repositório).

    Retorna um dicionário com as contagens gravadas, para o relatório.
    """
    indice_local = _carregar_json(indice_path)
    livros_tg = _carregar_json(os.path.join(raw_dir, "books.json"))
    capitulos_tg = _carregar_json(os.path.join(raw_dir, "chapters.json"))
    versos_tg = _carregar_json(os.path.join(raw_dir, "verses.json"))
    pessoas_tg = _carregar_json(os.path.join(raw_dir, "people.json"))
    lugares_tg = _carregar_json(os.path.join(raw_dir, "places.json"))
    eventos_tg = _carregar_json(os.path.join(raw_dir, "events.json"))
    grupos_tg = _carregar_json(os.path.join(raw_dir, "peopleGroups.json"))
    easton_tg = _carregar_json(os.path.join(raw_dir, "easton.json"))

    livro_por_ordem, osis_para_ordem, record_para_livro, capitulos_locais = \
        mapear_livros(indice_local, livros_tg)

    record_para_pessoa, pessoas = _registros_pessoas(pessoas_tg)
    record_para_lugar, lugares = _registros_lugares(lugares_tg)
    record_para_evento, eventos = _registros_eventos(eventos_tg)
    record_para_grupo, grupos = _registros_grupos(grupos_tg)
    easton = _registros_easton(easton_tg)

    # Livros.
    livros_linhas = []
    for ordem in sorted(livro_por_ordem):
        meta = livro_por_ordem[ordem]
        livros_linhas.append((
            ordem, meta["osis_name"], meta["book_name"], meta["local_name"],
            meta["testament"], meta["chapter_count"], meta["verse_count"],
        ))

    # Capítulos.
    capitulos_linhas = []
    vistos_cap = set()
    for rec in capitulos_tg:
        if not isinstance(rec, dict):
            continue
        f = rec.get("fields") or {}
        ordem, cap = _ordem_capitulo_de_ref(f.get("osisRef"), osis_para_ordem)
        if ordem is None:
            link = f.get("book")
            ordem = record_para_livro.get(link[0]) if isinstance(link, list) and link else None
        if ordem is None or cap is None:
            continue
        chave = (ordem, cap)
        if chave in vistos_cap:
            continue
        vistos_cap.add(chave)
        nome_livro = livro_por_ordem.get(ordem, {}).get("local_name") or ""
        capitulos_linhas.append((
            ordem * MULT_CHAPTER + cap,
            ordem,
            cap,
            referencia_capitulo(nome_livro, cap),
            _como_int(f.get("peopleCount")),
            _como_int(f.get("placesCount")),
        ))

    # Versículos + junções.
    versos_linhas = []
    vp = []
    vl = []
    vg = []
    ve = []
    for rec in versos_tg:
        if not isinstance(rec, dict):
            continue
        f = rec.get("fields") or {}
        ordem, cap, vers = _extrair_ref_versiculo(f, osis_para_ordem)
        if ordem is None:
            continue
        vid = versiculo_id(ordem, cap, vers)
        nome_livro = livro_por_ordem.get(ordem, {}).get("local_name") or ""
        versos_linhas.append((
            vid,
            ordem,
            cap,
            vers,
            f.get("osisRef"),
            referencia_versiculo(nome_livro, cap, vers),
            _como_int(f.get("yearNum")),
            _como_int(f.get("peopleCount")),
            _como_int(f.get("placesCount")),
            f.get("verseText"),
        ))
        for pid in _lista_ids(f.get("people"), record_para_pessoa):
            vp.append((vid, pid))
        for lid in _lista_ids(f.get("places"), record_para_lugar):
            vl.append((vid, lid))
        for gid in _lista_ids(f.get("peopleGroups"), record_para_grupo):
            vg.append((vid, gid))
        for eid in _lista_ids(f.get("event"), record_para_evento):
            ve.append((vid, eid))

    # Participantes e locais dos eventos.
    ev_participantes = []
    ev_locais = []
    for rec in eventos_tg:
        if not isinstance(rec, dict):
            continue
        f = rec.get("fields") or {}
        eid = record_para_evento.get(rec.get("id"))
        if eid is None:
            continue
        for pid in _lista_ids(f.get("participants"), record_para_pessoa):
            ev_participantes.append((eid, pid))
        for lid in _lista_ids(f.get("locations"), record_para_lugar):
            ev_locais.append((eid, lid))

    # Gravação.
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    try:
        for stmt in ESQUEMA + INDICES:
            conn.execute(stmt)
        conn.executemany(
            "INSERT OR REPLACE INTO books VALUES (?,?,?,?,?,?,?)", livros_linhas)
        conn.executemany(
            "INSERT OR REPLACE INTO chapters VALUES (?,?,?,?,?,?)", capitulos_linhas)
        conn.executemany(
            "INSERT OR REPLACE INTO verse_metadata VALUES (?,?,?,?,?,?,?,?,?,?)",
            versos_linhas)
        conn.executemany(
            "INSERT OR REPLACE INTO people VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", pessoas)
        conn.executemany(
            "INSERT OR REPLACE INTO places VALUES (?,?,?,?,?,?,?,?,?,?)", lugares)
        conn.executemany(
            "INSERT OR REPLACE INTO events VALUES (?,?,?,?,?,?,?,?,?)", eventos)
        conn.executemany(
            "INSERT OR REPLACE INTO people_groups VALUES (?,?,?)", grupos)
        conn.executemany(
            "INSERT OR REPLACE INTO easton VALUES (?,?,?,?)", easton)
        conn.executemany("INSERT OR IGNORE INTO verse_people VALUES (?,?)", vp)
        conn.executemany("INSERT OR IGNORE INTO verse_places VALUES (?,?)", vl)
        conn.executemany("INSERT OR IGNORE INTO verse_people_groups VALUES (?,?)", vg)
        conn.executemany("INSERT OR IGNORE INTO verse_events VALUES (?,?)", ve)
        conn.executemany("INSERT OR IGNORE INTO event_participants VALUES (?,?)", ev_participantes)
        conn.executemany("INSERT OR IGNORE INTO event_locations VALUES (?,?)", ev_locais)
        conn.commit()
    finally:
        conn.close()

    return {
        "livros": len(livros_linhas),
        "capitulos": len(capitulos_linhas),
        "versiculos": len(versos_linhas),
        "pessoas": len(pessoas),
        "lugares": len(lugares),
        "eventos": len(eventos),
        "grupos": len(grupos),
        "easton": len(easton),
        "verse_people": len(vp),
        "verse_places": len(vl),
        "verse_events": len(ve),
        "verse_groups": len(vg),
        "event_participants": len(ev_participantes),
        "event_locations": len(ev_locais),
        "capitulos_locais": capitulos_locais,
        "livro_por_ordem": livro_por_ordem,
    }

# ---------------------------------------------------------------------------
# Consultas (cruzamento em tempo de leitura)
# ---------------------------------------------------------------------------

def abrir_banco(db_path):
    """Abre o banco com ``row_factory`` para acesso por nome de coluna."""
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def buscar_versiculo_por_referencia(conn, referencia):
    """Devolve a linha de ``verse_metadata`` de uma referência (ex. ``"João 3:16"``)."""
    return conn.execute(
        "SELECT * FROM verse_metadata WHERE verse_reference = ?",
        (referencia,)).fetchone()


def pessoas_do_versiculo(conn, verse_id):
    """Pessoas mencionadas em um versículo (ordenadas por nome)."""
    return conn.execute(
        "SELECT p.* FROM verse_people vp "
        "JOIN people p ON p.person_id = vp.person_id "
        "WHERE vp.verse_id = ? ORDER BY p.name", (verse_id,)).fetchall()


def lugares_do_versiculo(conn, verse_id):
    """Lugares mencionados em um versículo (ordenados por nome)."""
    return conn.execute(
        "SELECT p.* FROM verse_places vp "
        "JOIN places p ON p.place_id = vp.place_id "
        "WHERE vp.verse_id = ? ORDER BY p.name", (verse_id,)).fetchall()


def eventos_do_versiculo(conn, verse_id):
    """Eventos (cronologia) associados a um versículo, em ordem cronológica."""
    return conn.execute(
        "SELECT e.* FROM verse_events ve "
        "JOIN events e ON e.event_id = ve.event_id "
        "WHERE ve.verse_id = ? ORDER BY e.sort_key", (verse_id,)).fetchall()


def grupos_do_versiculo(conn, verse_id):
    """Grupos de pessoas mencionados em um versículo."""
    return conn.execute(
        "SELECT g.* FROM verse_people_groups vg "
        "JOIN people_groups g ON g.group_id = vg.group_id "
        "WHERE vg.verse_id = ? ORDER BY g.group_name", (verse_id,)).fetchall()


def versiculos_da_pessoa(conn, person_id, limite=50):
    """Versículos (ordenados) em que uma pessoa é mencionada."""
    return conn.execute(
        "SELECT vm.* FROM verse_people vp "
        "JOIN verse_metadata vm ON vm.verse_id = vp.verse_id "
        "WHERE vp.person_id = ? ORDER BY vm.verse_id LIMIT ?",
        (person_id, limite)).fetchall()


def versiculos_do_lugar(conn, place_id, limite=50):
    """Versículos (ordenados) em que um lugar é mencionado."""
    return conn.execute(
        "SELECT vm.* FROM verse_places vp "
        "JOIN verse_metadata vm ON vm.verse_id = vp.verse_id "
        "WHERE vp.place_id = ? ORDER BY vm.verse_id LIMIT ?",
        (place_id, limite)).fetchall()


def encontrar_pessoa(conn, nome):
    """Procura uma pessoa por ``name`` ou ``person_lookup`` (sem caixa)."""
    return conn.execute(
        "SELECT * FROM people WHERE lower(name) = lower(?) "
        "OR lower(person_lookup) = lower(?) LIMIT 1",
        (nome, nome)).fetchone()


def encontrar_lugar(conn, nome):
    """Procura um lugar por ``name`` ou ``place_lookup`` (sem caixa)."""
    return conn.execute(
        "SELECT * FROM places WHERE lower(name) = lower(?) "
        "OR lower(place_lookup) = lower(?) LIMIT 1",
        (nome, nome)).fetchone()


def cronologia(conn, limite=None):
    """Eventos da cronologia (Jones), em ordem cronológica."""
    sql = "SELECT * FROM events ORDER BY sort_key IS NULL, sort_key, event_id"
    if limite:
        sql += f" LIMIT {int(limite)}"
    return conn.execute(sql).fetchall()


def pessoas_de_um_livro(conn, book_order):
    """Pessoas distintas mencionadas em um livro (por ordem de livro)."""
    return conn.execute(
        "SELECT DISTINCT p.* FROM verse_people vp "
        "JOIN verse_metadata vm ON vm.verse_id = vp.verse_id "
        "JOIN people p ON p.person_id = vp.person_id "
        "WHERE vm.book_order = ? ORDER BY p.name", (book_order,)).fetchall()


def listar_pessoas(conn, limite=None):
    """Pessoas em ordem de relevância (verse_count desc, depois nome)."""
    sql = "SELECT * FROM people ORDER BY verse_count DESC, name"
    if limite:
        sql += f" LIMIT {int(limite)}"
    return conn.execute(sql).fetchall()


def listar_lugares(conn, limite=None):
    """Lugares em ordem de relevância (verse_count desc, depois nome)."""
    sql = "SELECT * FROM places ORDER BY verse_count DESC, name"
    if limite:
        sql += f" LIMIT {int(limite)}"
    return conn.execute(sql).fetchall()


def buscar_easton(conn, termo):
    """Verbete do dicionário Easton por ``term_label`` ou ``dict_lookup``."""
    return conn.execute(
        "SELECT * FROM easton WHERE lower(term_label) = lower(?) "
        "OR lower(dict_lookup) = lower(?) LIMIT 1",
        (termo, termo)).fetchone()


def sugerir_easton(conn, termo, limite=20):
    """Verbetes cujo termo contém ``termo`` (sem caixa), para sugestões.

    Deduplicado por ``term_label`` (o Theographic tem pessoas homônimas com
    verbetes repetidos).
    """
    return conn.execute(
        "SELECT MIN(easton_id) AS easton_id, term_label, "
        "MIN(dict_lookup) AS dict_lookup FROM easton "
        "WHERE lower(term_label) LIKE lower(?) "
        "GROUP BY term_label ORDER BY term_label LIMIT ?",
        (f"%{termo}%", int(limite))).fetchall()


