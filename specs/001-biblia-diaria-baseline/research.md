# Research — Bíblia Diária Linha de Base

**Fase 0 do `/speckit-plan`.** Resolve os pontos de decisão técnica levantados
no Technical Context do `plan.md`. Todas as incógnitas foram resolvidas com
base no código existente, na spec e na constituição v1.0.0 — **nenhum
`NEEDS CLARIFICATION` permanece**.

## 1. Stack e alvo de plataforma

- **Decision**: Flutter/Dart multiplataforma, um único projeto. Publicação alvo:
  Android; validação diária em web e Windows.
- **Rationale**: é a implementação real (decisão do usuário — Opção A) e a
  constituição fixa a stack. Material 3, `setState`, `shared_preferences`,
  `flutter_tts`, `google_mobile_ads` já estão integrados e testados.
- **Alternatives considered**: Vite/JS puro (rejeitado — desvio de contexto),
  React Native (rejeitado — reescrita sem ganho para o público offline).

## 2. Persistência local (favoritos e preferências)

- **Decision**: armazenamento chave-valor persistido
  (`shared_preferences`), com fila serializada de escritas (last-write-wins).
- **Rationale**: dados são pequenos (`Set<String>` de referências + 2 flags de
  preferência). KV é suficiente, síncrono-friendly nos pontos de escrita, e já
  cobre o caso C4 (memória/disco nunca divergem) com custo mínimo.
- **Alternatives considered**: SQLite/Isar (over-engineering para o volume),
  arquivos JSON próprios (reimplementa KV sem ganho), SQL.js/localStorage web
  (não se aplica ao Flutter — e violaria a dependência mínima).

## 3. Conteúdo bíblico (assets offline)

- **Decision**: JSON em assets, dividido por livro (`assets/data/livros/*.json`),
  carregado sob demanda com cache em memória (`CacheDeLivros`) e retry em falha
  transiente; guardiões de tipos em `dados_seguros.dart`.
- **Rationale**: conteúdo é imutável e acompanha o build (100% offline). A
  divisão por livro evita carregar ~13 MB de uma vez (web/entrada). A falha de
  um arquivo não invalida os demais.
- **Alternatives considered**: bundle único (`biblia.json` de 13 MB — rejeitado:
  boot lento e `RangeError` em dados truncados), download remoto (rejeitado:
  viola offline-first), SQLite embutido com import (rejeitado: complexidade de
  migração sem benefício para dados fixos).

## 4. Integração de voz (leitura em voz alta)

- **Decision**: plugin de TTS do aparelho (`flutter_tts`), voz pt-BR nativa,
  velocidade 0.85, seleção de voz neural/pt-BR com fallback; capacidade
  declarada por `platform_support.dart` (indisponível na web/Linux).
- **Rationale**: sem custo e sem rede (usa o motor do SO). O contrato de
  leitura é manual e não contínuo (FR-007), e a falha do plugin degrada para
  botões desabilitados com aviso (C11/B1).
- **Alternatives considered**: serviço de voz em nuvem (rejeitado: online e com
  custo), gravações pré-renderizadas (rejeitado: inviável para 31 mil
  versículos).

## 5. Área de transferência (cópia da chave Pix)

- **Decision**: clipboard do sistema com try/catch e feedback explícito de
  sucesso/falha + orientação de cópia manual (B2).
- **Rationale**: a permissão de clipboard pode ser negada (web/desktop); a
  falha não pode parecer sucesso para o doador.
- **Alternatives considered**: ignorar falha (rejeitado: perda de doação).

## 6. Anúncios (banner)

- **Decision**: banner adaptativo via SDK de anúncios móveis, somente em
  Android/iOS (`suportaAdMob`), com `load()` protegido por try/catch (C9) e
  inicialização que nunca impede o `runApp` (C10).
- **Rationale**: o alvo de receita é mobile; web/desktop ficam sem banner. IDs
  de teste são bloqueados em release por regra pura testada (B8).
- **Alternatives considered**: anúncio interstitial/vídeo (fora de escopo da
  linha de base), banner em todas as plataformas (impossível: SDK não suporta).

## 7. Estado e componentização

- **Decision**: `StatefulWidget` + `setState`; lógica pura em módulos `lib/`;
  widgets reutilizáveis em `lib/widgets/`; relógio e carregador injetáveis.
- **Rationale**: sem camada de DI nem gerência de estado externa (YAGNI); o
  estado é pequeno e local. A extração para `lib/` já provou valor: as funções
  puras são testadas sem widget (matriz QA, casos E/B/C).
- **Alternatives considered**: Provider/Riverpod/Bloc (rejeitados: complexidade
  sem exigência atual — a constituição exige justificativa), repositórios
  genéricos (rejeitados: acesso direto aos módulos existentes é mais simples).

## 8. Testes e garantia de qualidade

- **Decision**: matriz de QA (`tool/QA_EDGE_CASES.md`) dirigindo arquivos de
  teste que referenciam casos (E/C/B); unit para funções puras, widget para
  fluxos; um único `testWidgets` por arquivo quando usa `runAsync`/assets.
- **Rationale**: padrão já consolidado e exigido pela constituição (V). Evita a
  poluição de estado residual do `flutter test` (nota na própria matriz).
- **Alternatives considered**: TDD estrito red-green por todos os fluxos
  (rejeitado como gate rígido nesta linha de base — há casos já cobertos que só
  exigem regressão), integração contínua com device farm (adiado).
