# -*- coding: utf-8 -*-
"""
Valida a consistência dos dados de estudo (Feature 002), com foco nos campos
opcionais de contexto histórico (`periodo` e `fatos`) dos recursos do tipo
`momento_historico`.

Regras verificadas (apenas a stdlib; sem dependências):
  1. `estudos_indice.json` é uma lista de objetos com `id` único e não vazio.
  2. Cada `estudos/<Livro>.json` é uma lista de objetos com `id` que exista no
     índice (o índice é a fonte da verdade; o detalhe guarda o corpo).
  3. `ref` segue o padrão "<Livro> [cap[:vers]]" (livro, capítulo ou versículo).
  4. Em `momento_historico`, `periodo` (se presente) é string não vazia e
     `fatos` (se presente) é lista de strings não vazias.

Uso: python tool/validar_estudos.py
"""
import json
import os
import re
import sys

BASE = os.path.join("assets", "data")
INDICE = os.path.join(BASE, "estudos_indice.json")
ESTUDOS_DIR = os.path.join(BASE, "estudos")


def carregar_json(caminho):
    with open(caminho, encoding="utf-8-sig") as f:
        return json.load(f)


def main():
    erros = []

    if not os.path.isfile(INDICE):
        print(f"[ERRO] Índice ausente: {INDICE}")
        return 1

    indice = carregar_json(INDICE)
    if not isinstance(indice, list):
        print("[ERRO] O índice deve ser uma lista.")
        return 1

    ids_indice = []
    for item in indice:
        if not isinstance(item, dict):
            erros.append("Índice: item não-objeto.")
            continue
        id_ = str(item.get("id", "")).strip()
        if not id_:
            erros.append("Índice: item sem `id`.")
        elif id_ in ids_indice:
            erros.append(f"Índice: `id` duplicado `{id_}`.")
        else:
            ids_indice.append(id_)
        ref = str(item.get("ref", "")).strip()
        if ref and not re.match(r"^.+?(?:\s+\d{1,3}(?::\d{1,3})?)?$", ref):
            erros.append(f"Índice: `ref` fora do padrão em `{id_}`: `{ref}`.")

    if not os.path.isdir(ESTUDOS_DIR):
        print(f"[ERRO] Pasta de detalhes ausente: {ESTUDOS_DIR}")
        return 1

    ids_detalhes = set()
    for nome in sorted(os.listdir(ESTUDOS_DIR)):
        if not nome.endswith(".json"):
            continue
        caminho = os.path.join(ESTUDOS_DIR, nome)
        detalhes = carregar_json(caminho)
        if not isinstance(detalhes, list):
            erros.append(f"{nome}: não é uma lista.")
            continue
        for item in detalhes:
            if not isinstance(item, dict):
                erros.append(f"{nome}: item não-objeto.")
                continue
            id_ = str(item.get("id", "")).strip()
            if not id_:
                erros.append(f"{nome}: item sem `id`.")
                continue
            ids_detalhes.add(id_)
            if id_ not in ids_indice:
                erros.append(f"{nome}: `id` `{id_}` sem par no índice.")
            if item.get("tipo") == "momento_historico":
                periodo = item.get("periodo")
                if periodo is not None and not (
                    isinstance(periodo, str) and periodo.strip()
                ):
                    erros.append(f"{nome}: `periodo` inválido em `{id_}`.")
                fatos = item.get("fatos")
                if fatos is not None and (
                    not isinstance(fatos, list)
                    or not all(isinstance(f, str) and f.strip() for f in fatos)
                ):
                    erros.append(
                        f"{nome}: `fatos` deve ser lista de strings não vazias em `{id_}`."
                    )

    orfaos = [i for i in ids_indice if i not in ids_detalhes]
    if orfaos:
        print(f"[AVISO] ids no índice sem detalhe ({len(orfaos)}):", ", ".join(orfaos[:10]))

    if erros:
        print(f"[ERRO] {len(erros)} problema(s) encontrado(s):")
        for e in erros:
            print("  -", e)
        return 1

    print(f"OK — índice ({len(ids_indice)} recursos) e detalhes consistentes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
