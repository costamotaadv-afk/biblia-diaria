# -*- coding: utf-8 -*-
"""Gera o ícone do app Bíblia Diária (1024x1024) usando PIL.

Uso: python tool/gerar_icone.py
Saída: assets/icon/app_icon.png
"""
import os
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
OUT = os.path.join("assets", "icon", "app_icon.png")

# Paleta (índigo suave, coerente com o colorSchemeSeed 0xFF3F51B5)
AZUL_TOP = (63, 81, 181)      # #3F51B5
AZUL_BOTTOM = (48, 63, 159)   # #303F9F
ROXO_ACC = (92, 107, 192)     # #5C6BC0
BRANCO = (255, 255, 255)
OURO = (255, 213, 79)         # #FFD54F

def gradiente_vertical(draw, top, bottom):
    for y in range(SIZE):
        t = y / (SIZE - 1)
        cor = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        draw.line([(0, y), (SIZE, y)], fill=cor + (255,))

def main():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    grad = Image.new("RGBA", (SIZE, SIZE))
    dg = ImageDraw.Draw(grad)
    gradiente_vertical(dg, AZUL_TOP, AZUL_BOTTOM)
    img.paste(grad, (0, 0))

    draw = ImageDraw.Draw(img, "RGBA")

    # Livro aberto: duas páginas inclinadas
    cx = SIZE // 2
    pagina_w = 300
    altura = 430
    top_livro = 360
    fundo = top_livro + altura

    # Página esquerda (vira para a direita)
    draw.polygon(
        [
            (cx - 90, fundo),            # base central
            (cx - 90 - pagina_w, fundo),  # base esquerda
            (cx - 90 - pagina_w, top_livro),  # topo esquerda
            (cx - 90, top_livro - 40),    # topo central (levemente mais alto)
        ],
        fill=BRANCO + (255,),
        outline=OURO + (255,),
        width=8,
    )

    # Página direita (espelha)
    draw.polygon(
        [
            (cx + 90, fundo),
            (cx + 90 + pagina_w, fundo),
            (cx + 90 + pagina_w, top_livro),
            (cx + 90, top_livro - 40),
        ],
        fill=BRANCO + (255,),
        outline=OURO + (255,),
        width=8,
    )

    # Linha central (cruz do livro)
    draw.line(
        [(cx, top_livro - 40), (cx, fundo)],
        fill=AZUL_TOP + (255,),
        width=12,
    )

    # Coração central sobre o livro
    draw.polygon(
        [
            (cx, 620 + 70),
            (cx - 90, 600),
            (cx - 50, 540),
            (cx, 580),
            (cx + 50, 540),
            (cx + 90, 600),
        ],
        fill=(229, 57, 53, 255),  # vermelho
    )
    # Realce do coração com arcos
    draw.ellipse([cx - 70, 545, cx - 5, 625], fill=(229, 57, 53, 255))
    draw.ellipse([cx + 5, 545, cx + 70, 625], fill=(229, 57, 53, 255))

    # Garantia: redesenhar o triângulo para suavizar
    draw.polygon(
        [(cx, 635), (cx - 70, 585), (cx + 70, 585)],
        fill=(229, 57, 53, 255),
    )

    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.save(OUT, "PNG")
    print("Ícone gerado em", OUT, img.size)

if __name__ == "__main__":
    main()
