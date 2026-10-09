<!--
  Sync Impact Report
  - Version change: (unversioned template placeholder) -> 1.0.0
  - Modified principles: n/a (first real content; all five principles added)
  - Added sections: Core Principles (I-V); Constraints Técnicas; Workflow & Quality Gates; Governance
  - Removed sections: n/a
  - Follow-up TODOs: none (all placeholders resolved)
-->

# Bíblia Diária Constitution

## Core Principles

### I. Código limpo e componentização Flutter

Todo código DEVE ser claro, idiomático e componentizado:

- Nomes descritivos em português (pt-BR) para identificadores, comentários e
  mensagens; APIs do Flutter/Dart permanecem em inglês.
- Comentários explicam o PORQUÊ e o risco evitado, nunca o que o código já diz.
- Componentes de UI reutilizáveis vivem em `lib/widgets/` e só existem quando
  há dois usos reais ou uma responsabilidade isolada clara (ex.: banner de
  anúncio).
- Lógica de negócio e parsing de dados NÃO moram em widgets: são funções puras
  em módulos pequenos e testáveis (padrão de `lib/dados_seguros.dart`,
  `lib/leitura_natural.dart`, `lib/config.dart`, `lib/cache_livros.dart`).
- `lib/main.dart` orquestra UI/estado; novas regras testáveis sem widget DEVEM
  ser extraídas para fora dele.

### II. Robustez offline e integridade de conteúdo

O app é 100% offline e o conteúdo (66 livros, ~13 MB) é editado manualmente:

- Dados externos (JSON de assets) NUNCA são confiáveis: tipos errados, campos
  ausentes, listas vazias e `null` são entradas esperadas, tratadas por
  guardiões seguros (ex.: `comoLista`), nunca por casts diretos fora deles.
- O conteúdo DEVE ser carregado sob demanda, com cache em memória e nova
  tentativa em falha transiente (padrão `CacheDeLivros`) — nunca estado
  "preso" em erro permanente.
- O "Versículo do Dia" DEVE ser determinístico: mesma data → mesmo conteúdo,
  em qualquer plataforma e horário.
- Toda falha de conteúdo produz fallback amigável, nunca erro técnico visível.

### III. Tolerância a falhas e excelente experiência para o usuário idoso

O público-alvo inclui pessoas idosas e de baixa familiaridade tecnológica:

- Plugins com suporte parcial (voz, anúncios, clipboard) DEVEM anunciar sua
  disponibilidade (padrão de `lib/platform_support.dart`), envolver chamadas
  propensas a falha em try/catch e degradar graciosamente — o app nunca deixa
  de abrir nem trava por causa de um recurso indisponível.
- Feature indisponível (ex.: TTS na web) DEVE ficar desabilitada com aviso;
  nunca "morta e clicável".
- Legibilidade em primeiro lugar: fonte grande, contraste, alvos de toque
  generosos; telas 320 px com escala de fonte 1.18 DEVEM renderizar sem
  overflow ou texto cortado.
- Leitura em voz alta é manual e não contínua: lê o trecho pedido e para,
  sem avançar sozinho para o próximo trecho.

### IV. Estado explícito, serializado e testável

- Prefira `StatefulWidget` + `setState` a gerência de estado externa até que a
  complexidade realmente exija (YAGNI). Estado derivado é recalculado no
  `build`, nunca duplicado.
- Escritas concorrentes em persistência local DEVEM respeitar ordem
  last-write-wins por fila encadeada (padrão de favoritos em `main.dart`,
  caso C4 da matriz de QA); memória e disco nunca divergem.
- Todo `await` seguido de `setState` DEVE ser protegido por `mounted`;
  `setState` após `dispose` é proibido.
- Dependências de tempo (relógio) e de carregamento (cache) DEVEM ser
  injetáveis via construtor para permitir teste determinístico.

### V. Testes como garantia (Matriz de QA)

A matriz `tool/QA_EDGE_CASES.md` (casos `E*`, `C*`, `B*`) é fonte de verdade:

- Toda correção/hardening DEVE atualizar a matriz e criar o teste que
  referencia o caso pelo código (ex.: `test/edge_cases_e10_test.dart`).
- Lógica pura DEVE ser testada por unidade (sem widget); testes de widget são
  reservados a fluxos que só fazem sentido na árvore montada.
- Testes DEVM ser determinísticos, sem rede, sem relógio real e sem serviços
  externos (mocks de plataforma via valores iniciais e canais mockados).
- Cenários de UI que carregam assets DEVEM combinar as fases em UM ÚNICO
  `testWidgets` por arquivo (regra do `runAsync`).
- Testes afirmam comportamento observável (texto, estado de disco, habilitação
  de botão), nunca detalhes de implementação.

## Constraints Técnicas

- **Stack fixa**: Flutter multiplataforma (Dart). A menção a qualquer outra
  stack (ex.: Vite/JS) em specs/planos é um desvio e DEVE ser tratada como
  erro a corrigir contra esta constituição.
- **Dependências mínimas**: adicionar pacote exige justificativa — o que já
  existe no Flutter resolve? O pacote é mantido e compatível com web/desktop
  e offline? `pubspec.yaml` permanece enxuto.
- **Plataformas**: Android e web são alvos ativos; iOS exige Mac (fora de
  escopo imediato). Recursos por plataforma são declarados em
  `lib/platform_support.dart`.
- **Monetização**: chave Pix é e-mail válido conferível; IDs de anúncio de
  teste NUNCA em build de release; AdMob degrada sem Google Play Services.
- **Performance**: Bíblia inteira (~13 MB) jamais carregada de uma vez;
  carregamento sob demanda e listas lazy são obrigatórios.
- **Idioma**: toda comunicação escrita (UI, comentários, docs, testes) em
  português do Brasil.

## Workflow & Quality Gates

- Toda mudança de código passa por `flutter analyze` (sem novas issues) e
  `flutter test` (verde) antes de ser considerada pronta.
- Mudanças de feature seguem o ciclo spec-kit: `/speckit-specify` →
  `/speckit-plan` → `/speckit-tasks` → implementação, com a spec persistida
  em `specs/` e o contexto em `.specify/feature.json`.
- Nenhuma feature nova é planejada sem constituição ratificada (gate do plano).
- Regressões de acessibilidade (320 px × fonte 1.18) e casos da matriz com
  status "coberto" devem permanecer verdes.
- Dívida de organização (caso na matriz sem teste) DEVE ser explícita e
  pontual, nunca silenciosa.

## Governance

- Esta constituição **supersede** convenções e práticas ad hoc; specs, planos
  e tarefas DEVEM ser verificados contra ela em revisão.
- **Emendas**: requerem (1) justificativa concreta, (2) atualização desta
  constituição, (3) impactos refletidos na matriz de QA e nos testes.
- **Versionamento**: MAJOR para remoção/redefinição de princípio
  (retroincompatível); MINOR para princípio/seção novo ou expansão material;
  PATCH para esclarecimentos e correções textuais.
- **Conformidade**: toda revisão/PR verifica aderência; complexidade nova
  precisa ser justificada em review. Documentos gerados pelo spec-kit usam
  esta constituição como guia de decisão em tempo de execução.

**Version**: 1.0.0 | **Ratified**: 2026-09-02 | **Last Amended**: 2026-09-02
