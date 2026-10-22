# Feature Specification: Experiência de Leitura Visual

**Feature Branch**: `004-experiencia-leitura-visual`

**Status**: Implemented

## Resumo

Refinamento da apresentação do app para leitura confortável e prolongada do texto
bíblico e dos estudos, com foco no público idoso/de baixa visão: tipografia serifada
para o corpo de leitura, paleta acolhedora (creme/carvão, dourado/terracota), cartão
imersivo do Versículo do Dia com ações grandes, navegação inferior com ícone+texto,
modo foco (barras somem ao rolar) e seleção tátil de versículo via folha de ações.
Tudo 100% offline (fonte empacotada, sem download em runtime).

## User Stories

1. **US1 — Tipografia confortável (P1):** como leitor idoso, quero versículos e
   estudos em fonte serifada com altura de linha ≥ 1.5, para ler por longos períodos.
2. **US2 — Paleta acolhedora (P1):** como usuário, quero fundos aquecidos (creme no
   claro, carvão no escuro) e destaque dourado/terracota, para reduzir cansaço visual.
3. **US3 — Cartão do dia com ações claras (P1):** como usuário, quero o Versículo do
   Dia com ações de Ouvir/Favoritar/Compartilhar grandes (ícone + rótulo) na base.
4. **US4 — Navegação tátil (P1):** como usuário sênior, quero 5 abas sempre com
   ícone e texto e alvos de toque ≥ 48 dp.
5. **US5 — Modo foco (P2):** como leitor, quero as barras somem ao rolar para baixo
   na aba Bíblia e reapareçam ao rolar para cima.
6. **US6 — Seleção tátil de versículo (P2):** como leitor, quero tocar num versículo
   e ver uma folha de ações (Ouvir/Copiar/Compartilhar/Favoritar).

## Requisitos Funcionais (resumo)

- FR-001: Fonte serifada `Lora` empacotada em `assets/fonts/` (Regular/Italic/SemiBold),
  declarada em `pubspec.yaml`, aplicada a versículos e corpos de estudo/contexto.
- FR-002: Paleta com fundo creme (`#FDFBF7`) no claro e carvão (`#121212`) no escuro;
  destaque dourado escuro (texto/ícones) + terracota (favoritos).
- FR-003: Contraste WCAG AA ≥ 4.5:1 nos pares de leitura (função pura `razaoContraste`).
- FR-004: Cartão do Versículo do Dia com marca d'água de aspas e 3 ações grandes.
- FR-005: Navegação inferior com 5 destinos, `labelBehavior: alwaysShow`, altura 76.
- FR-006: Modo foco na aba Bíblia via `SliverAppBar` (superior) + `NotificationListener`
  (inferior/FAB).
- FR-007: Toque em versículo abre `showModalBottomSheet` com as 4 ações (+ estudos).
- FR-008: Escala de texto compõe o ajuste do app com o do sistema (teto 2.0).

## Critérios de Aceite

- `flutter analyze` sem issues; `flutter test` verde (152 testes).
- B12 (320 px × 1.18) sem overflow; novos casos U1–U6 cobertos e verdes.
- Sem download de fonte em runtime; sem branco/preto puros; sem regressão de TTS/favoritos.

## Arquivos

- `lib/tema.dart` (novo), `lib/widgets/cartao_versiculo_dia.dart` (novo).
- `lib/main.dart` (tema delegado, escala composta, cartão, folha de ações, modo foco).
- `lib/widgets/painel_estudos.dart`, `lib/widgets/painel_contexto_historico.dart` (tipografia).
- `pubspec.yaml` (fontes), `assets/fonts/` (Lora + OFL).
- Testes: `test/tema_test.dart`, `test/tipografia_test.dart`,
  `test/acoes_versiculo_widget_test.dart`, `test/modo_foco_leitura_test.dart`,
  `test/alvos_toque_test.dart` (novos) + atualizações em 8 arquivos existentes.
