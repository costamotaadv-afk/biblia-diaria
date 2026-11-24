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
- **Aparência**: 3 temas (claro/escuro/sépia), escala de texto 100–160% (padrão
  118%) e espaçamento de linha 1,4–1,8 — espelhando `lib/tema.dart`. A fonte
  **Lora** é servida de `webapp/static/fonts/` (via `enableStaticServing`).
- **Navegação**: 5 abas como o Flutter; o acervo **Explorar** (Theographic,
  exclusivo do Streamlit) fica em Estudos → Explorar.
- **Paridade funcional**: busca na Bíblia, progresso de leitura, destaques e
  anotações foram portados de `lib/busca_biblia.dart`, `lib/progresso_leitura.dart`
  e `lib/destaques.dart`.

## Voz neural (opcional)

Por padrão o app usa **gTTS**. Para trocar por uma voz neural (licença comercial,
sem GPU), configure **uma** das variáveis de ambiente abaixo e reinicie:

```bash
# Google Cloud Text-to-Speech (voz pt-BR-Neural2-C)
TTS_PROVEDOR=google TTS_GOOGLE_API_KEY="SUA_CHAVE" streamlit run webapp/streamlit_app.py

# Azure Speech (voz pt-BR-FranciscaNeural)
TTS_PROVEDOR=azure TTS_AZURE_KEY="SUA_CHAVE" TTS_AZURE_REGION="eastus" streamlit run webapp/streamlit_app.py
```

- `TTS_VOZ` (opcional) troca a voz padrão do provedor.
- Sem essas variáveis, ou se a chamada neural falhar, o app cai para o **gTTS**
  automaticamente — a interface `falar*()` não muda.

O **F5-TTS** (TTS local com GPU) foi avaliado e **descartado**: licença CC-BY-NC
dos modelos e exigência de GPU são incompatíveis com este SaaS.

## Paridade visual e funcional (Flutter × Streamlit)

O webapp reproduz a identidade visual do app Flutter (`lib/tema.dart`): paleta
dourado/creme, tipografia **Lora** (versículos/estudos), cartões com raio 18,
botões de 52 px (raio 14), navegação em pílulas e títulos centrados. O CSS fica
centralizado em `webapp/ui/tema.py` e usa seletores validados no DOM do
Streamlit 1.56 (`button[kind=...]`, `label[data-testid="stRadioOption"]`,
`st.container(key=...)` → `.st-key-*`, `st.pills` → `button[role="radio"]`).

Capturas comparativas (mesma largura e mesmos dados) são geradas por
`tool/capturar_telas.py` (Playwright) em `docs/capturas/`, nos viewports
1280×800 e 390×844.

### Diferenças remanescentes (vs. Flutter)

- **AdMob**: ausente na web (igual nos dois).
- **TTS**: uma voz pt-BR do servidor (gTTS/neural) em vez das vozes do aparelho;
  sem seletor masculino/feminino; áudio inline, sem FAB global de play/pause.
- **Compartilhar**: link do WhatsApp em vez da folha nativa.
- **Explorar** (Theographic) existe apenas no Streamlit, em Estudos → Explorar.
- **Persistência**: só preferências são persistidas; a navegação é por sessão
  (o app abre sempre na aba Início, como o Flutter).
- **Chrome do Streamlit** (menu/rodapé/toolbar) é ocultado para parecer app;
  ícones emoji em vez dos Material Symbols.
