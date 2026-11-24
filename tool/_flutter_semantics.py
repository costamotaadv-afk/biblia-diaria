from __future__ import annotations

from playwright.sync_api import sync_playwright

URL = 'http://127.0.0.1:7357'

with sync_playwright() as p:
    b = p.chromium.launch()
    page = b.new_page(viewport={'width': 390, 'height': 844})
    page.goto(URL, wait_until='domcontentloaded')
    page.wait_for_timeout(15000)
    # Habilita a acessibilidade (semântica) para expor rótulos clicáveis.
    page.evaluate("() => document.querySelector('flt-semantics-placeholder')?.click()")
    page.wait_for_timeout(4000)
    info = page.evaluate(
        """() => {
            const nodes = [...document.querySelectorAll('flt-semantics')];
            const labels = nodes.map((n) => n.getAttribute('aria-label')).filter(Boolean);
            return { count: nodes.length, labels: labels.slice(0, 40) };
        }"""
    )
    print(info)
    b.close()
