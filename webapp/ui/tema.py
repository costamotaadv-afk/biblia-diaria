"""Tema visual do webapp (porte das paletas/tipografia de ``lib/tema.dart``).

Centraliza cores, tipografia e espaçamentos. O CSS injetado estiliza os
componentes nativos do Streamlit 1.56 (seletores validados no DOM renderizado)
para aproximar o visual do app Flutter. As funções puras (contraste/escala)
ficam em ``lib/tema.dart`` — aqui só declaramos os tokens e o CSS.
"""

# Paletas espelhando lib/tema.dart (claro/escuro/sépia).
PALETAS = {
    'claro': {
        'surface': '#FDFBF7',
        'surface_lowest': '#FFFCF5',
        'surface_low': '#F7F1E6',
        'surface_container': '#F2EADD',
        'surface_high': '#EDE3D3',
        'surface_highest': '#E7DCC9',
        'on_surface': '#2A2620',
        'on_surface_variant': '#5A5245',
        'primary': '#7A5A1E',
        'on_primary': '#FFFFFF',
        'primary_container': '#F3E3C3',
        'on_primary_container': '#2B1F06',
        'secondary': '#A75A38',
        'secondary_container': '#F6DDD1',
        'tertiary': '#2F4A6B',
        'tertiary_container': '#D6E3F5',
        'outline': '#8C8272',
        'outline_variant': '#E3D8C6',
        'error': '#BA1A1A',
        'card_bg': '#F7F1E6',
    },
    'escuro': {
        'surface': '#121212',
        'surface_lowest': '#0D0D0D',
        'surface_low': '#171717',
        'surface_container': '#1E1E1E',
        'surface_high': '#262626',
        'surface_highest': '#2E2E2E',
        'on_surface': '#E0E0E0',
        'on_surface_variant': '#BDB6AC',
        'primary': '#E3C27E',
        'on_primary': '#2A1F06',
        'primary_container': '#4A3A16',
        'on_primary_container': '#F5E3BE',
        'secondary': '#E9A98C',
        'secondary_container': '#54301F',
        'tertiary': '#A8C4E6',
        'tertiary_container': '#24405C',
        'outline': '#8A8174',
        'outline_variant': '#3A3A3A',
        'error': '#FFB4AB',
        'card_bg': '#171717',
    },
    'sepia': {
        'surface': '#F4ECD8',
        'surface_lowest': '#FAF4E6',
        'surface_low': '#F2E8D0',
        'surface_container': '#ECE0C4',
        'surface_high': '#E6D8B8',
        'surface_highest': '#DFCFAC',
        'on_surface': '#4A3A28',
        'on_surface_variant': '#5B4636',
        'primary': '#7A5A1E',
        'on_primary': '#FFFFFF',
        'primary_container': '#EAD9B4',
        'on_primary_container': '#2B1F06',
        'secondary': '#A75A38',
        'secondary_container': '#EED3C4',
        'tertiary': '#2F4A6B',
        'tertiary_container': '#D6E3F5',
        'outline': '#8A7A5E',
        'outline_variant': '#D9C9A6',
        'error': '#BA1A1A',
        'card_bg': '#F2E8D0',
    },
}

# Regras CSS fixas (referenciam as variáveis ``--bd-*`` definidas em ``:root``).
# Divididas em duas partes por limite de tamanho do editor.
_CSS_A = """
@font-face {
  font-family: 'Lora';
  font-style: normal;
  font-weight: 400;
  src: url('/app/static/fonts/Lora-Regular.ttf') format('truetype');
}
@font-face {
  font-family: 'Lora';
  font-style: normal;
  font-weight: 600;
  src: url('/app/static/fonts/Lora-SemiBold.ttf') format('truetype');
}
@font-face {
  font-family: 'Lora';
  font-style: italic;
  font-weight: 400;
  src: url('/app/static/fonts/Lora-Italic.ttf') format('truetype');
}

/* Chrome do Streamlit: remover o que não é do app */
#MainMenu, footer,
[data-testid="stDecoration"],
[data-testid="stToolbar"],
[data-testid="stStatusWidget"] {
  display: none !important;
}
[data-testid="stHeader"] {
  background: var(--bd-surface) !important;
  border-bottom: 1px solid var(--bd-outline-variant);
}

[data-testid="stAppViewContainer"],
[data-testid="stMainBlockContainer"] {
  background-color: var(--bd-surface) !important;
  color: var(--bd-on-surface);
}
[data-testid="stMarkdownContainer"], p, li {
  color: var(--bd-on-surface);
}
h1, h2, h3, h4 { font-weight: 700 !important; color: var(--bd-on-surface) !important; }
h1 { font-size: 1.5rem !important; }
h2 { font-size: 1.3rem !important; }
h3 { font-size: 1.15rem !important; }
h4 { font-size: 1.05rem !important; }

/* Largura máxima estilo app (desktop) + respiro no mobile */
[data-testid="stMainBlockContainer"] {
  max-width: 760px;
  margin: 0 auto;
  padding-left: 16px !important;
  padding-right: 16px !important;
  padding-bottom: 3rem !important;
}

/* Título do app (AppBar equivalente) */
.app-title {
  font-size: 1.25rem;
  font-weight: 700;
  text-align: center;
  color: var(--bd-on-surface);
  padding: 0.4rem 0 0.2rem;
}

/* Navegação: radio -> barra de pílulas */
[data-testid="stRadioGroup"] {
  display: flex !important;
  flex-wrap: wrap;
  gap: 6px;
  justify-content: center;
}
[data-testid="stRadioGroup"] label[data-testid="stRadioOption"] {
  flex: 1 1 auto;
  justify-content: center;
  min-height: 44px;
  padding: 8px 12px;
  margin: 0 !important;
  border: 1px solid var(--bd-outline-variant);
  border-radius: 999px;
  background: transparent;
}
[data-testid="stRadioGroup"] label[data-testid="stRadioOption"] > div:first-child {
  display: none !important;
}
[data-testid="stRadioGroup"] label[data-testid="stRadioOption"]:has(input:checked) {
  background: var(--bd-primary-container);
  border-color: var(--bd-primary);
  font-weight: 700;
}
[data-testid="stRadioGroup"] label[data-testid="stRadioOption"]:has(input:checked) p,
[data-testid="stRadioGroup"] label[data-testid="stRadioOption"]:has(input:checked) span {
  color: var(--bd-primary);
}

/* Botões */
button[kind="primary"], a[kind="primary"] {
  background-color: var(--bd-primary) !important;
  border: 1px solid var(--bd-primary) !important;
  color: var(--bd-on-primary) !important;
}
button[kind="secondary"], a[kind="secondary"] {
  background-color: transparent !important;
  border: 1px solid var(--bd-outline) !important;
  color: var(--bd-on-surface) !important;
}
button[kind="tertiary"], a[kind="tertiary"] {
  background: transparent !important;
  border: none !important;
  color: var(--bd-primary) !important;
}
button[kind="primary"], button[kind="secondary"], button[kind="tertiary"],
a[kind="primary"], a[kind="secondary"], a[kind="tertiary"] {
  min-height: 52px;
  border-radius: 14px !important;
  font-weight: 600;
}
"""

_CSS_B = """
/* Inputs */
[data-testid="stTextInputField"] input,
[data-testid="stSelectbox"] [data-rac] {
  border-radius: 14px !important;
  border: 1px solid var(--bd-outline) !important;
  min-height: 48px;
  background-color: var(--bd-surface-lowest) !important;
  color: var(--bd-on-surface) !important;
}
[data-testid="stWidgetLabel"] p {
  color: var(--bd-on-surface-variant) !important;
  font-weight: 600;
}

/* Cartões (containers com chave prefixo card_) */
[class*="st-key-card_"] {
  background: var(--bd-card-bg) !important;
  border: 1px solid var(--bd-outline-variant) !important;
  border-radius: 18px !important;
  padding: 18px !important;
}
.st-key-card_inicio_versiculo {
  background: linear-gradient(135deg, var(--bd-primary-container), var(--bd-secondary-container)) !important;
  border-radius: 24px !important;
}

/* Expander como cartão */
[data-testid="stExpander"] {
  border: 1px solid var(--bd-outline-variant) !important;
  border-radius: 14px !important;
  background: var(--bd-card-bg) !important;
}
[data-testid="stExpander"] summary { font-weight: 600; }

/* Pills (Estudos/Explorar) — st.pills renderiza como button[role=radio] */
button[role="radio"] {
  border-radius: 999px !important;
  border: 1px solid var(--bd-outline-variant) !important;
  background: transparent !important;
  min-height: 44px !important;
  padding: 6px 14px !important;
  color: var(--bd-on-surface) !important;
  font-weight: 600;
}
button[role="radio"][aria-checked="true"],
button[role="radio"][aria-pressed="true"] {
  background: var(--bd-primary-container) !important;
  border-color: var(--bd-primary) !important;
  color: var(--bd-primary) !important;
  font-weight: 700;
}

/* Progresso */
[role="progressbar"] { border-radius: 6px !important; }

/* Divisores */
hr { border-color: var(--bd-outline-variant) !important; }

/* Tipografia específica */
.bd-verse {
  font-family: 'Lora', Georgia, 'Times New Roman', serif !important;
  font-size: 1.09rem;
  line-height: var(--bd-line-height);
  letter-spacing: 0.1px;
  color: var(--bd-on-surface);
}
.bd-study-body {
  font-family: 'Lora', Georgia, 'Times New Roman', serif !important;
  font-size: 1.06rem;
  line-height: var(--bd-line-height);
  color: var(--bd-on-surface);
}
.bd-quote {
  font-family: 'Lora', Georgia, 'Times New Roman', serif !important;
  font-style: italic;
  font-size: 1.22rem;
  line-height: 1.6;
  color: var(--bd-on-surface);
}
.bd-ref { color: var(--bd-primary) !important; font-weight: 700; font-size: 0.9rem; text-align: right; }
.bd-rotulo { color: var(--bd-primary) !important; font-weight: 700; font-size: 0.81rem; letter-spacing: 1.2px; }
.bd-data { color: var(--bd-primary) !important; font-weight: 600; text-align: center; }
.bd-section { font-weight: 700; color: var(--bd-on-surface); }
.bd-sub { color: var(--bd-primary) !important; font-weight: 600; }

/* Versículos como linhas tocáveis (cada verso é um container .st-key-verse_*) */
[class*="st-key-verse_"] {
  border-radius: 10px !important;
  margin: 2px 0 !important;
}
[class*="st-key-verse_"] button {
  text-align: left !important;
  justify-content: flex-start !important;
  white-space: normal !important;
  height: auto !important;
  min-height: auto !important;
  padding: 8px 12px !important;
  border: none !important;
  background: transparent !important;
  font-family: 'Lora', Georgia, 'Times New Roman', serif !important;
  font-size: 1.09rem !important;
  line-height: var(--bd-line-height) !important;
  font-weight: 400 !important;
  color: var(--bd-on-surface) !important;
}
[class*="st-key-verse_"] button:hover { background: var(--bd-surface-container) !important; }
[class*="st-key-verse_"] button p { color: var(--bd-on-surface); }
[class*="st-key-verse_"] button strong { color: var(--bd-primary); font-size: 0.78rem; }

/* Resultados de busca como linhas */
[class*="st-key-busca_resultados"] button {
  text-align: left !important;
  justify-content: flex-start !important;
  white-space: normal !important;
  height: auto !important;
  min-height: 48px !important;
  padding: 8px 12px !important;
}
"""


def css(modo: str, escala: float, altura_linha: float) -> str:
    """Devolve o bloco ``<style>`` com o tema (claro/escuro/sépia)."""
    p = PALETAS.get(modo, PALETAS['claro'])
    font_size = round(16.0 * escala, 2)

    root = f""":root {{
  --bd-font-size: {font_size}px;
  --bd-line-height: {altura_linha};
  --bd-surface: {p['surface']};
  --bd-surface-lowest: {p['surface_lowest']};
  --bd-surface-low: {p['surface_low']};
  --bd-surface-container: {p['surface_container']};
  --bd-surface-high: {p['surface_high']};
  --bd-surface-highest: {p['surface_highest']};
  --bd-on-surface: {p['on_surface']};
  --bd-on-surface-variant: {p['on_surface_variant']};
  --bd-primary: {p['primary']};
  --bd-on-primary: {p['on_primary']};
  --bd-primary-container: {p['primary_container']};
  --bd-on-primary-container: {p['on_primary_container']};
  --bd-secondary: {p['secondary']};
  --bd-secondary-container: {p['secondary_container']};
  --bd-tertiary: {p['tertiary']};
  --bd-tertiary-container: {p['tertiary_container']};
  --bd-outline: {p['outline']};
  --bd-outline-variant: {p['outline_variant']};
  --bd-error: {p['error']};
  --bd-card-bg: {p['card_bg']};
}}
html {{ font-size: {font_size}px; }}
"""

    return f'<style>{root}{_CSS_A}{_CSS_B}</style>'


