# -*- coding: utf-8 -*-
"""
Divide a fonte canônica da Bíblia (um arquivo só, ~13 MB) em vários arquivos
menores para carregamento sob demanda na web e otimização no Android.

Fonte (canônica): `tool/backup/biblia.json.gz` — versão compactada (padrão,
para não ocupar ~13 MB no repositório). Se preferir manter descompactada, use
`tool/backup/biblia.json` (o script prioriza o `.gz` e cai para o `.json`).

Saídas (tudo em `assets/data/`):
  - indice.json         -> lista de livros (nome + nº capítulos) p/ navegação rápida
  - mensagens.json      -> array de mensagens do dia
  - livros/<nome>.json  -> conteúdo completo de cada livro (capítulos + versículos)

Uso: python tool/dividir_biblia.py
"""
import gzip
import json
import os

SRC_DIR = os.path.join("tool", "backup")
SRC_GZ = os.path.join(SRC_DIR, "biblia.json.gz")
SRC_PLAIN = os.path.join(SRC_DIR, "biblia.json")
OUT_DIR = os.path.join("assets", "data")
LIVROS_DIR = os.path.join(OUT_DIR, "livros")


def _carregar_dados():
    if os.path.exists(SRC_GZ):
        with gzip.open(SRC_GZ, "rt", encoding="utf-8-sig") as f:
            return json.load(f)
    with open(SRC_PLAIN, encoding="utf-8-sig") as f:
        return json.load(f)


def main():
    dados = _carregar_dados()

    livros = dados.get("livros", [])
    mensagens = dados.get("mensagens", []) or dados.get("mensagens_dia", [])

    os.makedirs(LIVROS_DIR, exist_ok=True)

    # Índice (leve) para a tela de leitura / navegação.
    indice = []
    for livro in livros:
        indice.append({
            "nome": livro.get("nome", ""),
            "capitulos": len(livro.get("capitulos", [])),
        })

    with open(os.path.join(OUT_DIR, "indice.json"), "w", encoding="utf-8") as f:
        json.dump(indice, f, ensure_ascii=False)

    with open(os.path.join(OUT_DIR, "mensagens.json"), "w", encoding="utf-8") as f:
        json.dump(mensagens, f, ensure_ascii=False)

    # Um arquivo pequeno por livro.
    total_bytes = 0
    for livro in livros:
        nome = livro.get("nome", "")
        # Nome usado como nome de arquivo. Remover caracteres inválidos.
        seguro = "".join(c for c in nome if c not in '<>:"/\\|?*').strip()
        with open(os.path.join(LIVROS_DIR, f"{seguro}.json"), "w", encoding="utf-8") as f:
            json.dump(livro, f, ensure_ascii=False)
        total_bytes += os.path.getsize(os.path.join(LIVROS_DIR, f"{seguro}.json"))

    print(f"Livros divididos: {len(livros)}")
    print(f"Índice: {os.path.join(OUT_DIR, 'indice.json')}")
    print(f"Mensagens: {os.path.join(OUT_DIR, 'mensagens.json')} ({len(mensagens)})")
    print(f"Pasta livros: {os.path.join(OUT_DIR, 'livros')} (~{total_bytes/1024/1024:.1f} MB total)")

if __name__ == "__main__":
    main()
