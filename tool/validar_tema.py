"""Valida o tema aplicado no DOM renderizado (estilos computados).

Como as capturas não são visíveis para revisão automatizada, checamos aqui os
valores calculados pelo navegador (fundo, fonte, raio, altura) e imprimimos o
HTML do ``st.pills`` para fixar o seletor correto.
"""
from __future__ import annotations

import sys

from playwright.sync_api import sync_playwright

URL = 'http://127.0.0.1:8501'


def _css(page, selector, prop):
    return page.evaluate(
        """([sel, prop]) => {
            const el = document.querySelector(sel);
            if (!el) return null;
            return getComputedStyle(el)[prop];
        }""",
        [selector, prop],
    )


def main() -> int:
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={'width': 1280, 'height': 800})
        page.goto(URL, wait_until='networkidle')
        page.wait_for_timeout(3000)

        print('--- Início ---')
        print('main-bg:', _css(page, '[data-testid="stMainBlockContainer"]', 'backgroundColor'))
        print('btn-radius:', _css(page, 'button[kind="secondary"]', 'borderRadius'))
        print('btn-minheight:', _css(page, 'button[kind="secondary"]', 'minHeight'))
        print('nav-checked-bg:', _css(page, 'label[data-testid="stRadioOption"]:has(input:checked)', 'backgroundColor'))
        print('verse-card-bg:', _css(page, '.st-key-card_inicio_versiculo', 'backgroundImage'))

        # Bíblia: versículos tocáveis
        page.locator('label[data-testid="stRadioOption"]:has-text("Bíblia")').first.click()
        page.wait_for_timeout(2500)
        print('\n--- Bíblia ---')
        dump = page.evaluate(
            """() => {
                const btns = [...document.querySelectorAll('[data-testid="stButton"]')]
                    .filter((d) => (d.textContent || '').includes('No princípio'));
                if (!btns.length) return 'no verse button';
                const d = btns[0];
                return JSON.stringify({
                    stButtonClass: d.className,
                    parentClass: d.parentElement ? d.parentElement.className : null,
                    grandparentClass: d.parentElement?.parentElement ? d.parentElement.parentElement.className : null,
                });
            }"""
        )
        print(dump)
        print('verse-font:', _css(page, '[class*="st-key-verse_"] button', 'fontFamily'))
        print('verse-align:', _css(page, '[class*="st-key-verse_"] button', 'textAlign'))
        print('verse-num-color:', _css(page, '[class*="st-key-verse_"] button strong', 'color'))

        # Estudos: pílulas
        page.locator('label[data-testid="stRadioOption"]:has-text("Estudos")').first.click()
        page.wait_for_timeout(2500)
        print('\n--- Estudos (pills) ---')
        print('pill-selected-bg:', _css(page, 'button[role="radio"][aria-checked="true"]', 'backgroundColor'))
        print('pill-selected-border:', _css(page, 'button[role="radio"][aria-checked="true"]', 'borderColor'))
        print('pill-radius:', _css(page, 'button[role="radio"]', 'borderRadius'))

        browser.close()
    return 0


if __name__ == '__main__':
    sys.exit(main())

