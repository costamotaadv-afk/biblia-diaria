"""Captura de telas comparativas (Flutter Web × Streamlit) via Playwright.

Uso:
  python tool\\capturar_telas.py --app streamlit
  python tool\\capturar_telas.py --app flutter
  python tool\\capturar_telas.py --app both
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs' / 'capturas'
STREAMLIT = 'http://127.0.0.1:8501'
FLUTTER = 'http://127.0.0.1:7357'

VIEWPORTS = {
    'desktop': {'width': 1280, 'height': 800},
    'mobile': {'width': 390, 'height': 844},
}


def _click_tab(page, label: str) -> None:
    page.locator(
        f'label[data-testid="stRadioOption"]:has-text("{label}")'
    ).first.click()
    page.wait_for_timeout(1800)


def _click_text(page, texto: str) -> None:
    page.get_by_role('radio', name=texto).first.click()
    page.wait_for_timeout(1800)


def capture_streamlit() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch()
        for vp_name, vp in VIEWPORTS.items():
            page = browser.new_page(viewport=vp)
            page.goto(STREAMLIT, wait_until='networkidle')
            page.wait_for_timeout(3500)

            page.screenshot(path=str(OUT / f'streamlit-{vp_name}-inicio.png'))

            _click_tab(page, 'Bíblia')
            page.screenshot(path=str(OUT / f'streamlit-{vp_name}-biblia.png'))

            _click_tab(page, 'Estudos')
            page.screenshot(path=str(OUT / f'streamlit-{vp_name}-estudos.png'))

            # Seção Explorar dentro de Estudos.
            _click_text(page, 'Explorar')
            page.screenshot(path=str(OUT / f'streamlit-{vp_name}-explorar.png'))

            _click_tab(page, 'Salvos')
            page.screenshot(path=str(OUT / f'streamlit-{vp_name}-salvos.png'))

            _click_tab(page, 'Ajustes')
            page.screenshot(path=str(OUT / f'streamlit-{vp_name}-ajustes.png'))

            page.close()
        browser.close()
    print(f'Capturas Streamlit salvas em {OUT}')


def _flutter_click(page, label: str) -> None:
    node = page.locator(f'flt-semantics[aria-label="{label}"]').first
    node.scroll_into_view_if_needed()
    node.click()
    page.wait_for_timeout(1800)


def capture_flutter() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch()
        for vp_name, vp in VIEWPORTS.items():
            page = browser.new_page(viewport=vp)
            page.goto(FLUTTER, wait_until='domcontentloaded')
            page.wait_for_timeout(15000)

            # Habilita a árvore de semântica para poder clicar por rótulo.
            page.evaluate(
                "() => document.querySelector('flt-semantics-placeholder')?.click()"
            )
            page.wait_for_timeout(3500)

            page.screenshot(path=str(OUT / f'flutter-{vp_name}-inicio.png'))
            _flutter_click(page, 'Bíblia')
            page.screenshot(path=str(OUT / f'flutter-{vp_name}-biblia.png'))
            _flutter_click(page, 'Estudos')
            page.screenshot(path=str(OUT / f'flutter-{vp_name}-estudos.png'))
            _flutter_click(page, 'Salvos')
            page.screenshot(path=str(OUT / f'flutter-{vp_name}-salvos.png'))
            _flutter_click(page, 'Ajustes')
            page.screenshot(path=str(OUT / f'flutter-{vp_name}-ajustes.png'))

            page.close()
        browser.close()
    print(f'Capturas Flutter salvas em {OUT}')


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--app', choices=['streamlit', 'flutter', 'both'], default='both')
    args = parser.parse_args()

    if args.app in ('streamlit', 'both'):
        capture_streamlit()
    if args.app in ('flutter', 'both'):
        capture_flutter()
    return 0


if __name__ == '__main__':
    sys.exit(main())
