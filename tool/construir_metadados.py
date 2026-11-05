# -*- coding: utf-8 -*-
"""Constrói e consulta a base de dados histórica (SQLite) do aplicativo.

Fonte gratuita e aberta (offline-first):

    https://github.com/robertrouse/theographic-bible-metadata  (CC BY-SA 4.0)

Este script baixa os JSONs brutos do repositório Theographic, processa-os e
popula um banco SQLite local com o cruzamento de versículos × pessoas ×
lugares × cronologia. Depois de construído, o banco pode ser consultado sem
conexão (``--consulta``, ``--pessoa``, ``--lugar``, ``--cronologia``).

Apenas a biblioteca padrão do Python é usada (``urllib``, ``json``,
``sqlite3``). O mapeamento de versículos usa a mesma ordem de 66 livros do
canon protestante local (``assets/data/indice.json``) e do KJV.

Uso:
    python tool/construir_metadados.py                 # baixa (1ª vez) e constrói
    python tool/construir_metadados.py --atualizar     # força novo download
    python tool/construir_metadados.py --consulta "João 3:16"
    python tool/construir_metadados.py --pessoa "David"
    python tool/construir_metadados.py --lugar "Jerusalem"
    python tool/construir_metadados.py --cronologia 10
    python tool/construir_metadados.py --resumo
"""
import argparse
import os
import shutil
import sys
import urllib.request

# Importa o módulo core (puro) a partir de webapp/core.
_WEBAPP = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "webapp")
if _WEBAPP not in sys.path:
    sys.path.insert(0, _WEBAPP)

from core import metadados_biblia as md  # noqa: E402

BASE_URL = "https://raw.githubusercontent.com/robertrouse/theographic-bible-metadata/master/json/"
ARQUIVOS = ["books", "chapters", "verses", "people", "places", "events", "peopleGroups", "easton"]


def raiz_projeto():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def diretorio_dados():
    override = os.environ.get("BIBLIA_METADADOS_DIR")
    if override:
        return os.path.abspath(override)
    return os.path.join(raiz_projeto(), "tool", "theographic")


def caminho_raw():
    return os.path.join(diretorio_dados(), "raw")


def caminho_db():
    return os.path.join(diretorio_dados(), "biblia_metadados.db")


def baixar(url, destino):
    req = urllib.request.Request(url, headers={"User-Agent": "biblia-diaria-metadados/1.0"})
    with urllib.request.urlopen(req, timeout=300) as resposta, open(destino, "wb") as f:
        shutil.copyfileobj(resposta, f)


def garantir_brutos(atualizar=False):
    raw = caminho_raw()
    os.makedirs(raw, exist_ok=True)
    for nome in ARQUIVOS:
        destino = os.path.join(raw, f"{nome}.json")
        if atualizar or not os.path.isfile(destino) or os.path.getsize(destino) == 0:
            print(f"  baixando {nome}.json ...", flush=True)
            baixar(BASE_URL + nome + ".json", destino)
    return raw


def construir(atualizar=False):
    raw = garantir_brutos(atualizar)
    indice = os.path.join(raiz_projeto(), "assets", "data", "indice.json")
    if not os.path.isfile(indice):
        print("[ERRO] Índice local não encontrado:", indice)
        sys.exit(1)
    return md.construir_banco(raw, indice, caminho_db())

def relatar(rel):
    linha = "-" * 66
    print(linha)
    print("BASE DE DADOS HISTÓRICA (Theographic) — construída com sucesso")
    print(linha)
    print(f"  Livros:      {rel['livros']:>6}")
    print(f"  Capítulos:   {rel['capitulos']:>6}")
    print(f"  Versículos:  {rel['versiculos']:>6}")
    print(f"  Pessoas:     {rel['pessoas']:>6}")
    print(f"  Lugares:     {rel['lugares']:>6}")
    print(f"  Eventos:     {rel['eventos']:>6}   (cronologia de Jones)")
    print(f"  Grupos:      {rel['grupos']:>6}")
    print(f"  Easton:      {rel['easton']:>6}")
    print(linha)
    print("Junções (cruzamento em tempo de leitura):")
    print(f"  verse_people:       {rel['verse_people']:>6}")
    print(f"  verse_places:       {rel['verse_places']:>6}")
    print(f"  verse_events:       {rel['verse_events']:>6}")
    print(f"  verse_groups:       {rel['verse_groups']:>6}")
    print(f"  event_participants: {rel['event_participants']:>6}")
    print(f"  event_locations:    {rel['event_locations']:>6}")
    print(linha)

    # Sanidade do mapeamento de livros (capítulos local vs. Theographic).
    divergentes = []
    livro_por_ordem = rel.get("livro_por_ordem", {})
    capitulos_locais = rel.get("capitulos_locais", {})
    for ordem in sorted(livro_por_ordem):
        meta = livro_por_ordem[ordem]
        local = capitulos_locais.get(ordem)
        tg = meta.get("chapter_count")
        if local is not None and tg is not None and local != tg:
            divergentes.append(f"    {meta['local_name']}: local={local}, Theographic={tg}")
    if divergentes:
        print("Atenção — diferenças de nº de capítulos (local vs. Theographic):")
        print("\n".join(divergentes))
        print(linha)
    return 0

def _exibir_pessoa(conn, nome, limite=50):
    p = md.encontrar_pessoa(conn, nome)
    if p is None:
        print(f"Pessoa não encontrada: {nome}")
        return 1
    print(f"{p['name']}  (id={p['person_id']}, lookup={p['person_lookup']})")
    if p["display_title"] and p["display_title"] != p["name"]:
        print(f"  título: {p['display_title']}")
    if p["gender"]:
        print(f"  gênero: {p['gender']}")
    nasc = md.rotulo_ano(p["birth_year"])
    morte = md.rotulo_ano(p["death_year"])
    if nasc or morte:
        print(f"  nascimento/morte: {nasc or '?'} — {morte or '?'}")
    versiculos = md.versiculos_da_pessoa(conn, p["person_id"], limite)
    total = p["verse_count"] or len(versiculos)
    print(f"  mencionada em {total} versículo(s); mostrando {len(versiculos)}:")
    for v in versiculos:
        print(f"    {v['verse_reference']}")
    return 0


def _exibir_lugar(conn, nome, limite=50):
    l = md.encontrar_lugar(conn, nome)
    if l is None:
        print(f"Lugar não encontrado: {nome}")
        return 1
    print(f"{l['name']}  (id={l['place_id']}, lookup={l['place_lookup']})")
    if l["display_title"] and l["display_title"] != l["name"]:
        print(f"  título: {l['display_title']}")
    if l["feature_type"]:
        print(f"  tipo: {l['feature_type']}")
    if l["latitude"] is not None and l["longitude"] is not None:
        print(f"  coordenadas: {l['latitude']}, {l['longitude']}")
    versiculos = md.versiculos_do_lugar(conn, l["place_id"], limite)
    total = l["verse_count"] or len(versiculos)
    print(f"  mencionado em {total} versículo(s); mostrando {len(versiculos)}:")
    for v in versiculos:
        print(f"    {v['verse_reference']}")
    return 0


def consultar_versiculo(ref):
    conn = md.abrir_banco(caminho_db())
    try:
        v = md.buscar_versiculo_por_referencia(conn, ref)
        if v is None:
            print(f"Referência não encontrada: {ref}")
            print("Dica: use o formato local, ex. \"João 3:16\".")
            return 1
        print(f"{v['verse_reference']}  (osisRef={v['osis_ref']}, "
              f"ano≈{md.rotulo_ano(v['year']) or '?'})")
        pessoas = md.pessoas_do_versiculo(conn, v["verse_id"])
        lugares = md.lugares_do_versiculo(conn, v["verse_id"])
        eventos = md.eventos_do_versiculo(conn, v["verse_id"])
        grupos = md.grupos_do_versiculo(conn, v["verse_id"])
        print(f"  Pessoas ({len(pessoas)}):",
              ", ".join(p["name"] for p in pessoas) or "(nenhuma)")
        print(f"  Lugares ({len(lugares)}):",
              ", ".join(l["name"] for l in lugares) or "(nenhum)")
        print(f"  Grupos ({len(grupos)}):",
              ", ".join(g["group_name"] for g in grupos) or "(nenhum)")
        print(f"  Eventos ({len(eventos)}):")
        for e in eventos:
            print(f"    • {e['title']}  ({md.rotulo_ano(e['start_date']) or 'sem data'})")
        return 0
    finally:
        conn.close()

def verificar(rel):
    """Checagens rápidas de integridade após a construção."""
    conn = md.abrir_banco(caminho_db())
    try:
        erros = []
        esperados = {
            "versiculos": 31102, "pessoas": 3067, "lugares": 1298,
            "eventos": 450, "livros": 66, "capitulos": 1189,
        }
        for chave, esperado in esperados.items():
            if rel.get(chave) != esperado:
                erros.append(f"contagem de {chave}: {rel.get(chave)} != {esperado}")

        v = md.buscar_versiculo_por_referencia(conn, "João 3:16")
        if v is None:
            erros.append("João 3:16 não encontrado.")
        else:
            nomes = {p["name"].lower() for p in md.pessoas_do_versiculo(conn, v["verse_id"])}
            if "jesus" not in nomes:
                erros.append("João 3:16 sem 'Jesus' entre as pessoas.")

        g = md.buscar_versiculo_por_referencia(conn, "Gênesis 1:1")
        if g is None or g["year"] != -4003:
            erros.append("Gênesis 1:1 com ano inesperado (esperado -4003).")

        if erros:
            print("[VERIFICAR] Problemas:")
            for e in erros:
                print("  -", e)
            return 1
        print("[VERIFICAR] OK — contagens e cruzamentos de exemplo consistentes.")
        return 0
    finally:
        conn.close()


def main(argv):
    parser = argparse.ArgumentParser(
        description="Base de dados histórica (Theographic) em SQLite.")
    parser.add_argument("--atualizar", action="store_true",
                        help="força novo download dos JSONs brutos")
    parser.add_argument("--consulta", metavar="REF",
                        help="mostra pessoas/lugares/eventos de um versículo (ex. \"João 3:16\")")
    parser.add_argument("--pessoa", metavar="NOME",
                        help="mostra uma pessoa e os versículos em que é citada")
    parser.add_argument("--lugar", metavar="NOME",
                        help="mostra um lugar e os versículos em que é citado")
    parser.add_argument("--cronologia", metavar="N", type=int, nargs="?",
                        const=20, help="lista os N primeiros eventos da cronologia")
    parser.add_argument("--resumo", action="store_true",
                        help="apenas mostra o resumo do banco existente")
    args = parser.parse_args(argv)

    if args.consulta:
        return consultar_versiculo(args.consulta)

    se_necessita_banco = args.pessoa or args.lugar or (args.cronologia is not None) or args.resumo
    if se_necessita_banco:
        if not os.path.isfile(caminho_db()):
            print("[ERRO] Banco ainda não construído. Rode sem argumentos primeiro.")
            return 1
        conn = md.abrir_banco(caminho_db())
        try:
            if args.pessoa:
                return _exibir_pessoa(conn, args.pessoa)
            if args.lugar:
                return _exibir_lugar(conn, args.lugar)
            if args.cronologia is not None:
                for e in md.cronologia(conn, args.cronologia):
                    print(f"{md.rotulo_ano(e['start_date']) or '?' :>12}  {e['title']}")
                return 0
            if args.resumo:
                for tabela in ("books", "chapters", "verse_metadata", "people",
                               "places", "events", "people_groups", "easton"):
                    n = conn.execute(f"SELECT COUNT(*) c FROM {tabela}").fetchone()["c"]
                    print(f"{tabela:>20}: {n}")
                return 0
        finally:
            conn.close()
        return 0

    rel = construir(atualizar=args.atualizar)
    relatar(rel)
    return verificar(rel)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))



