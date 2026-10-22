# Publicação no Streamlit Community Cloud

Passo a passo para publicar o **Bíblia Diária — Web** gratuitamente e obter um
link público para encaminhar (formato `https://<nome-do-app>.streamlit.app`).

## Pré-requisitos

1. Conta no GitHub com este repositório publicado:
   <https://github.com/costamotaadv-afk/biblia-diaria>
2. Conta gratuita no [Streamlit Community Cloud](https://share.streamlit.io)
   (login com a mesma conta do GitHub).

## Arquivos já preparados neste projeto

| Arquivo | Finalidade |
| --- | --- |
| `webapp/streamlit_app.py` | Entrada do app (abas, tema, navegação). |
| `requirements.txt` (raiz) | Dependências Python (`streamlit`, `gTTS`, `pytest`). |
| `.streamlit/config.toml` (raiz) | Tema claro e servidor headless no Cloud. |
| `assets/data/**` | Dados bíblicos reutilizados (já versionados no Git). |

Não é necessário `packages.txt`: o `gTTS` gera o áudio MP3 via API e o player
`st.audio` o reproduz no navegador — sem dependências de sistema (ffmpeg etc.).

## Passo 1 — Enviar o código para o GitHub

Confirme que os arquivos da web estão commitados e empurrados:

```powershell
git add .streamlit/config.toml requirements.txt webapp docs/DEPLOY_STREAMLIT.md
git commit -m "Prepara publicação no Streamlit Cloud"
git push origin master
```

> Se `webapp/` ainda aparecer como "untracked" (`?? webapp/`), o comando acima
> resolve. A pasta `webapp/.state/` e `__pycache__/` já estão no `.gitignore`.

## Passo 2 — Criar o app no Streamlit Cloud

1. Acesse <https://share.streamlit.io> e clique em **"Create app"**.
2. Em **"Repository"**, escolha `costamotaadv-afk/biblia-diaria`.
3. Em **"Branch"**, escolha `master`.
4. Em **"Main file path"**, informe:

   ```text
   webapp/streamlit_app.py
   ```

5. (Opcional) Em **"App URL"**, escolha um subdomínio, ex.: `biblia-diaria`.
6. Clique em **"Deploy!"**.

O Streamlit Cloud vai instalar as dependências e publicar. Em ~1–2 minutos o
link estará disponível no topo da página.

## Link gerado

O link final terá o formato:

```text
https://biblia-diaria.streamlit.app
```

É esse link que você encaminha a quem quiser — funciona em qualquer navegador,
sem instalar nada.

## Link de compartilhamento (WhatsApp)

O botão "📲 Compartilhar no WhatsApp" (aba Início) usa o link centralizado em
`webapp/core/config.py` → `LINK_DOWNLOAD`. Deixe-o vazio enquanto o app não
estiver publicado: o botão fica oculto (não envia usuários para um endereço
morto). Ao publicar, defina:

```python
LINK_DOWNLOAD = 'https://biblia-diaria.streamlit.app'
```

O app Flutter usa o mesmo mecanismo em `lib/config.dart` → `linkDownloadApp`.

## Observações importantes

- **Persistência**: mantenha `BIBLIA_PERSIST=0` (padrão). No Cloud o filesystem
  é efêmero e compartilhado; favoritos/preferências valem por sessão.
- **Áudio (TTS)**: o `gTTS` precisa de internet **no servidor** (o Cloud tem).
  A leitura e visualização do texto continuam funcionando 100% mesmo sem rede.
- **Atualizações**: após cada `git push` no branch `master`, o Cloud reimplanta
  o app automaticamente.

## Testes antes de publicar

```powershell
python -m pytest webapp/tests -q      # 58+ casos (matriz de QA)
python -m compileall -q webapp        # sem erros de sintaxe
```
