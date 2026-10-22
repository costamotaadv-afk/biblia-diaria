# -*- coding: utf-8 -*-
"""
Compara a Bíblia local do aplicativo (`assets/data/livros/*.json`) com a
versão Almeida Corrigida Fiel (ACF) do repositório público:

    https://raw.githubusercontent.com/thiagobodruk/bible/master/json/pt_acf.json

O que este script faz:
  1. Verifica e ajusta o caminho dos JSONs locais da Bíblia (procura a pasta
     `assets/data` a partir da raiz do projeto e, se necessário, do diretório
     de execução / subindo na árvore de pastas).
  2. Baixa o JSON ACF (ou reaproveita o cache local `.pt_acf_cache.json`).
  3. Compara a ESTRUTURA (livros, capítulos e quantidade de versículos) e o
     TEXTO de cada versículo.
  4. Exibe um relatório claro das divergências no terminal, distinguindo
     "junção de versículos" (numeração diferente, sem perda de conteúdo) de
     ausência/divergência real.

Sem dependências externas — usa apenas a biblioteca padrão do Python.

Uso:
    python comparar_biblia.py                # usa o cache do ACF, se existir
    python comparar_biblia.py --atualizar    # força novo download do ACF
    python comparar_biblia.py --todas        # lista TODAS as divergências de texto
    python comparar_biblia.py --max=200      # limita a amostra a 200 divergências
"""
import json
import os
import re
import sys
import unicodedata
import urllib.error
import urllib.request

ACF_URL = "https://raw.githubusercontent.com/thiagobodruk/bible/master/json/pt_acf.json"

# Nomes de livros que diferem entre o app local e o ACF (local -> ACF).
ALIASES_NOME = {
    "Cânticos": "Cantares",
    "Lamentações de Jeremias": "Lamentações",
}

MAX_DIVERGENCIAS_PADRAO = 100

# Limiar (0..1) de sobreposição de tokens para considerar que um versículo
# local "junta" dois versículos ACF consecutivos (numeração diferente).
LIMIAR_JUNCAO = 0.55


# ---------------------------------------------------------------------------
# Caminho dos dados locais
# ---------------------------------------------------------------------------
def raiz_projeto():
    """Raiz do projeto, inferida a partir da localização deste script."""
    return os.path.dirname(os.path.abspath(__file__))


def resolver_base():
    """Verifica e ajusta o caminho da pasta `assets/data` do aplicativo.

    Retorna o caminho validado (contém `indice.json` e a pasta `livros/`) ou
    ``None`` se não for encontrado. A ordem de busca é:

      1. ``<raiz do script>/assets/data``;
      2. ``<cwd>/assets/data``;
      3. subida de diretórios a partir do cwd até achar ``assets/data``.
    """
    candidatos = []
    candidatos.append(os.path.join(raiz_projeto(), "assets", "data"))
    candidatos.append(os.path.join(os.getcwd(), "assets", "data"))

    diretorio = os.path.abspath(os.getcwd())
    while True:
        candidatos.append(os.path.join(diretorio, "assets", "data"))
        pai = os.path.dirname(diretorio)
        if pai == diretorio:
            break
        diretorio = pai

    vistos = set()
    for base in candidatos:
        base = os.path.normpath(base)
        if base in vistos:
            continue
        vistos.add(base)
        if os.path.isfile(os.path.join(base, "indice.json")) and \
                os.path.isdir(os.path.join(base, "livros")):
            return base
    return None


def carregar_json(caminho):
    """Lê um arquivo JSON aceitando BOM (utf-8-sig)."""
    with open(caminho, encoding="utf-8-sig") as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Download / cache do ACF
# ---------------------------------------------------------------------------
def baixar_acf(cache_path):
    """Baixa o JSON ACF e salva uma cópia crua em `cache_path`."""
    requisicao = urllib.request.Request(
        ACF_URL, headers={"User-Agent": "comparar_biblia.py/1.0"}
    )
    with urllib.request.urlopen(requisicao, timeout=120) as resposta:
        dados = resposta.read()
    with open(cache_path, "wb") as f:
        f.write(dados)
    return json.loads(dados.decode("utf-8-sig"))


def carregar_acf_do_cache(cache_path):
    with open(cache_path, "rb") as f:
        return json.loads(f.read().decode("utf-8-sig"))


def obter_acf(cache_path, atualizar):
    """Devolve a lista de livros ACF, baixando se necessário.

    Se o download falhar e houver cache, usa o cache como contingência.
    """
    if not atualizar and os.path.isfile(cache_path):
        print(f"[cache] Usando ACF em cache: {cache_path}")
        return carregar_acf_do_cache(cache_path)

    try:
        print(f"[download] Baixando ACF de {ACF_URL}")
        return baixar_acf(cache_path)
    except (urllib.error.URLError, OSError, ValueError) as erro:
        if os.path.isfile(cache_path):
            print(f"[aviso] Falha no download ({erro}); usando cache local.")
            return carregar_acf_do_cache(cache_path)
        raise


# ---------------------------------------------------------------------------
# Normalização de texto
# ---------------------------------------------------------------------------
def normalizar(texto):
    """Normaliza para comparação de equivalência: remove acentos, caixa,
    espaços repetidos e pontuação. Não altera o texto exibido no relatório."""
    texto = str(texto or "")
    texto = unicodedata.normalize("NFD", texto)
    texto = "".join(c for c in texto if unicodedata.category(c) != "Mn")
    texto = texto.lower()
    texto = re.sub(r"\s+", " ", texto)
    texto = re.sub(r"[^\w\s]", "", texto)
    return texto.strip()


def _tokens_juncao(texto):
    """Tokens normalizados para detectar junção (troca Jeová/Senhor)."""
    texto = normalizar(texto)
    texto = texto.replace("jeova", "senhor").replace("jehova", "senhor")
    return set(texto.split())


def detectar_juncoes(vers_local, vers_acf, limiar=LIMIAR_JUNCAO):
    """Encontra junções de versículos (local tem menos versículos que a ACF).

    Usa alinhamento por sobreposição de tokens: a junção é a posição em que um
    versículo local absorve dois versículos ACF consecutivos, deslocando a
    numeração em +1 daí em diante. Retorna tuplas
    ``(num_local, num_acf_a, num_acf_b)`` (números 1-based).
    """
    n = len(vers_local)
    m = len(vers_acf)
    if n >= m:
        return []

    ltoks = [_tokens_juncao(v.get("texto", "")) for v in vers_local]
    atoks = [_tokens_juncao(t) for t in vers_acf]

    def cobertura(l, a):
        return (len(l & a) / len(a)) if a else 0.0

    juncoes = []
    if m == n + 1:
        # Um único versículo a mais no ACF: localiza a junção por alinhamento.
        melhor_p = None
        melhor_score = -1.0
        for p in range(n):
            score = sum(cobertura(ltoks[i], atoks[i]) for i in range(p))
            score += cobertura(ltoks[p], atoks[p] | atoks[p + 1])
            score += sum(cobertura(ltoks[i], atoks[i + 1]) for i in range(p + 1, n))
            if score > melhor_score:
                melhor_score = score
                melhor_p = p
        if melhor_p is not None:
            p = melhor_p
            # Confirma que é junção (o versículo local cobre ambos os ACF).
            if cobertura(ltoks[p], atoks[p]) >= limiar and \
                    cobertura(ltoks[p], atoks[p + 1]) >= limiar:
                juncoes.append((p + 1, p + 1, p + 2))
        return juncoes

    # Diferença maior que um: cobertura simples de pares consecutivos.
    for indice, lt in enumerate(ltoks):
        if not lt:
            continue
        for j in range(m - 1):
            if cobertura(lt, atoks[j]) >= limiar and \
                    cobertura(lt, atoks[j + 1]) >= limiar:
                juncoes.append((indice + 1, j + 1, j + 2))
    return juncoes


# ---------------------------------------------------------------------------
# Comparação
# ---------------------------------------------------------------------------
def comparar(indice, livros_dir, acf):
    """Compara a Bíblia local com a ACF. Retorna um dicionário de relatório."""
    acf_por_nome = {str(livro.get("name", "")).strip(): livro for livro in acf}
    nomes_acf = set(acf_por_nome)

    relatorio = {
        "livros_local": len(indice),
        "livros_acf": len(acf),
        "sem_correspondencia": [],
        "acf_sem_local": [],
        "estrutura_capitulos": [],
        "estrutura_versiculos": [],
        "juncoes": [],                # (ref_cap, num_local, num_acf_a, num_acf_b)
        "versiculos_faltantes": [],
        "versiculos_nao_comparados": 0,
        "versiculos_comparados": 0,
        "identicos": 0,
        "equivalentes": 0,
        "divergentes": 0,
        "divergencias": [],         # (referencia, local, acf)
        "equivalentes_lista": [],   # (referencia, local, acf)
        "divergencias_por_livro": {},
    }

    acf_encontrados = set()

    for item in indice:
        if not isinstance(item, dict):
            continue
        nome = str(item.get("nome", "")).strip()
        acf_livro = acf_por_nome.get(nome) or acf_por_nome.get(ALIASES_NOME.get(nome, ""))

        if acf_livro is None:
            relatorio["sem_correspondencia"].append(nome)
            continue
        acf_encontrados.add(str(acf_livro.get("name", "")).strip())

        caminho = os.path.join(livros_dir, f"{nome}.json")
        if not os.path.isfile(caminho):
            relatorio["sem_correspondencia"].append(f"{nome} (arquivo ausente: {caminho})")
            continue

        livro_local = carregar_json(caminho)
        caps_local = livro_local.get("capitulos", [])
        caps_acf = acf_livro.get("chapters", [])

        if len(caps_local) != len(caps_acf):
            relatorio["estrutura_capitulos"].append(
                (nome, len(caps_local), len(caps_acf))
            )

        caps_local_por_num = {}
        for capitulo in caps_local:
            if isinstance(capitulo, dict) and isinstance(capitulo.get("numero"), int):
                caps_local_por_num[capitulo["numero"]] = capitulo

        numeros = set(caps_local_por_num) | set(range(1, len(caps_acf) + 1))
        for numero in sorted(numeros):
            cap_local = caps_local_por_num.get(numero)
            vers_local = cap_local.get("versiculos", []) if cap_local else None
            vers_acf = caps_acf[numero - 1] if 1 <= numero <= len(caps_acf) else None

            if vers_local is None:
                relatorio["estrutura_versiculos"].append(
                    (f"{nome} {numero}", "capítulo ausente no local", len(vers_acf or []))
                )
                continue
            if vers_acf is None:
                relatorio["estrutura_versiculos"].append(
                    (f"{nome} {numero}", len(vers_local), "capítulo ausente no ACF")
                )
                continue

            if len(vers_local) != len(vers_acf):
                relatorio["estrutura_versiculos"].append(
                    (f"{nome} {numero}", len(vers_local), len(vers_acf))
                )
                juncoes = detectar_juncoes(vers_local, vers_acf)
                if juncoes:
                    for num_local, num_acf_a, num_acf_b in juncoes:
                        relatorio["juncoes"].append(
                            (f"{nome} {numero}", num_local, num_acf_a, num_acf_b)
                        )
                    # Numeração/divisão diferente: a comparação verso a verso
                    # por número ficaria desalinhada. Pula este capítulo.
                    relatorio["versiculos_nao_comparados"] += len(vers_local)
                    continue

            vers_local_por_num = {
                v.get("numero"): v for v in vers_local if isinstance(v, dict)
            }
            total_versiculos = max(len(vers_local), len(vers_acf))
            for vi in range(1, total_versiculos + 1):
                v_local = vers_local_por_num.get(vi)
                v_acf = vers_acf[vi - 1] if vi <= len(vers_acf) else None

                if v_local is None:
                    relatorio["versiculos_faltantes"].append(
                        (f"{nome} {numero}:{vi}", "local")
                    )
                    continue
                if v_acf is None:
                    relatorio["versiculos_faltantes"].append(
                        (f"{nome} {numero}:{vi}", "ACF")
                    )
                    continue

                texto_local = str(v_local.get("texto", "")).strip()
                texto_acf = str(v_acf).strip()
                referencia = f"{nome} {numero}:{vi}"
                relatorio["versiculos_comparados"] += 1

                if texto_local == texto_acf:
                    relatorio["identicos"] += 1
                elif normalizar(texto_local) == normalizar(texto_acf):
                    relatorio["equivalentes"] += 1
                    relatorio["equivalentes_lista"].append(
                        (referencia, texto_local, texto_acf)
                    )
                else:
                    relatorio["divergentes"] += 1
                    relatorio["divergencias"].append(
                        (referencia, texto_local, texto_acf)
                    )
                    relatorio["divergencias_por_livro"][nome] = \
                        relatorio["divergencias_por_livro"].get(nome, 0) + 1

    relatorio["acf_sem_local"] = sorted(nomes_acf - acf_encontrados)
    return relatorio



# ---------------------------------------------------------------------------
# Relatório
# ---------------------------------------------------------------------------
def _porcentagem(parte, todo):
    if not todo:
        return "0.0%"
    return f"{100.0 * parte / todo:.1f}%"


def _resumo_texto(texto, limite=76):
    texto = " ".join(str(texto or "").split())
    if len(texto) <= limite:
        return texto
    return texto[: limite - 1] + "…"


def relatar(relatorio, base, cache_path, max_divergencias, listar_todas):
    """Imprime o relatório de divergências no terminal."""
    linha = "=" * 72
    print()
    print(linha)
    print(" RELATÓRIO DE COMPARAÇÃO — Bíblia local × Almeida Corrigida Fiel")
    print(linha)
    print(f" Local : {base}")
    print(f" ACF   : {ACF_URL}")
    print(f" Cache : {cache_path}")

    print()
    print("[1] ESTRUTURA (livros / capítulos / versículos)")
    print("-" * 72)
    print(f" Livros locais: {relatorio['livros_local']}   "
          f"Livros ACF: {relatorio['livros_acf']}")

    if relatorio["sem_correspondencia"]:
        print(f" Livros locais SEM correspondência no ACF "
              f"({len(relatorio['sem_correspondencia'])}):")
        for nome in relatorio["sem_correspondencia"]:
            print(f"   - {nome}")
    else:
        print(" Livros locais SEM correspondência no ACF: 0")

    if relatorio["acf_sem_local"]:
        print(f" Livros do ACF SEM correspondência local "
              f"({len(relatorio['acf_sem_local'])}):")
        for nome in relatorio["acf_sem_local"]:
            print(f"   - {nome}")
    else:
        print(" Livros do ACF SEM correspondência local: 0")

    if relatorio["estrutura_capitulos"]:
        print(f"\n Divergências de nº de CAPÍTULOS "
              f"({len(relatorio['estrutura_capitulos'])}):")
        for nome, n_local, n_acf in relatorio["estrutura_capitulos"]:
            print(f"   - {nome}: local {n_local} × ACF {n_acf}")
    else:
        print("\n Divergências de nº de capítulos por livro: 0")

    n_estrut = relatorio["estrutura_versiculos"]
    print(f"\n Divergências de nº de VERSÍCULOS por capítulo: {len(n_estrut)}")
    for referencia, n_local, n_acf in n_estrut[:max_divergencias]:
        print(f"   - {referencia}: local {n_local} × ACF {n_acf}")
    if len(n_estrut) > max_divergencias:
        print(f"   ... e mais {len(n_estrut) - max_divergencias} (use --todas)")

    juncoes = relatorio["juncoes"]
    if juncoes:
        print(f"\n Junções de versículos (numeração diferente, SEM perda de conteúdo): "
              f"{len(juncoes)}")
        for ref_cap, num_local, num_a, num_b in juncoes[:max_divergencias]:
            print(f"   - {ref_cap}:{num_local} junta ACF {ref_cap}:{num_a}+{num_b}")
        if len(juncoes) > max_divergencias:
            print(f"   ... e mais {len(juncoes) - max_divergencias} (use --todas)")

    n_faltantes = relatorio["versiculos_faltantes"]
    if n_faltantes:
        print(f"\n Versículos presentes só numa fonte (possível divergência de conteúdo): "
              f"{len(n_faltantes)}")
        for referencia, lado in n_faltantes[:max_divergencias]:
            print(f"   - {referencia}: ausente no {'local' if lado == 'local' else 'ACF'}")
        if len(n_faltantes) > max_divergencias:
            print(f"   ... e mais {len(n_faltantes) - max_divergencias} (use --todas)")

    print()
    print("[2] TEXTO DOS VERSÍCULOS")
    print("-" * 72)
    total = relatorio["versiculos_comparados"]
    identicos = relatorio["identicos"]
    equivalentes = relatorio["equivalentes"]
    divergentes = relatorio["divergentes"]
    print(f" Versículos comparados : {total}")
    print(f" Idênticos             : {identicos} ({_porcentagem(identicos, total)})")
    print(f" Equivalentes (formato) : {equivalentes} ({_porcentagem(equivalentes, total)})")
    print(f" Divergentes (palavreado): {divergentes} ({_porcentagem(divergentes, total)})")

    if relatorio["divergencias_por_livro"]:
        top = sorted(relatorio["divergencias_por_livro"].items(),
                     key=lambda kv: kv[1], reverse=True)[:10]
        print("\n Livros com mais divergências de texto:")
        for nome, quantidade in top:
            print(f"   - {nome}: {quantidade}")

    if equivalentes:
        print(f"\n Amostra de versículos EQUIVALENTES (só formatação/acento) — "
              f"{equivalentes} no total:")
        for referencia, local, acf in relatorio["equivalentes_lista"][:10]:
            print(f"   [{referencia}]")
            print(f"     local: {_resumo_texto(local)}")
            print(f"     ACF  : {_resumo_texto(acf)}")

    if divergentes:
        limite = None if listar_todas else max_divergencias
        amostra = relatorio["divergencias"] if limite is None \
            else relatorio["divergencias"][:limite]
        print(f"\n Divergências de TEXTO (amostra de {len(amostra)} "
              f"de {divergentes}):")
        for referencia, local, acf in amostra:
            print(f"   [{referencia}]")
            print(f"     local: {_resumo_texto(local)}")
            print(f"     ACF  : {_resumo_texto(acf)}")
        if limite is not None and divergentes > limite:
            print(f"   ... e mais {divergentes - limite} (use --todas)")

    print()
    print("[3] RESUMO")
    print("-" * 72)
    if not relatorio["sem_correspondencia"] and \
            not relatorio["estrutura_capitulos"] and \
            not relatorio["estrutura_versiculos"]:
        print(" Estrutura íntegra: os 66 livros, capítulos e versículos batem com a ACF.")
    else:
        print(" Há divergências ESTRUTURAIS (ver seção [1]).")
    print(f" Texto: {identicos} idênticos, {equivalentes} equivalentes, "
          f"{divergentes} divergentes.")
    n_nao = relatorio["versiculos_nao_comparados"]
    if n_nao:
        print(f"        {n_nao} versículo(s) não comparado(s) por numeração diferente.")
    if relatorio["juncoes"] and not relatorio["versiculos_faltantes"]:
        print(" Numeração: as diferenças de nº de versículos são junções "
              "(numeração diferente), sem perda de conteúdo.")
    elif relatorio["versiculos_faltantes"]:
        print(" Atenção: há versículos presentes só numa fonte "
              "(possível perda/omissão de conteúdo).")
    if divergentes:
        print(" Observação: o texto local não é a ACF (tradução diferente); "
              "as divergências de texto são esperadas.")
    print(linha)
    print()



# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def _parse_args(argv):
    atualizar = False
    listar_todas = False
    max_divergencias = MAX_DIVERGENCIAS_PADRAO
    for arg in argv:
        if arg in ("--atualizar", "--refresh", "-a"):
            atualizar = True
        elif arg in ("--todas", "--tudo", "-t"):
            listar_todas = True
        elif arg.startswith("--max="):
            try:
                max_divergencias = int(arg.split("=", 1)[1])
            except ValueError:
                print(f"[erro] Valor inválido em {arg}")
                sys.exit(2)
        elif arg in ("--ajuda", "-h", "--help"):
            print(__doc__)
            sys.exit(0)
        else:
            print(f"[erro] Argumento desconhecido: {arg}")
            print(__doc__)
            sys.exit(2)
    return atualizar, listar_todas, max_divergencias


def main(argv):
    atualizar, listar_todas, max_divergencias = _parse_args(argv)

    base = resolver_base()
    if base is None:
        print("[ERRO] Não encontrei a pasta `assets/data` do aplicativo.")
        print("       Rode este script a partir da raiz do projeto, ou verifique")
        print("       se `assets/data/indice.json` e `assets/data/livros/` existem.")
        return 1

    livros_dir = os.path.join(base, "livros")
    indice_path = os.path.join(base, "indice.json")
    cache_path = os.path.join(raiz_projeto(), ".pt_acf_cache.json")

    indice = carregar_json(indice_path)
    if not isinstance(indice, list):
        print(f"[ERRO] `indice.json` não é uma lista: {indice_path}")
        return 1

    acf = obter_acf(cache_path, atualizar)
    if not isinstance(acf, list):
        print("[ERRO] O JSON ACF não é uma lista.")
        return 1

    relatorio = comparar(indice, livros_dir, acf)
    relatar(relatorio, base, cache_path, max_divergencias, listar_todas)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

