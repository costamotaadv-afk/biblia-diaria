# Quickstart — Recursos de Estudo do Texto Bíblico

Guia rápido para **validar** e **manter** a feature 002.

## 1. Rodar a suíte (gate da constituição)

O Flutter deste projeto usa Puro (env `stable`). Se `flutter` não estiver no PATH:

```powershell
& "$env:USERPROFILE\.puro\envs\stable\flutter\bin\flutter.bat" analyze
& "$env:USERPROFILE\.puro\envs\stable\flutter\bin\flutter.bat" test
```

Esperado: `analyze` sem novas issues; `test` verde (inclui
`test/catalogo_estudos_test.dart`, casos EST1–EST6).

## 2. Rodar o app

```powershell
# Web (servidor local do projeto)
powershell -ExecutionPolicy Bypass -File tool\servir_app.ps1

# ou direto
& "$env:USERPROFILE\.puro\envs\stable\flutter\bin\flutter.bat" run -d windows
```

## 3. Validar manualmente (por user story)

- **US1/US2**: abra **Bíblia → Gênesis → capítulo 1**. O versículo `Gênesis 1:1`
  deve exibir o indicador de estudo; toque nele e confira a nota/comentário. Abra
  o cabeçalho do capítulo para ver recursos de capítulo/livro.
- **US3**: abra a aba **Estudos**; filtre por tipo (ex.: "Sermão") e por livro e
  confira a lista; toque em um recurso para abrir o painel.
- **US4**: toque em **Salvar** em um recurso; vá em **Salvos** e confira a seção
  de recursos de estudo; reinicie o app e confirme que permanece.
- **US5**: com voz pt-BR disponível, toque em **Ouvir** em um recurso e valide a
  leitura (manual, para ao fim).

## 4. Adicionar/editar conteúdo (mantenedor — UC-08)

Não é preciso mexer em código. Em `assets/data/`:

1. **Índice** (`estudos_indice.json`): adicione a entrada leve
   (`id`, `tipo`, `titulo`, `ref`, `livro`, `tema`).
2. **Detalhe** (`estudos/<Livro>.json`): adicione o recurso completo (mesmo `id`,
   mais `corpo` e, se houver, `fonte`).

Regras:
- `ref` aceita `"Livro cap:vers"`, `"Livro cap"` ou `"Livro"`.
- `id` deve ser idêntico entre índice e detalhe.
- `tipo` conhecidos: `nota`, `comentario`, `artigo`, `sermao`, `palestra`,
  `momento_historico` (outros valores funcionam com rótulo genérico).
- O `id` nunca deve ser reutilizado com sentido diferente (favoritos guardam o
  `id`).

## 5. Checklist de aceite da feature

- [ ] Recursos aparecem offline, sem rede.
- [ ] Painel abre de forma perceptível imediata e não bloqueia a leitura.
- [ ] Mesma referência → mesmo conjunto e ordem de recursos (determinismo).
- [ ] Dados ausentes/corrompidos → fallback amigável, sem erro técnico.
- [ ] Recursos salvos sobrevivem ao reinício (zero perda).
- [ ] Crédito exibido sempre que houver fonte declarada.
- [ ] 320 px × fonte 1.18 sem overflow no painel e na biblioteca.
- [ ] Novo recurso adicionado só por edição de dados.
