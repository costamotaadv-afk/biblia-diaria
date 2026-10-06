# Platform Contract — Plugins de Plataforma e Área de Transferência

Este documento define o contrato de integração com `flutter_tts` (leitura em
voz alta), `google_mobile_ads` (banner) e a área de transferência/Clipboard
(doação Pix). A regra transversal é a **degradação graciosa**: nenhuma falha de
plugin, permissão ou plataforma pode impedir o uso do app nem produzir erro
técnico visível ao usuário (FR-013, FR-014).

Gates de capacidade implementados em `lib/platform_support.dart`; assinaturas
públicas documentadas em [module-apis.md](module-apis.md).

## 1. Gates de capacidade por plataforma

| Recurso | Android | iOS | Web | Windows | macOS | Linux |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| TTS (`flutter_tts`) — `suportaTts` | sim | sim | **não** | sim | sim | **não** |
| Anúncios (`google_mobile_ads`) — `suportaAdMob` | sim | sim | **não** | **não** | **não** | **não** |
| Clipboard (Pix) | sim | sim | sim* | sim | sim | sim |

\* Na web a cópia depende da permissão `clipboard-write` do navegador; a falha
deve ser tratada (caso B2). O Android é o alvo de publicação; web/Windows são as
plataformas de desenvolvimento e validação.

## 2. Leitura em voz alta (`flutter_tts`)

### Contrato de disponibilidade
- Gate de entrada: `suportaTts`. O widget raiz começa com `_ttsDisponivel =
  suportaTts` e o rebaixa para `false` se a configuração falhar (plugin ausente,
  engine sem voz, erro de plataforma — caso C11).
- Sempre que `_ttsDisponivel == false`, os botões "Ouvir versículo"/"Ouvir
  capítulo" ficam **desabilitados com aviso** — nunca "mortos e clicáveis"
  (FR-010, caso B1).

### Contrato de configuração
- Idioma fixo `pt-BR` (`setLanguage`), velocidade `0.85` (`_velocidadeFala`),
  pitch padrão — leitura levemente pausada e natural, pensada para idosos.
- Seleção de voz por `getVoices`: filtra vozes `pt`, prioriza neural/pt-BR
  feminina do motor nativo; sem vozes pt → Ajustes mostra "Nenhuma voz pt
  disponível no dispositivo." (caso B6).
- A voz escolhida é persistida em `voz_tts_id` (ver `storage.md`). Voz salva que
  deixou de existir → fallback para a melhor voz pt-BR + reescrita da chave
  (caso B7).

### Contrato de leitura
- O texto falado é derivado por funções puras de `lib/leitura_natural.dart`:
  `referenciaParaLeitura` (ex.: "Gênesis 1:1" → "Gênesis, capítulo um, versículo
  um"), `nomeLivroParaLeitura` ("1 Coríntios" → "Primeira Coríntios") e
  `textoParaLeituraNatural` — os números do livro nunca são engolidos (FR-009,
  caso E10).
- Leitura **manual e não contínua** (FR-007): lê exatamente o trecho pedido e
  para ao final; não avança sozinho para o próximo trecho.
- Um único áudio por vez: todo novo trecho faz `stop` antes de `speak` (caso
  C3). Pausar/continuar respeitam a máquina de estados `_falando / _pausado /
  _leituraAtiva` (FR-008).
- Texto vazio ou só espaços não inicia leitura (casos E5/B9).

### Contrato de falhas
- Toda chamada ao plugin é protegida por try/catch ou pelo gate `suportaTts`;
  uma exceção de plataforma rebaixa `_ttsDisponivel` e nunca escapa como erro
  não tratado (casos C1, C11, C12).
- Todo `await → setState` é guardado por `mounted` (caso C7).

### Testes
`test/platform_c10_c11_test.dart`, `test/tts_qualidade_test.dart`,
`test/tts_concorrencia_test.dart`, `test/edge_cases_e10_test.dart`.

## 3. Anúncios (`google_mobile_ads`)

### Contrato de inicialização
- `inicializarAdMob()` é chamado na partida **somente** quando `suportaAdMob` e
  **nunca lança** para o chamador (try/catch interno): aparelho sem Google Play
  Services ou sem App ID → app abre normalmente, sem anúncios (FR-013, caso C10).

### Contrato do banner
- `BannerAnuncio` (`lib/widgets/banner_anuncio.dart`) é o único widget de
  anúncio: banner adaptativo (anchored adaptive) em telas de conteúdo, sem
  parâmetros obrigatórios, exibido apenas onde `suportaAdMob`.
- Falha de `load()` (incluindo `PlatformException`/`MissingPluginException`) é
  tratada internamente: nada é exibido ao usuário e o conteúdo segue utilizável
  (caso C9).
- `dispose()` segue o ciclo do elemento; rotação de tela recarrega o tamanho
  adaptativo e dispõe o banner anterior (caso C8).

### Contrato de publicação (IDs)
- IDs de teste do Google (`ca-app-pub-3940…`) são aceitos apenas em debug;
  `erroIdAnuncioEmProducao(isRelease, id)` bloqueia ID de teste em build de
  release (FR-015, caso B8).
- Antes de publicar: trocar o App ID em
  `android/app/src/main/AndroidManifest.xml` (`APPLICATION_ID`) e o
  `_bannerAdUnitId` em `lib/widgets/banner_anuncio.dart` pelos IDs reais do
  console AdMob.

### Testes
`test/platform_c10_c11_test.dart`, `test/banner_c9_test.dart`,
`test/config_negocio_test.dart` (regra B8).

## 4. Área de transferência e Pix

### Contrato de configuração
- `chavePix` (`lib/config.dart`) é a constante da chave de doação (e-mail:
  `costamota@gmail.com`); `chavePixValida` (regex de e-mail) garante que a chave
  configurada é sempre válida antes de publicar (FR-015, caso B3).

### Contrato de cópia
- Ao tocar "Copiar chave Pix", o app chama `Clipboard.setData` **dentro de
  try/catch**:
  - **Sucesso**: diálogo com instruções grandes e numeradas + aviso anti-fraude
    "confira o nome de quem receberá" antes de confirmar (FR-012, caso B10),
    acessível via Semantics.
  - **Falha** (permissão negada em web/desktop): SnackBar de erro amigável
    orientando a cópia manual — o diálogo de sucesso NÃO abre (caso B2).
- Toques rápidos/duplos em "Copiar" nunca lançam exceção e exibem no máximo um
  feedback (caso C13).

### Testes
`test/clipboard_b2_test.dart`, `test/config_negocio_test.dart`,
`test/tts_concorrencia_test.dart` (duplo-toque C13).

## 5. Resumo dos casos de plataforma (regressão)

| Caso | Falha que o contrato impede | Status |
| :--- | :--- | :--- |
| C9 | `load()` do banner sem try/catch → exceção assíncrona | Corrigido + testado |
| C10 | `MobileAds.initialize()` sem GMS → crash no startup | Corrigido + testado |
| C11 | TTS sem implementação (web/Linux) → `MissingPluginException` | Corrigido + testado |
| C12 | `_tts.speak('')` ao continuar → exceção em alguns engines | Tratado por gate/estado |
| B2 | Clipboard negado → doação "silenciosamente" perdida | Corrigido + testado |
| B6 | Aparelho sem voz pt → dropdown vazio/erro | Corrigido |
| B7 | `voz_tts_id` órfão → assert de "value not in items" | Corrigido + testado |
| B8 | ID de anúncio de teste em release | Corrigido + testado |
