"""Utilitário de desenvolvimento: inspeciona o DOM renderizado do Streamlit.

Imprime os `data-testid` presentes e amostras de HTML de elementos-chave
(botões, radio, inputs, containers), navegando pelas abas para capturar o
máximo de componentes. Usado para fixar seletores CSS em `webapp/ui/tema.py`.
"""
from __future__ import annotations

import sys

from playwright.sync_api import sync_playwright

URL = "http://127.0.0.1:8501"


def _dump(page, title: str) -> None:
    page.wait_for_timeout(1500)
    data = page.evaluate(
        """() => {
            const s = new Set();
            document.querySelectorAll('[data-testid]').forEach(
                (e) => s.add(e.getAttribute('data-testid'))
            );
            const samples = {};
            for (const sel of [
                'div[data-testid*="stButton"] button',
                'div[data-testid*="stLinkButton"] a',
                '[data-testid*="stRadio"] label',
                '[data-testid*="stTextInput"]',
                '[data-testid*="stSelectbox"]',
                '[data-testid*="stExpander"]',
                '[data-testid*="stVerticalBlockBorderWrapper"]',
                '[data-testid*="stPills"] button',
                '[data-testid*="stSegmentedControl"]',
            ]) {
                const el = document.querySelector(sel);
                samples[sel] = el ? el.outerHTML.slice(0, 400) : null;
            }
            return { testids: Array.from(s).sort(), samples };
        }"""
    )
    print(f"\n===== {title} =====")
    print("TESTIDS:", ", ".join(data["testids"]))
    for sel, html in data["samples"].items():
        if html:
            print(f"\n--- {sel} ---\n{html}")


def _dump_ancestors(page, texto: str) -> None:
    chain = page.evaluate(
        """(texto) => {
            const el = [...document.querySelectorAll('*')].find(
                (e) => e.children.length === 0 && e.textContent.includes(texto)
            );
            if (!el) return 'not found: ' + texto;
            const chain = [];
            let n = el;
            for (let i = 0; i < 9 && n; i++) {
                chain.push(
                    n.tagName + '.' + [...n.classList].join('.') +
                    ' [td=' + (n.getAttribute('data-testid') || '') + ']'
                );
                n = n.parentElement;
            }
            return chain.join('\\n');
        }""",
        texto,
    )
    print(f"\n----- ANCESTRAIS DE '{texto}' -----\n{chain}")


def main() -> int:
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": 1280, "height": 800})
        page.goto(URL, wait_until="networkidle")
        _dump(page, "Início")
        _dump_ancestors(page, "Versículo do Dia")
        _dump_ancestors(page, "Mensagem para você")

        # Navega para Bíblia
        page.locator('[role="radiogroup"] label', has_text="Bíblia").first.click()
        _dump(page, "Bíblia")

        # Navega para Estudos
        page.locator('[role="radiogroup"] label', has_text="Estudos").first.click()
        _dump(page, "Estudos")

        browser.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
