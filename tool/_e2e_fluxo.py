from __future__ import annotations

from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    b = p.chromium.launch()
    page = b.new_page(viewport={'width': 1280, 'height': 800})
    page.goto('http://127.0.0.1:8501', wait_until='networkidle')
    page.wait_for_timeout(3000)
    ref = page.evaluate(
        "() => (document.querySelector('.bd-ref')?.innerText || '').trim()"
    )
    print('STREAMLIT_VERSE_REF:', ref)

    # Favorita o versículo do dia e confere em Salvos.
    page.get_by_role('button', name='⭐ Favoritar').first.click()
    page.wait_for_timeout(1500)
    page.locator('label[data-testid="stRadioOption"]:has-text("Salvos")').first.click()
    page.wait_for_timeout(2000)
    salvo_presente = page.evaluate(
        "(ref) => document.body.innerText.includes(ref)", ref
    )
    print('SALVO_PRESENTE:', salvo_presente)
    b.close()
