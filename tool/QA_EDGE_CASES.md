# 🧪 Matriz de Cenários de Edge Case — Bíblia Diária

**Artefato de QA** — Checklist de regressão e documentação de risco.
Atualizado em: 2026 (acompanha o código-fonte; revise a cada release).

**Regras de negócio relevantes extraídas do código:**
- Conteúdo 100% offline via JSON dividido (66 livros, ~13MB), carregado sob demanda com cache em memória (`_livrosCache`) e deduplicação de futures (`_futuresLivros`).
- Versículo do dia determinístico: `dia % 66` escolhe livro; `(dia ~/ 66) % cap.length` escolhe capítulo; `(dia ~/ (66 * cap.length)) % vers.length` escolhe versículo.
- Favoritos (versículos/capítulos) persistidos como `Set<String>` no `SharedPreferences`.
- TTS com máquina de estados `_falando / _pausado / _leituraAtiva`, leitura manual não-contínua.
- Tema escuro + fonte grande (textScaler 1.18) para idosos.
- Pix por e-mail fixo (`costamota@gmail.com`), copiado via Clipboard.
- AdMob: banner adaptativo só em Android/iOS (IDs de teste atualmente).
- Recursos de estudo (notas, comentários, artigos, sermões, palestras, momentos históricos) via índice leve + detalhe por livro, com favoritos na chave `favoritos_estudos`.

---

## 1️⃣ Limites de Entrada de Dados (Mínimos, Máximos, Tipos inválidos)

**E1. `indice.json` vazio (0 livros)**
- **Input:** `[]` no arquivo do índice.
- **Esperado:** `_indice = []`; tela "Bíblia" vazia; Home mostra *"Carregando conteúdo..."* (fallback do `_conteudoDoDia`). Sem crash.
- **Impacto se falhar:** `_nomeLivroDoDia = null` → `indice[dia % 0]` geraria `RangeError` (divisão por zero em `dia % indice.length` com `length == 0`). O teste atual valida 66 livros, mas não o caso de deploy com arquivo corrompido/truncado.
- **Status:** ✅ Coberto por `test/limites_dados_test.dart` (livro nulo → fallback "Carregando conteúdo...").

**E2. Livro sem campo `capitulos` ou `nome` nulo no índice**
- **Input:** `[{"nome": null}]` ou `[{"nome":"X"}]` (sem `capitulos`).
- **Esperado:** subtítulo "0 capítulos" (`?? 0`); ao expandir, tenta carregar `null.json` → falha graciosa *"Não foi possível carregar este livro."*
- **Impacto se falhar:** `nomeLivroDoDia = 'null'`, `indice[i]['nome']` como `'null'` no TTS/leitura → referências absurdas lidas em voz alta, confundindo o usuário idoso.
- **Status:** ✅ Coberto por `test/limites_dados_test.dart` (livro nulo → fallback; subtítulo usa `?? 0`).

**E3. Livro com `capitulos` como **objeto** (tipo errado) em vez de lista**
- **Input:** `{"nome":"Gênesis","capitulos": {"errado": true}}`.
- **Esperado:** cast `(livro['capitulos'] as List?)` lança `TypeError` **dentro do builder do FutureBuilder** (fora do try/catch de `_carregarLivroMap`).
- **Status:** ✅ Corrigido com cast seguro `comoLista` em `lib/dados_seguros.dart` (usado em `main.dart`) + coberto por `test/limites_dados_test.dart`.
- **Impacto se falhar:** tela vermelha em debug / tela branca em release ao abrir o livro. É a falha com maior severidade de dados: **crash não tratado**. Falha de QA aqui = app inutilizável para 1 dos 66 livros sem mensagem amigável.

**E4. Capítulo com `versiculos` vazio**
- **Input:** `{"numero":5,"versiculos":[]}`.
- **Esperado:** `_conteudoDoDia` retorna *"Sem conteúdo bíblico disponível."*; leitura do capítulo retorna cedo (`texto == null → return`).
- **Impacto se falhar:** tentativa de ler `versiculos[0]` → `RangeError` no versículo do dia (bug latente se um capítulo for truncado na edição do JSON).
- **Status:** ✅ Coberto por `test/limites_dados_test.dart` (versículos vazios → "Sem conteúdo").

**E5. Versículo com `texto` vazio ou só espaços**
- **Input:** `{"numero":1,"texto":"   "}`.
- **Esperado:** o teste `dados_biblicos_test` já exige `trim().isNotEmpty` — mas só em execução de teste; em produção o texto vazio é renderizado como `""...""` e o TTS lê só a referência.
- **Impacto se falhar:** versículo do dia vazio em produção → confiança do usuário destruída; necessidade de hotfix de dados.

**E6. Versículo/capítulo com `numero` = 0, negativo, string `"abc"` ou ausente**
- **Input:** `{"numero":"abc","texto":"..."}`.
- **Esperado:** `numeroPorExtenso("abc")` → `int.tryParse` falha → devolve `"abc"`; TTS lê "abc". `chave` vira `"Gênesis abc:null"`. Sem crash.
- **Impacto se falhar:** favoritos com chaves inválidas que nunca casam em `_buscarTextoVersiculo` → "Conteúdo não encontrado." para sempre (perda silenciosa de favorito do usuário).

**E7. Capítulo/versículo com número > 999 (limite de `escreverNumero`)**
- **Input:** `"1000"` (não existe na Bíblia, mas JSON pode ser malformado).
- **Esperado:** `escreverNumero` retorna o dígito cru `"1000"` → TTS lê como número. Sem crash.
- **Impacto se falhar:** se o TTS interpretar "1000" como horário/telefone, a leitura soa errada; teste deve garantir fallback textual.
- **Status:** ✅ Corrigido (`numeroPorExtenso`/`escreverNumero` devolvem o literal) + coberto por `test/edge_cases_e10_test.dart`.

**E8. `mensagens.json` vazio**
- **Input:** `[]`.
- **Esperado:** fallback *"Deus te fortaleça neste dia."* (já implementado). ✅
- **Impacto se falhar:** card "Mensagem para você" vazio — perda de feature sem erro visível.

**E9. `mensagens.json` com itens não-string (número, objeto, null)**
- **Input:** `[123, {"a":1}, null]`.
- **Esperado:** `'$m'` converte → `"123"`, `"Instance of '_Map'"`, `"null"` passam pelo filtro `trim().isNotEmpty` → **mensagens garbage exibidas**.
- **Impacto se falhar:** mensagem "Instance of '_Map'" na Home — parece bug de tela inteiro, mas é dado inválido não validado.

**E10. ⚠️ Livro com prefixo numérico no TTS (`referenciaParaLeitura`) — BUG REAL**
- **Input:** `"1 Coríntios 2:3"` (e `1 João 3:16`, `2 Reis 4:1`, etc.).
- **Esperado:** leitura natural *"Primeira Coríntios, capítulo dois, versículo três"*.
- **Comportamento original (falha):** `split(RegExp(r'[\s:]+'))` → `["1","Coríntios","2","3"]` → primeiro int vira **capítulo=1**, segundo vira **versículo=2** → o número do livro é engolido: *"Coríntios, capítulo um, versículo dois"*. **A referência é lida errada** (e o `"3"` é descartado).
- **Status:** ✅ Corrigido + coberto por `test/edge_cases_e10_test.dart`.
- **Impacto se falhar:** o dia em que o versículo cair em um dos 12 livros com prefixo numérico (1 Samuel, 2 Reis, 1/2/3 João…) o app anuncia o texto errado ao idoso — **defeito de acessibilidade de alta severidade, disparado por dado 100% válido**.

**E11. Referência cruzada interna com 4 dígitos (regex de `textoParaLeituraNatural`)**
- **Input:** texto contendo `"Salmos 1190:12"` (malformado) ou abreviatura `"1 Co 2:3"`.
- **Esperado:** `RegExp(r'([A-Za-zÀ-ÿ]+)\s+(\d{1,3}):(\d{1,3})')` não casa `1190` (4 dígitos) → TTS lê `"1190:12"` como horário. Para `"1 Co 2:3"`, casa `"Co 2:3"` e **perde o "1"** do livro.
- **Impacto se falhar:** leitura incoerente; teste deve validar o mapeamento de referências cruzadas dentro dos capítulos longos (Salmos, Isaías).
- **Status:** ✅ Documentado (4 dígitos ficam literais, sem virar horário) + coberto por `test/edge_cases_e10_test.dart`.

**E12. Capítulo gigante no TTS (Salmos 119 — 176 versículos)**
- **Input:** tocar "Ouvir capítulo" em Salmos 119 (~4.000+ caracteres).
- **Esperado:** engine TTS pode truncar silenciosamente; `setCompletionHandler` dispara antes do fim → leitura "termina" incompleta.
- **Impacto se falhar:** usuário acredita ter ouvido o capítulo inteiro quando só ouviu metade — risco de conteúdo religioso truncado. Teste de estresse: medir tempo de fala vs. texto esperado.
- **Status:** ✅ Corrigido (`dividirTextoParaFala` divide em segmentos na pontuação) + coberto por `test/edge_cases_e10_test.dart`.

**E13. Relógio do aparelho antes de 2024 (dias negativos) e datas extremas**
- **Input:** `DateTime(2023-06-15)` → `_diasDesdeEpoca` negativo.
- **Esperado:** Dart usa módulo euclidiano (`-5 % 66 == 61`) → **sem crash**, mas o "versículo do dia" aponta para conteúdo determinístico do futuro/passado errado. Data ano 9999 → int de precisão arbitrária, sem overflow.
- **Impacto se falhar:** se fosse linguagem/divisor com módulo truncado, `RangeError`; aqui o risco é **conteúdo incorreto** para usuários com relógio mal configurado (comum em idosos).
- **Status:** ✅ Coberto por `test/limites_dados_test.dart` (dias negativos e ano 9999 via `diasDesdeEpoca`).

**E14. Favorito órfão (livro removido/renomeado entre versões de dados)**
- **Input:** chave salva `"Cântico dos Cânticos 1"` quando o índice agora diz `"Cânticos"`.
- **Esperado:** `_nomeLivroDaChave` (busca no índice invertido) → null → Future `null` → exibe *"Conteúdo não encontrado."* e desabilita "Ouvir". ✅ Gracioso.
- **Impacto se falhar:** se a busca de prefixo não achasse, a tela Salvos travaria em "Carregando versículo..." para sempre (estado pendente sem timeout).

**E15. Volume máximo de favoritos (1000+ itens na tela Salvos)**
- **Input:** 1000+ chaves salvas.
- **Esperado:** `_montarTelaSalvos` usa `ListView(children:)` **não-lazy** e cada item faz varredura linear `O(versículos totais)` em `_buscarTextoVersiculo` → O(N×31100).
- **Impacto se falhar:** congelamento de UI (jank) em aparelho básico; em casos extremos, OOM. **Teste de estresse recomendado**: 500/1000/5000 favoritos + medir frame budget.
- **Status:** ✅ Coberto por `test/estresse_e15_test.dart` (carga mista + remoção no meio).

---

## 2️⃣ Erros de Estado e Concorrência

**C1. Duplo-toque em "Ouvir versículo" (speak concorrente)**
- **Input:** dois taps em <100ms em versículos diferentes.
- **Esperado:** ambos chamam `_iniciarLeitura` → `await _tts.stop()` em série → "último vence"; o `setState` duplo é inofensivo.
- **Impacto se falhar:** o 2º `_tts.speak` pode ser cancelado pelo stop do 1º que ainda não terminou → **nenhum som** e estado `_leituraAtiva=true` travado com FAB flutuante.

**C2. Taps rápidos em Play/Pause durante transição (estado stale)**
- **Input:** sequência pause→play→pause em <200ms.
- **Esperado:** `_alternarPlayPause` lê `_falando/_pausado` **antes** do `await _tts.pause()`; dois cliques podem gravar estado desatualizado.
- **Impacto se falhar:** FAB mostra ícone de "pause" mas o TTS está parado (ou vice-versa) → desorientação do usuário idoso. Requer debounce/bloqueio durante `await`.

**C3. Iniciar capítulo enquanto um versículo está falando**
- **Input:** "Ouvir versículo" + imediatamente "Ouvir capítulo" do mesmo livro.
- **Esperado:** `_iniciarLeitura` faz `await _tts.stop()` antes do novo `speak` → substituição limpa.
- **Impacto se falhar:** vozes sobrepostas ou leitura dupla; teste deve verificar que exatamente **um** áudio está ativo.

**C4. Duplo-toque em "Salvar versículo" (race de persistência)**
- **Input:** dois taps no ícone de favorito em <100ms.
- **Esperado:** ambos fazem `await SharedPreferences.getInstance()` e mutam o mesmo `Set`; `setStringList` pode gravar em ordem invertida → estado final divergente entre memória e disco.
- **Status:** ✅ Mitigado com fila serializada de escrita + coberto por `test/concurrency_c4_test.dart`.
- **Impacto se falhar:** favorito que o usuário vê salvo some após reiniciar o app (ou vice-versa) → **perda de dados do usuário**. Teste: double-tap + reinício + conferência.

**C5. Falha transiente no carregamento de livro → sem retry**
- **Input:** `rootBundle.loadString` falha uma vez (I/O, web cache) em `Gênesis`.
- **Esperado:** `_carregarLivroMap` retorna `null`; mas `_futuresLivros['Gênesis']` **fica resolvido com null para sempre** → retry nunca acontece até reiniciar.
- **Impacto se falhar:** livro aparece permanentemente como *"Não foi possível carregar"* mesmo após rede/arquivo se recuperarem. Falha de resiliência: exige `FutureBuilder` refazer ou limpar future em erro.
- **Status:** ✅ Corrigido com `CacheDeLivros` (falha remove o future → retry) + coberto por `test/cache_livros_test.dart`.

**C6. Expandir os 66 livros (estado de memória máxima)**
- **Input:** usuário expande todos os livros da aba Bíblia (ou automação faz `tap` em todos).
- **Esperado:** a lista é **lazy** (`ListView.builder` com estado de expansão `_livrosExpandidos`):
  cada livro vira linhas planas de capítulo/versículo montadas só quando entram na viewport.
  Antes, `maintainState: true` + `Column` não-lazy montavam milhares de `ListTile` vivos num único
  frame (Salmos → ~2.400 `ListTile`).
- **Impacto se falhar:** OOM em aparelho Android de entrada; web pode travar. Teste de estresse: monitorar RSS/heap durante expansão sequencial.
- **Status:** ✅ Corrigido (lista lazy em `lib/main.dart`) + testado por `test/estresse_c6_test.dart`.

**C7. Troca de aba durante carregamento de livro**
- **Input:** expandir livro → trocar para "Salvos" antes do `FutureBuilder` completar.
- **Esperado:** `_assegurarLivro` continua em background e preenche cache; sem `setState` pós-dispose (guardado por `mounted`).
- **Impacto se falhar:** exceção "setState called after dispose" → crash em debug. O guard `mounted` existe mas deve ser coberto por teste para regressão.
- **Status:** ✅ Coberto por `test/troca_aba_c7_test.dart` (guard `mounted` + lista lazy).

**C8. Rotação de tela durante leitura TTS / banner**
- **Input:** girar o aparelho com leitura ativa e banner carregado.
- **Esperado:** `_larguraSolicitada` muda → `didChangeDependencies` recarrega banner; TTS continua (audível, independente de UI).
- **Impacto se falhar:** banner antigo não-disposto (`_bannerAd?.dispose()` é assíncrono) → vazamento de memória do SDK de anúncios; leitura perde estado de pause.
- **Status:** ✅ Coberto por `test/rotacao_c8_test.dart` (rotação recarrega o banner sem exceção).

**C9. Banner: falha de `load()` / `MissingPluginException` / dispose durante load**
- **Input:** emulador sem Google Play Services, ou toggle de aba durante `await banner.load()`.
- **Esperado:** `MissingPluginException` tratado só em `getCurrentOrientationAnchoredAdaptiveBannerAdSize`; `banner.load()` **não tem try/catch** → `PlatformException` vira exceção assíncrona não tratada.
- **Status:** ✅ Corrigido (try/catch em `banner.load()` em `banner_anuncio.dart`) + coberto por `test/banner_c9_test.dart` (load lança `PlatformException`).
- **Impacto se falhar:** tela vermelha em debug ao navegar entre abas; risco de crash em release para dispositivos sem GMS. Teste: injetar falha de load em 100% dos requests.

**C10. `MobileAds.initialize()` sem Google Play Services — ⚠️ startup crash**
- **Input:** dispositivo Android sem GMS (China, emulador sem API do Google), com `suportaAdMob == true`.
- **Esperado:** `main()` faz `await MobileAds.instance.initialize()` **sem try/catch** → `PlatformException` aborta o app **antes do runApp**.
- **Status:** ✅ Corrigido com `inicializarAdMob()` (try/catch + degradação graciosa) + coberto por `test/platform_c10_c11_test.dart`.
- **Impacto se falhar:** **app não abre** em parcela real de dispositivos Android. Deve ser envolto em try/catch e seguir sem anúncios (graceful degradation).

**C11. ⚠️ TTS não implementado em Web (alvo atual do teste pessoal)**
- **Input:** `flutter_tts` chama `setLanguage` na web (plugin sem implementação).
- **Esperado:** `MissingPluginException` lançada em `_configurarTts()` (chamado sem `await` e sem try/catch no `initState`).
- **Status:** ✅ Corrigido com `suportaTts` + try/catch + botões desabilitados + coberto por `test/platform_c10_c11_test.dart`.
- **Impacto se falhar:** exceção não tratada no console web; botões "Ouvir versículo/capítulo" **permanecem habilitados mas não fazem nada** → feature "morta" com UX enganosa. Deve haver `suportaTts` análogo ao `suportaAdMob`, desabilitando os botões na web.

**C12. `_tts.speak('')` para retomar leitura**
- **Input:** pausar e clicar "Continuar" (código chama `_tts.speak('')`).
- **Esperado:** alguns engines (Android sem serviço de fala ativo) lançam erro em string vazia → exceção não tratada em `_alternarPlayPause`.
- **Impacto se falhar:** ao tocar "Continuar", nada acontece ou o app lança erro → usuário preso no estado pausado.
- **Status:** ✅ Corrigido (falha de retomada encerra graciosamente, sem desabilitar o TTS) + coberto por `test/tts_retomada_c12_test.dart`.

**C13. Duplo-toque em "Copiar chave Pix"**
- **Input:** dois taps no botão (ou tap em "Copiar" no diálogo).
- **Esperado:** dois `Clipboard.setData` + dois SnackBars/diálogos empilhados; `showDialog` pode abrir 2 diálogos.
- **Impacto se falhar:** UX confusa; se `Clipboard.setData` falhar (B2), nenhum feedback.

---

## 3️⃣ Erros de Negócio e Permissão

**B1. Botão "Ouvir versículo" habilitado sem conteúdo/suporte (web)**
- **Input:** app na web, versículo do dia carregado, tap em "Ouvir versículo".
- **Esperado (negócio):** se TTS indisponível, botão deve estar **desabilitado** (como já é quando `referencia.isEmpty`).
- **Status:** ✅ Corrigido junto de C11 (botões usam `_ttsDisponivel`).
- **Impacto se falhar:** anúncio de feature "Ouvir" que não funciona na plataforma web/windows — principal plataforma de teste atual.

**B2. Permissão de Clipboard negada (web/desktop) ao copiar Pix**
- **Input:** navegador bloqueando `clipboard-write`, tap em "Copiar chave Pix".
- **Esperado:** `Clipboard.setData` lança `PlatformException` → não há try/catch → **nenhum SnackBar** e o diálogo "Chave copiada!" não abre.
- **Status:** ✅ Corrigido com try/catch + SnackBar de erro amigável + coberto por `test/clipboard_b2_test.dart`.
- **Impacto se falhar:** doador idoso acha que copiou e vai ao banco sem a chave → **perda de doação** (impacto direto em receita do projeto). Deve mostrar erro "Não foi possível copiar, segure e selecione manualmente".

**B3. Validação da chave Pix (e-mail)**
- **Input:** `_chavePix = 'costamota@gmail.com'` (fixa). Teste: trocar por `"sem-arroba"` ou `"123"`.
- **Esperado:** o app copia qualquer string sem validação; não há teste automatizado da regra "chave Pix válida antes de publicar".
- **Impacto se falhar:** se a chave for trocada por valor inválido em manutenção futura, **doações simplesmente não chegam** sem nenhum aviso no app (falhar silenciosamente).

**B4. Virada do dia com app aberto (regra "Versículo do Dia")**
- **Input:** app aberto às 23:59; trocar para meia-noite sem interação.
- **Esperado (negócio):** o versículo do dia deve mudar automaticamente.
- **Comportamento atual:** `_conteudoDoDia()` só recalcula em `build` → fica mostrando **o versículo de ontem até o próximo setState** (toque em qualquer aba).
- **Impacto se falhar:** usuário que deixa o app aberto lê conteúdo desatualizado; teste com relógio injetável (hoje `DateTime.now()` não é injetável → difícil de testar de forma determinística).

**B5. Determinismo do versículo do dia (limites do calendário)**
- **Input:** `dia == 0` → deve ser **Gênesis 1:1** (2024-01-01); `dia == 1` → Gênesis 1:2; testar último dia acessível.
- **Esperado:** mesmo input (data) → mesmo versículo, em qualquer plataforma/horário.
- **Impacto se falhar:** conteúdo diário inconsistente entre web/Android; usuários comparam e acham bug.
- **Status:** ✅ Coberto por `test/limites_dados_test.dart` (ciclo determinístico dia→referência).

**B6. Aparelho sem engine TTS em português**
- **Input:** Android com TTS instalado só em inglês.
- **Esperado:** `getVoices` filtra pt → lista vazia → tela Ajustes mostra *"Nenhuma voz pt disponível no dispositivo."* ✅
- **Impacto se falhar:** dropdown vazio com exception de seleção, ou botões de voz habilitados sem ação.

**B7. `voz_tts_id` salvo aponta para voz que não existe mais**
- **Input:** usuário salva voz neural; faz atualização do SO que remove a voz; `getVoices` não contém `vozSalva`.
- **Esperado:** loop não encontra `escolhida` → fallback para a melhor voz pt-BR feminina e **reescreve** `voz_tts_id`. ✅ Gracioso.
- **Impacto se falhar:** dropdown mostra valor antigo não presente nos itens → `DropdownButtonFormField` lança assert/erro de "value not in items".
- **Status:** ✅ Coberto por `test/tts_qualidade_test.dart` (fase 2: voz salva removida → fallback + reescrita de `voz_tts_id`).

**B8. IDs de teste do AdMob publicados por engano (regra de negócio de publicação)**
- **Input:** build de release sem trocar `ca-app-pub-3940256099942544/...` nem o App ID do Manifest.
- **Esperado:** banner de teste em produção (sem receita) e **aviso de violação de política** do Google (uso de ID de teste em produção).
- **Impacto se falhar:** conta AdMob suspensa e receita zero; teste de release deve verificar que IDs de produção estão no artefato final.

**B9. Salvar versículo do dia com referência vazia**
- **Input:** dia em que `_conteudoDoDia` retorna `referencia: ''` (livro null).
- **Esperado:** botões "Ouvir"/"Salvar" desabilitados (`onPressed: null`). ✅
- **Impacto se falhar:** favorito com chave `""` persistida → lixo no `SharedPreferences` e item estranho na tela Salvos.

**B10. Nome do recebedor não conferido (regra anti-fraude Pix)**
- **Input:** fluxo de doação sem o aviso *"confira o nome de quem receberá"*.
- **Esperado:** aviso presente (implementado) e acessível via Semantics; teste de regressão de texto.
- **Impacto se falhar:** doador manda Pix para chave trocada/fraudulenta sem conferência → dano financeiro ao usuário e à reputação do app.
- **Status:** ✅ Coberto por `test/widget_test.dart` (aviso de texto + Semantics da chave).

**B11. Favorito de capítulo com nome composto/numérico ("1 João 3")**
- **Input:** salvar `"1 João 3"`, depois buscar na tela Salvos.
- **Esperado:** `_nomeLivroDaChave` varre o índice **reverso** e casa `"1 João "` (mais longo) → OK.
- **Impacto se falhar:** se a busca fosse por `split` ou por primeiro match, `"1 João"` poderia casar com `"1 João"` errado ou falhar — teste de regressão cobre prefixos numéricos.

**B12. Fonte grande (1.18) + texto longo → overflow de layout**
- **Input:** texto escalado em 1.18 num aparelho 320px com versículo longo (Salmos 119:176).
- **Esperado:** `Text` envolve; botões empilham com `LayoutBuilder` (`maxWidth < 420`).
- **Impacto se falhar:** overflow amarelo/vermelho em debug → texto cortado para o público-alvo (idosos). Teste em grid de tamanhos (320/360/411/768px) e `textScaleFactor` 1.18–2.0.

---

## 4️⃣ Recursos de Estudo (catálogo, casamento, filtros)

**EST1. JSON de estudos ausente, vazio ou corrompido**
- **Input:** `null`, string não-JSON ou `[]` no conteúdo de `assets/data/estudos_indice.json` / `assets/data/estudos/<Livro>.json`.
- **Esperado:** `recursosDeJson` devolve `[]` (catálogo vazio); painel mostra estado vazio amigável; sem `TypeError` nem crash.
- **Impacto se falhar:** deploy com arquivo truncado/corrompido derrubaria a aba Estudos e o indicador de estudo na leitura.
- **Status:** ✅ Coberto por `test/catalogo_estudos_test.dart` (entrada não-lista → catálogo vazio).

**EST2. Item não-`Map`, `id` vazio ou tipos errados são ignorados**
- **Input:** itens como `"texto"`, `42`, `null`, map sem `id`/com `id` vazio, ou `tipo`/`titulo`/`tema`/`fonte` com tipo errado.
- **Esperado:** parsing descarta os inválidos e mantém os válidos; tipos errados viram `''`/`[]`/`null` sem lançar (`recursoDeMapa`/`recursosDeJson`).
- **Impacto se falhar:** um único item malformado quebraria o catálogo inteiro (crash em tela) em vez de ser descartado.
- **Status:** ✅ Coberto por `test/catalogo_estudos_test.dart`.

**EST3. Casamento de referência versículo/capítulo/livro (com prefixo numérico)**
- **Input:** recurso com `ref` de versículo (`"João 3:16"`), capítulo (`"João 3"`) ou livro (`"João"`), contra o alvo `"João 3:16"`; também `"1 João 4:8"`.
- **Esperado:** `recursoAplicavel`/`recursosAplicaveis` devolvem o recurso de versículo mais os de capítulo e de livro (herança); `capituloDaReferencia` extrai `"João 3"` apenas de versículos; o prefixo numérico não confunde o casamento.
- **Impacto se falhar:** recurso de capítulo/livro não apareceria nos versículos, ou `"1 João"` casaria errado — perda de contexto de estudo.
- **Status:** ✅ Coberto por `test/catalogo_estudos_test.dart`.

**EST4. Corpo vazio ou só espaços → sem conteúdo**
- **Input:** recurso com `corpo: "   "` (ou fonte parcial).
- **Esperado:** `temCorpo == false`; painel mostra mensagem amigável em vez de corpo vazio; crédito de fonte montado apenas com os campos existentes.
- **Impacto se falhar:** recurso "fantasma" sem texto renderizaria em branco e enganaria o usuário.
- **Status:** ✅ Coberto por `test/catalogo_estudos_test.dart`.

**EST5. Agrupamento e filtros determinísticos (tipo/livro)**
- **Input:** catálogo com tipos conhecidos e desconhecidos, e vários livros.
- **Esperado:** `agruparPorTipo` põe os tipos conhecidos primeiro (ordem da tabela) e os demais ao final (ordem de aparição); `filtrarRecursos`/`tiposDisponiveis`/`livrosDisponiveis` são estáveis (livros em ordem alfabética).
- **Impacto se falhar:** a ordem da biblioteca mudaria a cada build → UX inconsistente e testes frágeis (NFR-007).
- **Status:** ✅ Coberto por `test/catalogo_estudos_test.dart`.

**EST7. Busca por palavra-chave nos estudos**
- **Input:** termo de busca na biblioteca de estudos (título, corpo ou tema).
- **Esperado:** `filtrarPorBusca` casa sem diferenciar maiúsculas/minúsculas e
  ignora acentos; busca vazia devolve todos; sem resultado → estado vazio claro.
- **Impacto se falhar:** o usuário não acharia um recurso por palavra-chave, ou
  a busca seria frágil (diferenciação de acento/caixa) — UX ruim na biblioteca.
- **Status:** ✅ Coberto por `test/catalogo_estudos_test.dart`.

**EST8. Contexto histórico (periodo/fatos) de um momento histórico**
- **Input:** recurso `momento_historico` com `periodo` e `fatos` presentes, ausentes, vazios ou com tipos errados.
- **Esperado:** `recursoDeMapa` parseia `periodo` (string) e `fatos` (lista de strings não vazias); ausentes/vazios viram `''`/`[]` (`temPeriodo`/`temFatos` falsos); o painel mostra selo de período e tópicos sem overflow em 320 px; o "Ouvir" inclui o contexto.
- **Impacto se falhar:** o contexto histórico sumiria, ou um campo malformado derrubaria o painel (SC-004) e a leitura em voz alta omitiria o período/fatos.
- **Status:** ✅ Coberto por `test/catalogo_estudos_test.dart`.

**EST6. Rótulo genérico para tipo desconhecido**
- **Input:** `tipo: "devocional"` (fora de `tiposConhecidos`) ou `""`.
- **Esperado:** `rotuloTipo` capitaliza o desconhecido (`"Devocional"`) e usa `"Estudo"` para vazio; tipos conhecidos têm rótulo fixo (`"Sermão"`, `"Momento histórico"`).
- **Impacto se falhar:** tipo desconhecido exibiria a chave técnica (`"momento_historico"`) em vez de um rótulo legível.
- **Status:** ✅ Coberto por `test/catalogo_estudos_test.dart`.

---

## 📊 Resumo de prioridade (o que testar primeiro)

| Severidade | Caso | Tipo | Status |
|---|---|---|---|
| 🔴 Alta | E10 — TTS lê mal livros com prefixo numérico | Dados válidos → saída errada | ✅ Corrigido + testado |
| 🔴 Alta | C10 — `MobileAds.initialize()` crasha sem GMS | Startup | ✅ Corrigido + testado |
| 🔴 Alta | C11 — TTS quebra na web (plataforma atual) | Plataforma | ✅ Corrigido + testado |
| 🔴 Alta | B2 — Clipboard negado = doação perdida sem feedback | Permissão | ✅ Corrigido + testado |
| 🟠 Média | C4 — Race de persistência de favoritos | Concorrência | ✅ Mitigado + testado |
| 🟠 Média | C5 — Sem retry após falha transiente de livro | Estado | ✅ Corrigido + testado |
| 🟠 Média | E3 — `capitulos` com tipo errado → crash no builder | Dados | ✅ Corrigido + testado |
| 🟠 Média | E15 — Estresse de favoritos (1000+ na tela Salvos) | Estresse | ✅ Corrigido + testado |
| 🟠 Média | C6 — Estresse de livros expandidos (memória/estado) | Estresse | ✅ Corrigido + testado |
| 🟡 Baixa | B4, C8 — Virada do dia, rotação | Diversos | ✅ Corrigido + testado |
| 🟡 Baixa | E1–E4, E13, B5, B7, C9 | Dados/Plataforma | ✅ Corrigido + testado |
| 🟡 Baixa | EST1–EST8 — Recursos de estudo (parsing/casamento/filtros/contexto histórico) | Dados | ✅ Coberto + testado |

**Cobertura automatizada atual:** `test/edge_cases_e10_test.dart`, `test/concurrency_c4_test.dart`, `test/platform_c10_c11_test.dart`, `test/clipboard_b2_test.dart`, `test/tts_qualidade_test.dart`, `test/limites_dados_test.dart`, `test/dados_biblicos_test.dart`, `test/config_negocio_test.dart`, `test/banner_c9_test.dart`, `test/banner_timeout_c9_test.dart`, `test/rotacao_c8_test.dart`, `test/catalogo_estudos_test.dart`, `test/cache_livros_test.dart`, `test/estresse_c6_test.dart`, `test/estresse_e15_test.dart`, `test/robustez_e16_test.dart`, `test/troca_aba_c7_test.dart`, `test/tts_concorrencia_test.dart`, `test/tts_retomada_c12_test.dart`, `test/overflow_b12_test.dart`, `test/virada_dia_b4_test.dart`, `test/widget_test.dart`.

> **Refatoração para testabilidade (E1–E4, E13, B5):** a lógica de seleção do versículo do dia e os casts de JSON foram extraídos para funções puras em `lib/dados_seguros.dart` (`diasDesdeEpoca`, `comoLista`, `selecionarVersiculoDoDia`), permitindo teste unitário determinístico sem widget.

> **Nota de infraestrutura de teste:** o `runAsync` usado para carregar assets via `rootBundle` deixa estado residual entre `testWidgets` do mesmo arquivo (o 2º teste falha ao abrir o app). Por isso, os arquivos com cenários de UI **combinam as fases em UM ÚNICO `testWidgets`** (ver `clipboard_b2_test.dart` e `concurrency_c4_test.dart`).

> **Melhoria de voz (TTS):** velocidade de fala fixada em `0.36` (`_velocidadeFala` em `lib/main.dart`) — bem pausada, mais natural e ideal para idosos (60+). Seleção de voz prioriza neural/pt-BR feminina do motor nativo (Google TTS / AVSpeechSynthesizer), coberta por `test/tts_qualidade_test.dart`.
