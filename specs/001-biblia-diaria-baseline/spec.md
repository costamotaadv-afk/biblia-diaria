# Feature Specification: Bíblia Diária — Linha de Base do Aplicativo

**Feature Branch**: `001-biblia-diaria-baseline`
**Created**: 2026-09-02
**Status**: Draft
**Input**: Especificar o escopo atual do app Flutter Bíblia Diária (leitura diária, Bíblia completa offline, favoritos, leitura em voz alta, tema/fonte, doação Pix, anúncios) e o que precisa ser estruturado em seguida, para servir de linha de base do ciclo spec-kit.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Ler o "Versículo do Dia" na abertura (Priority: P1)

Ao abrir o app, o usuário vê imediatamente uma leitura diária: um versículo bíblico, sua referência e uma mensagem de incentivo, escolhidos de forma estável para aquela data, mesmo **sem internet**. O conteúdo muda automaticamente quando o dia muda.

**Why this priority**: É o coração do produto e a primeira impressão; funciona offline e sem configuração — entrega valor sozinho.

**Independent Test**: Abrir o app sem rede em qualquer data; conferir que um versículo com referência é exibido e que, na mesma data, o conteúdo é sempre o mesmo (determinismo), mudando apenas no dia seguinte.

**Acceptance Scenarios**:

1. **Given** um usuário abre o app pela primeira vez em uma data válida, **When** a tela inicial conclui o carregamento, **Then** ele vê "Versículo do Dia" com versículo, referência (ex.: "Gênesis 1:1") e mensagem de incentivo.
2. **Given** o app aberto além da meia-noite sem interação, **When** o usuário volta a interagir com a tela, **Then** o versículo do dia corresponde à nova data.
3. **Given** dados de conteúdo indisponíveis ou vazios, **When** a tela inicial tenta montar o versículo, **Then** nenhum erro técnico é mostrado — aparece um texto amigável de fallback e os botões de ação ficam desabilitados.

### User Story 2 — Ler a Bíblia completa por livro e capítulo (Priority: P1)

O usuário navega pelos 66 livros da Bíblia (Gênesis a Apocalipse), expande capítulos e lê cada versículo, tudo **offline**, inclusive com nomes compostos e numéricos ("1 Coríntios", "3 João").

**Why this priority**: É a funcionalidade central de conteúdo; precisa ser confiável mesmo com dados de entrada imperfeitos.

**Independent Test**: Navegar até um livro com prefixo numérico e outro com nome composto, abrir vários capítulos e percorrer versículos sem rede.

**Acceptance Scenarios**:

1. **Given** a lista de 66 livros, **When** o usuário expande um livro, **Then** os capítulos são exibidos e o conteúdo é carregado na medida em que é pedido (o app não trava ao abrir).
2. **Given** um arquivo de conteúdo corrompido em um livro (capítulo como objeto, versículo vazio, número inválido), **When** o usuário o abre, **Then** o app mostra uma mensagem amigável — nunca uma tela de erro ou travamento.

### User Story 3 — Salvar versículos e capítulos favoritos (Priority: P1)

O usuário marca um versículo do dia, um versículo ou um capítulo inteiro como "Salvo". Os salvos ficam disponíveis em uma aba própria, **persistidos no aparelho entre sessões**, e podem ser removidos.

**Why this priority**: Retenção e uso diário; dados do usuário não podem se perder em toques rápidos ou reinícios.

**Independent Test**: Salvar um versículo, reiniciar o app, confirmar que ele permanece na lista "Salvos", e remover em seguida.

**Acceptance Scenarios**:

1. **Given** um versículo exibido, **When** o usuário toca em salvar, **Then** o ícone reflete "Salvo" e o item persiste após reiniciar o app.
2. **Given** toques rápidos e repetidos no botão salvar/remover, **When** o usuário reinicia o app, **Then** o estado final em tela é exatamente igual ao estado persistido (sem favorito "fantasma").
3. **Given** um favorito cujo livro deixou de existir em versões futuras de conteúdo, **When** a aba "Salvos" o exibe, **Then** aparece "Conteúdo não encontrado." sem travar e sem estado de carregamento eterno.

### User Story 4 — Ouvir versículo ou capítulo em voz alta (Priority: P1)

O usuário toca "Ouvir" em um versículo ou capítulo e o conteúdo é lido em voz alta em português, **usando a voz do próprio aparelho**. A leitura é **manual e não contínua**: lê exatamente o trecho pedido e para ao final — não avança sozinho para o próximo trecho. Controles de pausar/continuar ficam disponíveis.

**Why this priority**: Acessibilidade para o público principal (pessoas idosas e com dificuldade de leitura). É o diferencial do app.

**Independent Test**: Em um aparelho com voz em português, tocar "Ouvir versículo"; validar que começa, pausa, continua e para no fim do trecho sem pular para o próximo.

**Acceptance Scenarios**:

1. **Given** um versículo com texto, **When** o usuário toca "Ouvir versículo", **Then** a leitura começa e um controle de pausar/continuar aparece (flutuante e na tela).
2. **Given** o usuário pausa e toca "Continuar", **When** a leitura é retomada, **Then** ela segue do ponto pausado dentro do mesmo trecho.
3. **Given** referências com prefixo numérico ("1 Coríntios 2:3"), **When** o app lê em voz alta, **Then** pronuncia corretamente ("Primeira Coríntios, capítulo dois, versículo três"), sem engolir o número do livro.
4. **Given** um aparelho ou plataforma sem voz em português, **When** a tela é montada, **Then** a opção "Ouvir" fica desabilitada com aviso — nunca "morta e clicável".

### User Story 5 — Ajustar tema escuro e tamanho da fonte (Priority: P2)

O usuário alterna entre tema claro/escuro e ativa fonte maior (recomendada), com preferências salvas. O layout não "estoura" nem corta texto em aparelhos pequenos com fonte grande.

**Why this priority**: Conforto visual e legibilidade para idosos — decisivo para o público-alvo.

**Independent Test**: Ativar tema escuro e fonte grande em um aparelho de tela pequena (320 px) e percorrer as quatro abas sem texto cortado; reiniciar e conferir que as preferências permanecem.

**Acceptance Scenarios**:

1. **Given** a aba de Ajustes, **When** o usuário alterna tema ou fonte, **Then** a mudança é imediata e persiste após reiniciar.
2. **Given** fonte grande ativa e texto longo em tela estreita, **When** qualquer aba é renderizada, **Then** não há overflow nem conteúdo cortado.

### User Story 6 — Doar via Pix com instruções acessíveis (Priority: P2)

O usuário encontra a chave Pix (e-mail) na aba Ajustes, copia com um toque e recebe instruções grandes e numeradas. Se a cópia falhar (navegador/desktop), um aviso claro orienta a cópia manual. Um aviso orienta a conferir o nome do recebedor antes de confirmar.

**Why this priority**: Sustentabilidade do projeto (app gratuito); doador é majoritariamente idoso — erro de cópia significa doação perdida.

**Independent Test**: Tocar "Copiar chave Pix"; simular bloqueio de área de transferência e confirmar que aparece mensagem de falha amigável.

**Acceptance Scenarios**:

1. **Given** a aba Ajustes, **When** o usuário toca "Copiar chave Pix", **Then** a chave é copiada, um diálogo numerado explica os passos e o aviso anti-fraude ("confira o nome de quem receberá") está presente.
2. **Given** permissão de cópia negada, **When** o usuário toca em copiar, **Then** o app avisa que não foi possível e orienta a cópia manual.

### User Story 7 — Manter o app gratuito com anúncios (banner) (Priority: P2)

Nas telas de conteúdo, um anúncio em banner é exibido em plataformas compatíveis (celular). Em aparelhos ou plataformas sem suporte, o app funciona normalmente **sem anúncios e sem erros**.

**Why this priority**: Receita do projeto; falhas de anúncio jamais podem impedir o uso do app.

**Independent Test**: Navegar entre abas em um aparelho sem suporte a anúncios (emulador sem serviços do Google) e confirmar que o app segue estável.

**Acceptance Scenarios**:

1. **Given** uma plataforma compatível, **When** o usuário navega para uma tela com banner, **Then** um anúncio é carregado sem bloquear a interface.
2. **Given** uma plataforma sem suporte ou falha de carregamento, **When** a tela é aberta, **Then** nenhum erro é exibido ao usuário e o conteúdo permanece utilizável.

### User Story 8 — Estruturar o app para evolução (publicação e manutenção) (Priority: P3)

Antes da publicação, o projeto precisa de: anúncios com identificadores reais de produção, processos de garantia de qualidade documentados e automatizados, estrutura de código organizada em componentes e governança ratificada, para que mudanças futuras (conteúdo, versículos, novas versões) não introduzam regressões.

**Why this priority**: Não agrega valor direto ao usuário hoje, mas protege todas as histórias acima em releases futuros.

**Independent Test**: Executar o conjunto automatizado de verificação de qualidade e confirmar que os casos de risco conhecidos da matriz de QA estão cobertos e verdes.

**Acceptance Scenarios**:

1. **Given** o fluxo de verificação automatizado, **When** ele é executado, **Then** todos os casos de risco documentados passam ou estão explicitamente marcados como pendentes.
2. **Given** um build de produção, **When** são verificados os identificadores de anúncio e a chave Pix, **Then** nenhum identificador de teste é usado em produção e a chave é um e-mail válido.

### Edge Cases

- Conteúdo ausente/corrompido (índice vazio, livro sem capítulos, capítulos como objeto, versículos vazios, texto só com espaços, números inválidos) → fallback amigável, sem crash.
- Aparelho sem data/hora correta (antes de 2024) ou datas extremas → versículo determinístico, sem erro de intervalo.
- Toques rápidos/duplos em salvar e em ouvir → estado consistente, sem perda de dados, sem sobreposição de áudio.
- Falha transitória ao carregar conteúdo (rede/cache) → nova tentativa na próxima ação, sem estado "preso".
- Plataforma sem leitura em voz alta ou sem anúncios → recurso desabilitado com aviso, nunca quebrado.
- Grande volume de favoritos (200+) e textos longos com fonte grande em tela estreita → sem travamento e sem overflow.
- Referências com prefixo numérico ("1 Coríntios", "2 Reis", "3 João") e capítulos gigantes (Salmos 119) → leitura correta e completa.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O app DEVE exibir, na abertura e sem rede, um "Versículo do Dia" determinístico (mesma data → mesmo conteúdo), com versículo, referência e mensagem.
- **FR-002**: O app DEVE conter os 66 livros da Bíblia (Gênesis a Apocalipse) navegáveis por livro e capítulo, 100% offline.
- **FR-003**: O app DEVE carregar conteúdo sob demanda (sem baixar tudo de uma vez), sem travar na navegação.
- **FR-004**: O app DEVE permitir salvar e remover favoritos de versículos e de capítulos inteiros.
- **FR-005**: Os favoritos DEVEM persistir entre sessões no próprio aparelho.
- **FR-006**: O app DEVE reproduzir em voz alta um versículo ou um capítulo, em português, usando voz disponível no aparelho.
- **FR-007**: A leitura em voz alta DEVE ser manual e não contínua: lê o trecho pedido e para ao final, sem avançar sozinho.
- **FR-008**: O app DEVE fornecer controles de pausar e continuar a leitura em voz alta.
- **FR-009**: Referências de livros com prefixo numérico DEVEM ser lidas em voz alta corretamente.
- **FR-010**: Quando a leitura em voz alta não estiver disponível, o app DEVE desabilitar a opção e informar o usuário.
- **FR-011**: O app DEVE permitir alternar tema claro/escuro e fonte maior, com preferências persistidas.
- **FR-012**: O app DEVE exibir a chave Pix (e-mail válido) para doação e oferecer cópia com feedback claro de sucesso ou falha.
- **FR-013**: O app DEVE exibir um banner de anúncio em plataformas compatíveis, degradando sem erro nas demais.
- **FR-014**: Nenhuma falha de conteúdo, plataforma ou permissão DEVE produzir erro técnico visível ao usuário — sempre mensagem amigável e estado consistente.
- **FR-015**: Em builds de produção, o app DEVE usar identificadores de anúncio reais (nunca de teste) e a chave Pix DEVE ser válida.
- **FR-016**: O app DEVE tolerar toques rápidos/repetidos sem perder dados nem duplicar ações de áudio.

### Key Entities

- **Livro**: unidade canônica de conteúdo (66 no total), com nome (ex.: "1 Coríntios"), capítulos e versículos; base para navegação e referências.
- **Capítulo**: agrupamento de versículos com número próprio; pode ser salvo como favorito e lido em voz alta inteiro.
- **Versículo**: menor unidade de texto com referência única ("Livro capítulo:versículo"); é o alvo da leitura diária, dos favoritos e da leitura em voz alta.
- **Referência**: identificador textual estável de um versículo/capítulo usado em favoritos e na leitura diária.
- **Favorito**: referência salva pelo usuário (versículo ou capítulo), persistida no aparelho.
- **Preferências do usuário**: tema (claro/escuro) e tamanho de fonte, persistidos.
- **Conteúdo diário**: par (versículo do dia + mensagem) derivado deterministicamente da data.
- **Chave de doação (Pix)**: identificador de recebimento (e-mail) exibido e copiável, com instruções de uso.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das funcionalidades principais (leitura diária, navegação da Bíblia, favoritos, voz, tema/fonte, Pix) funcionam sem conexão com a internet.
- **SC-002**: O "Versículo do Dia" é determinístico em 100% das execuções: mesma data produz exatamente o mesmo conteúdo em qualquer aparelho/plataforma.
- **SC-003**: Nenhuma falha de dados corrompidos, plataforma sem suporte ou permissão negada resulta em erro técnico visível ou travamento (0 crashes nas jornadas principais).
- **SC-004**: 100% dos favoritos salvos sobrevivem ao reinício do app e ao uso com toques rápidos (zero perda de dados).
- **SC-005**: A leitura em voz alta de capítulos gigantes (ex.: Salmos 119) conclui sem truncamento silencioso.
- **SC-006**: Em telas de 320 px com fonte grande, nenhuma das abas exibe texto cortado ou overflow.
- **SC-007**: 100% dos casos de risco da matriz de QA têm status documentado e, quando marcados como cobertos, passam na verificação automatizada.
- **SC-008**: Em build de produção, nenhum identificador de anúncio de teste está presente e a chave Pix é um e-mail válido.

## Assumptions

- O conteúdo bíblico é de domínio público (tradução Almeida) e muda com baixa frequência; versões futuras de conteúdo não quebram favoritos antigos (fallback "Conteúdo não encontrado.").
- O público-alvo inclui pessoas idosas e de baixa familiaridade tecnológica; legibilidade e previsibilidade têm precedência sobre recursos novos.
- O app é distribuído gratuitamente; a sustentabilidade vem de doações Pix e anúncios.
- O desenvolvimento ocorre principalmente em Windows e web; Android é o alvo principal de publicação; iOS requer Mac e está fora de escopo imediato.
- O Android SDK ainda não está instalado na máquina de desenvolvimento; a publicação em loja é um marco posterior, tratado em feature própria (não bloqueia esta linha de base).
- A stack é Flutter (multiplataforma); a estrutura de governança foi ratificada em `.specify/memory/constitution.md` (v1.0.0).
- As funcionalidades descritas já existem implementadas na linha de base; esta spec documenta o escopo atual e os critérios de qualidade que o trabalho futuro deve preservar.
