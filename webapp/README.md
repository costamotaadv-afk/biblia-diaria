# Bíblia Diária — Web (Streamlit)

Porte do app Flutter **Bíblia Diária** para a web, mantendo o projeto Flutter
intocado. Os dados JSON de `assets/data` (66 livros, ~13 MB) são reutilizados
no lugar — sem duplicação.

## Executar

```bash
pip install -r requirements.txt   # streamlit, gTTS, pytest
streamlit run webapp/streamlit_app.py
```

Ou, para desenvolvimento local:

```bash
BIBLIA_PERSIST=1 streamlit run webapp/streamlit_app.py
```

## Testes

```bash
python -m pytest webapp/tests -q      # matriz de QA portada (57+ casos)
python -m compileall -q webapp        # sem erros de sintaxe
```

## Estrutura

```
webapp/
├── streamlit_app.py          # entrada: tema CSS, nav por abas, dispatch
├── core/                     # lógica pura portada 1:1 de lib/*.dart
│   ├── dados_seguros.py      # guardiões de JSON + versículo do dia (E1–E9, E13, B5, E16)
│   ├── leitura_natural.py    # referência/texto → fala natural (E6/E7/E10/E11/E12)
│   ├── catalogo_estudos.py   # recursos de estudo (EST1–EST8)
│   ├── contexto_historico.py # Salmos (CTX1–CTX7)
│   ├── config.py             # chave Pix (B3)
│   ├── formato_data.py       # datas pt-BR (sem locale/babel)
│   ├── data_source.py        # loaders @st.cache_data sobre assets/data
│   └── storage.py            # session_state + write-through JSON (BIBLIA_PERSIST)
├── ui/                       # 5 abas + painéis (paridade com lib/main.dart)
└── tests/                    # ports pytest da matriz de QA
```

## Decisões

- **Paridade total** nas 5 abas; apenas o AdMob foi removido (sem equivalente
  server-side na web).
- **TTS** via `gTTS(lang='pt-br')` → `st.audio` (uma voz pt-BR). O seletor de
  voz masculina/feminina do dispositivo vira um *toggle* de "leitura lenta".
  A reprodução é manual e não-contínua, como no app. O `gTTS` exige internet
  no servidor — a leitura/visualização de texto continua 100% offline.
- **Persistência**: `st.session_state` é a fonte da verdade; o write-through
  em `webapp/.state/prefs.json` só ocorre com `BIBLIA_PERSIST=1`. No Streamlit
  Cloud, o filesystem é efêmero e compartilhado entre usuários — recomendado
  manter `BIBLIA_PERSIST=0` (apenas sessão).
- **Fonte grande**: `font-size: 18.9px` na raiz (equivale ao `textScaler 1.18`).
- **Tema escuro**: CSS injetado (claro é o padrão em `.streamlit/config.toml`).
