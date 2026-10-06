# Feature Specification: Recursos de Estudo do Texto Bíblico

**Feature Branch**: `002-recursos-de-estudo`

**Created**: 2026-09-03

**Status**: Draft

**Input**: User description: "aplique ao sistema notas de rodapé, comentários, artigos, sermões, palestras, momentos históricos e outros bons recursos para entender melhor aquele texto."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver notas e comentários do trecho que estou lendo (Priority: P1)

Ao ler um versículo ou um capítulo, o usuário percebe que aquele trecho tem recursos de
estudo (notas de rodapé e comentários) e consegue abri-los sem sair da leitura, para
entender melhor o que acabou de ler.

**Why this priority**: É o núcleo do pedido ("entender melhor aquele texto") e o menor
recorte que já entrega valor — o usuário lê e, no mesmo lugar, encontra a explicação do
trecho. Funciona offline e sozinho.

**Independent Test**: Abrir um trecho que possui recurso cadastrado, tocar no indicador de
estudo e conferir que a nota/comentário daquela referência aparece; abrir um trecho sem
recurso e conferir a mensagem amigável "Sem recursos de estudo para este trecho."

**Acceptance Scenarios**:

1. **Given** um versículo com nota de rodapé e/ou comentário cadastrado, **When** o usuário
   o exibe na leitura, **Then** um indicador discreto sinaliza que há estudo disponível e,
   ao ser tocado, abre o conteúdo daquela referência sem perder a posição de leitura.
2. **Given** um capítulo com recursos de estudo de nível de capítulo, **When** o usuário o
   abre, **Then** os recursos do capítulo ficam acessíveis a partir do cabeçalho do
   capítulo, além dos recursos de cada versículo.
3. **Given** um trecho sem nenhum recurso de estudo, **When** o usuário toca no indicador,
   **Then** aparece "Sem recursos de estudo para este trecho." — sem tela vazia, sem erro
   técnico e sem ação "morta e clicável".

---

### User Story 2 - Aprofundar com artigos, sermões, palestras e contexto histórico (Priority: P1)

Para o mesmo trecho, o usuário acessa materiais mais longos e variados — artigos, sermões,
palestras e "momentos históricos" — organizados por tipo, para ir além do significado
imediato do texto.

**Why this priority**: Complementa diretamente o pedido de "sermões, palestras e momentos
históricos"; sem esses tipos, a feature fica só na nota. Junto com a US1, forma o MVP de
compreensão do texto.

**Independent Test**: Abrir o painel de estudos de um trecho que possui vários tipos de
recurso e verificar que cada um é apresentado sob seu tipo (artigo, sermão, palestra,
momento histórico), com título e corpo legível.

**Acceptance Scenarios**:

1. **Given** um trecho com recursos de vários tipos, **When** o painel de estudos é aberto,
   **Then** os recursos são agrupados/rotulados pelo tipo, e o usuário consegue distinguir
   um artigo de um sermão, uma palestra e um momento histórico.
2. **Given** um recurso de um tipo, **When** exibido, **Then** mostra um título legível e o
   corpo de texto; quando houver, credita a fonte/atribuição (autor, origem, ano).
3. **Given** um tipo de recurso ainda não reconhecido pelo app, **When** ele é exibido,
   **Then** o texto aparece de forma genérica e legível, sem quebrar a tela nem sumir.

---

### User Story 3 - Navegar por uma biblioteca de estudos (Priority: P2)

O usuário abre uma seção própria de "Estudos" e percorre todos os recursos disponíveis,
filtrando por tipo (nota, comentário, artigo, sermão, palestra, momento histórico) e por
livro/tema, sem depender de estar lendo um trecho específico.

**Why this priority**: Dá descoberta e navegação ao acervo; amplia o uso (estudo temático),
mas não é pré-requisito para o valor central da leitura enriquecida.

**Independent Test**: Abrir a seção "Estudos", escolher um filtro de tipo e um livro, e
conferir que a lista resultante corresponde ao filtro, de forma responsiva e offline.

**Acceptance Scenarios**:

1. **Given** a seção "Estudos", **When** o usuário escolhe o tipo "sermão", **Then** a lista
   mostra apenas recursos daquele tipo.
2. **Given** a seção "Estudos" com filtro por livro, **When** o usuário seleciona um livro,
   **Then** só aparecem recursos ligados àquele livro (ou ao seu tema), e um estado claro é
   exibido quando não houver nenhum.
3. **Given** um acervo com muitos recursos, **When** a lista é percorrida, **Then** ela se
   mantém fluida e não bloqueia a abertura do app.

---

### User Story 4 - Salvar recursos de estudo (Priority: P2)

O usuário marca um recurso de estudo como salvo para consultá-lo depois; os recursos salvos
aparecem junto aos demais itens salvos e persistem entre sessões, podendo ser removidos.

**Why this priority**: Retenção e uso recorrente; apoiado na experiência de "Salvos" já
existente, agrega valor relevante sem redefinir o fluxo principal.

**Independent Test**: Salvar um recurso de estudo, reiniciar o app, confirmar que ele
permanece na seção de salvos e removê-lo em seguida.

**Acceptance Scenarios**:

1. **Given** um recurso de estudo exibido, **When** o usuário toca em salvar, **Then** o
   estado passa a "Salvo" e persiste após reiniciar o app.
2. **Given** recursos salvos, **When** o usuário abre a seção de salvos, **Then** os
   recursos de estudo aparecem identificados por tipo e podem ser abertos e removidos.
3. **Given** um recurso salvo cujo conteúdo deixou de existir em versões futuras, **When** a
   seção de salvos o exibe, **Then** aparece "Conteúdo não encontrado." sem travar nem
   ficar em carregamento eterno.

---

### User Story 5 - Ouvir um recurso de estudo em voz alta (Priority: P3)

O usuário toca "Ouvir" em uma nota, comentário, artigo, sermão, palestra ou momento
histórico e o texto é lido em voz alta em português, com a voz do próprio aparelho, de forma
manual e não contínua — inclusive para quem tem dificuldade de leitura.

**Why this priority**: Reaproveita o diferencial de acessibilidade do app para o público
idoso; é valioso, mas os recursos de estudo já entregam valor no texto antes disso.

**Independent Test**: Com voz em português disponível, tocar "Ouvir" em um recurso e validar
que lê exatamente aquele conteúdo e para no fim, sem avançar sozinho.

**Acceptance Scenarios**:

1. **Given** um recurso de estudo com corpo de texto, **When** o usuário toca "Ouvir",
   **Then** a leitura começa e os controles pausar/continuar ficam disponíveis.
2. **Given** a leitura de um recurso em andamento, **When** o usuário pausa e continua,
   **Then** retoma do ponto pausado, dentro do mesmo recurso.
3. **Given** uma plataforma/aparelho sem voz em português, **When** o recurso é exibido,
   **Then** a opção "Ouvir" fica desabilitada com aviso — nunca "morta e clicável".

---

### Edge Cases

- Trecho sem recursos → mensagem amigável; o indicador não engana o usuário.
- Arquivo de estudos ausente, vazio ou corrompido (tipo errado, texto vazio, `null`) →
  fallback amigável, sem erro técnico e sem travar a leitura.
- Recurso com corpo só de espaços → tratado como sem conteúdo.
- Tipo de recurso desconhecido → exibição genérica e legível (extensível a novos tipos).
- Recurso ligado a versículo/livro inexistente, ou a livros com prefixo numérico
  ("1 Coríntios", "3 João") → associação não gera crash nem recurso "fantasma".
- Um mesmo recurso ligado a vários trechos → aparece em todos, sem duplicar armazenamento
  nem quebrar favoritos.
- Recurso sem fonte/atribuição → exibido normalmente; o crédito só aparece quando existir.
- Acervo muito grande (centenas/milhares de recursos) → abertura e navegação não baixam tudo
  de uma vez nem travam; nada de "carregando para sempre".
- Texto de recurso longo em tela estreita (320 px) com fonte grande → legível, sem overflow
  nem texto cortado.
- Recurso salvo que desaparece em versão futura do conteúdo → "Conteúdo não encontrado."

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O app DEVE associar recursos de estudo a uma referência bíblica (versículo ou
  capítulo), a um livro, ou a um tema/palavra-chave.
- **FR-002**: O app DEVE suportar, no mínimo, os tipos de recurso: **nota de rodapé**,
  **comentário**, **artigo**, **sermão**, **palestra** e **momento histórico**, com
  estrutura aberta para novos tipos.
- **FR-003**: Durante a leitura, o app DEVE indicar, de forma discreta, que um trecho tem
  recursos de estudo e permitir abri-los sem abandonar a leitura.
- **FR-004**: O app DEVE exibir cada recurso com tipo, título e corpo de texto, e creditar
  fonte/atribuição (autor, origem, ano) sempre que essa informação existir.
- **FR-005**: O app DEVE oferecer uma seção de biblioteca de estudos que lista os recursos e
  permite filtrá-los por tipo e por livro/tema.
- **FR-006**: O usuário DEVE poder salvar e remover recursos de estudo; os salvos DEVEM
  persistir entre sessões no próprio aparelho.
- **FR-007**: O app DEVE permitir ouvir o corpo textual de um recurso em voz alta (quando
  houver voz disponível), mantendo a leitura manual e não contínua.
- **FR-008**: Os recursos de estudo DEVEM estar disponíveis **offline** e ser carregados sob
  demanda — a base de estudos inteira nunca é carregada de uma vez.
- **FR-009**: Falhas ou ausência de conteúdo de estudo DEVEM produzir mensagem amigável e
  estado consistente, nunca erro técnico visível ou tela em carregamento eterno.
- **FR-010**: Quando um trecho não tiver recursos, o app DEVE informar isso claramente e não
  oferecer ações inativas.
- **FR-011**: A origem do conteúdo DEVE ser **texto curado e embutido no próprio app**
  (notas, comentários, artigos, sermões e palestras transcritos), 100% offline, com crédito
  de fonte quando aplicável — sem dependência de internet.
- **FR-012**: A cobertura inicial DEVE ser um **conjunto inicial curado** de recursos
  (trechos e temas representativos), com a estrutura pronta para expansão posterior sem
  alteração de código.
- **FR-013**: A experiência de estudos DEVE aparecer **tanto dentro da tela de leitura**
  (painel por referência) **quanto em uma seção própria** de biblioteca de estudos.
- **FR-014**: A adição de novos recursos de estudo DEVE ser possível apenas editando dados,
  sem alteração de código de lógica.
- **FR-015**: A associação entre recurso e trecho DEVE ser estável e tolerante a conteúdo
  ausente, de modo que versões futuras de conteúdo não quebrem favoritos antigos.
- **FR-016**: Recursos de estudo DEVEM respeitar a legibilidade e a acessibilidade do app
  (destaque, alvos de toque generosos, sem overflow em telas estreitas com fonte grande).

### Non-Functional Requirements

- **NFR-001 (Offline-first)**: 100% dos recursos de estudo DEVEM estar acessíveis sem
  conexão; nenhuma funcionalidade da feature pode exigir rede.
- **NFR-002 (Desempenho)**: Abrir os recursos de um trecho DEVE ser perceptivelmente
  imediato; a base de estudos NÃO pode ser carregada inteira de uma vez; a leitura nunca
  pode ser bloqueada pelo carregamento dos estudos.
- **NFR-003 (Escala/volume)**: A feature DEVE suportar acervo de centenas a milhares de
  recursos e textos longos sem travar, sem vazamento de memória e sem "jank" perceptível.
- **NFR-004 (Acessibilidade)**: Fonte grande, contraste adequado e alvos de toque generosos;
  nenhum overflow/recorte em 320 px com escala de fonte 1.18; leitura em voz alta disponível
  quando a plataforma suportar; rótulos de acessibilidade (Semantics) nos controles.
- **NFR-005 (Robustez)**: Dados ausentes/vazios/corrompidos NUNCA resultam em erro técnico
  visível nem estado de carregamento eterno; falhas transientes DEVEM permitir nova tentativa
  na próxima ação; toda mensagem ao usuário em pt-BR e amigável.
- **NFR-006 (Integridade e atribuição)**: Quando o recurso declarar fonte, o crédito DEVE ser
  exibido; o conteúdo respeita domínio público e direitos autorais das fontes citadas.
- **NFR-007 (Determinismo)**: Para uma mesma referência, o conjunto e a ordem dos recursos
  exibidos DEVEM ser os mesmos em qualquer plataforma, horário ou execução.
- **NFR-008 (Manutenibilidade/extensibilidade)**: Novos tipos e novos recursos DEVEM ser
  adicionáveis apenas por edição de dados; a lógica DEVE permanecer pura e testável fora de
  widgets, aderente à constituição v1.0.0 do projeto.
- **NFR-009 (Privacidade)**: Nenhum dado do usuário (ex.: recursos salvos) sai do aparelho;
  a persistência é local.
- **NFR-010 (Compatibilidade de plataforma)**: Em plataformas sem voz ou sem anúncios, a
  feature DEVE degradar graciosamente — sem erro e sem bloquear o uso.

### Key Entities *(include if feature involves data)*

- **Recurso de Estudo**: material de apoio à compreensão de um texto; atributos:
  identificador estável, tipo, título, corpo de texto, referência(s) associada(s)
  (versículo/capítulo/livro/tema) e fonte/atribuição (autor, origem, ano, licença) opcional.
- **Tipo de Recurso**: categoria do material (nota de rodapé, comentário, artigo, sermão,
  palestra, momento histórico e outros extensíveis).
- **Referência**: identificador textual estável de um versículo ("Livro capítulo:versículo")
  ou de um capítulo/livro, reaproveitado dos favoritos existentes.
- **Favorito de Estudo**: recurso salvo pelo usuário, persistido no aparelho (mesma
  experiência de salvos já existente).
- **Coleção/Tema**: agrupamento opcional de recursos por assunto/palavra-chave para a
  navegação na biblioteca de estudos.

## Use Cases (Casos de Uso)

| ID | Ator | Caso de uso | Fluxo principal | Fluxo alternativo |
| :--- | :--- | :--- | :--- | :--- |
| UC-01 | Leitor | Ver recursos de um versículo | Lê o versículo → toca no indicador de estudo → painel abre com nota/comentário da referência | Sem recursos → mensagem "Sem recursos de estudo para este trecho." (FR-010) |
| UC-02 | Leitor | Ver recursos de um capítulo | Abre o capítulo → toca no indicador do cabeçalho → painel com recursos de capítulo/livro | Sem recursos → painel informa ausência; ação não fica "morta" (FR-009/FR-010) |
| UC-03 | Leitor | Aprofundar por tipo | No painel, escolhe/observa o tipo → lê artigo, sermão, palestra ou momento histórico | Tipo desconhecido → exibição genérica e legível (FR-002, edge case) |
| UC-04 | Leitor | Explorar a biblioteca | Abre "Estudos" → filtra por tipo e por livro → abre um recurso da lista | Filtro sem resultados → estado vazio claro (FR-005) |
| UC-05 | Leitor | Salvar recurso | Toca em salvar no recurso → estado vira "Salvo" → reaparece em "Salvos" após reiniciar | Recurso removido do conteúdo → "Conteúdo não encontrado." (FR-006, FR-015) |
| UC-06 | Leitor | Remover recurso salvo | Em "Salvos", toca em remover → recurso sai da lista e do disco | Toques rápidos → última ação prevalece, sem favorito "fantasma" (FR-006) |
| UC-07 | Leitor | Ouvir um recurso | Toca "Ouvir" no recurso → leitura em voz alta do trecho exato → para no fim | Plataforma sem voz → opção desabilitada com aviso (FR-007, NFR-010) |
| UC-08 | Mantenedor | Adicionar conteúdo | Edita os arquivos de dados de estudo → novos recursos/tipos aparecem sem mexer no código | Dado corrompido → ignorado com fallback, app segue estável (FR-014, NFR-005) |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos recursos de estudo ficam acessíveis sem conexão com a internet.
- **SC-002**: Abrir os recursos de um trecho exibe o conteúdo de forma perceptivelmente
  imediata, sem carregar a base de estudos inteira nem bloquear a leitura.
- **SC-003**: A mesma referência apresenta sempre o mesmo conjunto e ordem de recursos
  (determinismo), em qualquer plataforma e horário.
- **SC-004**: Zero erros técnicos visíveis e zero travamentos em cenários de conteúdo
  ausente, vazio ou corrompido (inclusive base de estudos indisponível).
- **SC-005**: 100% dos recursos de estudo salvos sobrevivem ao reinício do app (zero perda).
- **SC-006**: Todo recurso exibido com fonte declarada apresenta o crédito correspondente
  (nenhuma atribuição exigível é omitida).
- **SC-007**: Adicionar novos recursos de estudo não exige mudança de código nem
  "recompilação" de regras — apenas edição de dados.
- **SC-008**: Em telas de 320 px com fonte grande, nenhum recurso apresenta texto cortado ou
  overflow.

## Assumptions

- O conteúdo de estudo é primariamente **texto** e o app permanece **offline por padrão**;
  recursos de áudio/vídeo de palestras e sermões, caso existam no futuro, seriam tratados
  como item separado (fora desta feature).
- O conteúdo é curado/redigido pelo próprio projeto, com crédito a fontes de domínio público
  quando houver; o app não é fonte oficial de doutrina e as notas não substituem o texto
  bíblico.
- O público-alvo inclui pessoas idosas e de baixa familiaridade tecnológica: legibilidade,
  contraste, alvos de toque generosos e previsibilidade têm precedência.
- A funcionalidade reutiliza a experiência existente de favoritos/persistência local e de
  leitura em voz alta, sem introduzir novas dependências.
- O app continua carregando conteúdo sob demanda (nunca a Bíblia nem a base de estudos
  inteiras de uma vez).
- Mudanças seguem o ciclo spec-kit e a constituição v1.0.0 (lógica pura fora de widgets,
  testes ligados à matriz de QA, comunicação em pt-BR).
