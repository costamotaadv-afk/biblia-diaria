"""Botão de copiar via Clipboard API do navegador (degradação graciosa)."""

import html
import json

import streamlit.components.v1 as components


def botao_copiar(texto: str, label: str = 'Copiar', altura: int = 52, primario: bool = False) -> None:
    """Renderiza um botão que copia ``texto`` (altura em px; padrão 52).

    ``primario=True`` usa o estilo preenchido (dourado) — ações de destaque
    (ex.: chave Pix); ``False`` usa o estilo contornado neutro.
    """
    dados = json.dumps(texto or '', ensure_ascii=False)
    label_seguro = html.escape(label)
    cor_fundo = 'var(--bd-primary, #7A5A1E)' if primario else 'transparent'
    cor_texto = 'var(--bd-on-primary, #FFFFFF)' if primario else 'var(--bd-on-surface, #2A2620)'
    borda = (
        '1px solid var(--bd-primary, #7A5A1E)'
        if primario
        else '1px solid var(--bd-outline, #8C8272)'
    )
    html_str = (
        '<button onclick="navigator.clipboard.writeText('
        + dados
        + ').then(function(){this.innerText='
        + json.dumps('Copiado!', ensure_ascii=False)
        + ';}.bind(this)).catch(function(){this.innerText='
        + json.dumps('Copie manualmente', ensure_ascii=False)
        + ';}.bind(this))" style="width:100%; padding:10px 16px; '
        + f'border:{borda}; border-radius:14px; background:{cor_fundo}; '
        + f'color:{cor_texto}; cursor:pointer; font-size:15px; font-weight:600; '
        + 'min-height:52px;">'
        + label_seguro
        + '</button>'
    )
    components.html(html_str, height=altura + 12)

