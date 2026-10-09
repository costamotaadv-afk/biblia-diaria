# -*- coding: utf-8 -*-
"""
Valida a contextualização histórica dos Salmos (Feature 003).

Regras verificadas (apenas a stdlib; sem dependências):
  1. `contexto/Salmos.json` é uma lista de objetos com `id` único e não vazio.
  2. Todos os Salmos 1..150 estão presentes, exatamente uma vez.
  3. Campos obrigatórios (`titulo`, `classificacao`, `periodo`,
     `contexto_politico`, `localizacao`, `explicacao`, `fontes`) preenchidos.
  4. `certeza` pertence a {documentado, tradicional, hipotese, indeterminado}.
  5. `referencias_cruzadas[].ref` resolve para um livro do `indice.json`.

Uso: python tool/validar_contexto.py
"""
import json
import os
import sys

BASE = os.path.join("assets", "data")
DETALHE = os.path.join(BASE, "contexto", "Salmos.json")
INDICE_BIBLIA = os.path.join(BASE, "indice.json")

CERTEZA_VALIDA = {"documentado", "tradicional", "hipotese", "indeterminado"}


def carregar_json(caminho):
    with open(caminho, encoding="utf-8-sig") as f:
        return json.load(f)


def extrair_nomes_livros():
    indice = carregar_json(INDICE_BIBLIA)
    return [str(item.get("nome", "")).strip() for item in indice if isinstance(item, dict)]


def resolver_livro(ref, nomes):
    """Devolve o nome do livro casado (mais longo primeiro) ou None."""
    ref = ref.strip()
    for nome in sorted(nomes, key=len, reverse=True):
        if not nome:
            continue
        if ref == nome or ref.startswith(nome + " "):
            return nome
    return None


def main():
    erros = []

    if not os.path.isfile(DETALHE):
        print(f"[ERRO] Detalhe ausente: {DETALHE}")
        return 1

    dados = carregar_json(DETALHE)
    if not isinstance(dados, list):
        print("[ERRO] O detalhe deve ser uma lista.")
        return 1

    nomes_livros = extrair_nomes_livros()
    ids = set()
    numeros = set()

    for item in dados:
        if not isinstance(item, dict):
            erros.append("Item não-objeto no detalhe.")
            continue
        id_ = str(item.get("id", "")).strip()
        if not id_:
            erros.append("Item sem `id`.")
            continue
        if id_ in ids:
            erros.append(f"`id` duplicado `{id_}`.")
        ids.add(id_)

        numero = item.get("salmo")
        if not isinstance(numero, int) or not (1 <= numero <= 150):
            erros.append(f"{id_}: `salmo` inválido ({numero}).")
        else:
            if numero in numeros:
                erros.append(f"{id_}: Salmo {numero} duplicado.")
            numeros.add(numero)

        for campo in ("titulo", "periodo", "contexto_politico",
                      "localizacao", "explicacao"):
            valor = str(item.get(campo, "")).strip()
            if not valor:
                erros.append(f"{id_}: campo obrigatório `{campo}` vazio.")

        classificacao = item.get("classificacao")
        if not isinstance(classificacao, list) or not classificacao or \
                not all(isinstance(c, str) and c.strip() for c in classificacao):
            erros.append(f"{id_}: `classificacao` deve ser lista de strings não vazias.")

        certeza = str(item.get("certeza", "")).strip()
        if certeza not in CERTEZA_VALIDA:
            erros.append(f"{id_}: `certeza` inválida (`{certeza}`).")

        fontes = item.get("fontes")
        if not isinstance(fontes, list) or not fontes:
            erros.append(f"{id_}: `fontes` deve ser lista não vazia.")
        else:
            for f in fontes:
                if not isinstance(f, dict) or not any(
                        str(f.get(k, "")).strip() for k in ("autor", "obra", "ano", "licenca")):
                    erros.append(f"{id_}: fonte inválida.")
                    break

        refs = item.get("referencias_cruzadas")
        if refs is not None and not isinstance(refs, list):
            erros.append(f"{id_}: `referencias_cruzadas` deve ser lista.")
        elif isinstance(refs, list):
            for r in refs:
                if not isinstance(r, dict):
                    erros.append(f"{id_}: referência cruzada não-objeto.")
                    continue
                ref = str(r.get("ref", "")).strip()
                if not ref:
                    erros.append(f"{id_}: referência cruzada sem `ref`.")
                elif resolver_livro(ref, nomes_livros) is None:
                    erros.append(f"{id_}: referência `{ref}` não resolve para um livro.")

    for n in range(1, 151):
        if n not in numeros:
            erros.append(f"Salmo {n} ausente no detalhe.")

    if erros:
        print(f"[ERRO] {len(erros)} problema(s) encontrado(s):")
        for e in erros:
            print("  -", e)
        return 1

    print(f"OK — {len(ids)} contextos dos Salmos 1..150 consistentes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
