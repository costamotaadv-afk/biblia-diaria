# Plano — Experiência de Leitura Visual

## Contexto

Briefing de UX com 5 frentes: (1) tipografia e ritmo de leitura, (2) paleta
acolhedora, (3) cartão do Versículo do Dia com ações rápidas, (4) navegação tátil,
(5) modo foco + seleção tátil de versículo na aba Bíblia.

## Decisões-chave

- **Fonte:** empacotar `Lora` (Regular/Italic/SemiBold) em `assets/fonts/`, em vez de
  `google_fonts` (que baixaria em runtime e feriria o princípio offline).
- **Paleta:** `ColorScheme` explícito (não `fromSeed`) para controle total; contraste
  validado por função pura `razaoContraste`.
- **Modo foco:** `SliverAppBar` (superior) + `NotificationListener<UserScrollNotification>`
  (inferior/FAB); a aba Bíblia passa de `ListView` para `CustomScrollView`.
- **Seleção de versículo:** substitui os 4 `IconButton` do `trailing` por `ListTile`
  tocável que abre uma folha de ações — reaproveitando o padrão de `showModalBottomSheet`.

## Fases

1. **Base visual:** baixar fontes, criar `lib/tema.dart`, delegar tema/escala em `main.dart`.
2. **Cartão do dia:** `lib/widgets/cartao_versiculo_dia.dart` + `_montarTelaInicio`.
3. **Leitura + toque:** `_linhaVersiculo` (serifada) + `_abrirAcoesVersiculo` + `_copiarVersiculo`.
4. **Modo foco:** `CustomScrollView` + `SliverAppBar` + `_aoRolar` + `AnimatedSize` no nav.
5. **Estudos/contexto + polimento:** tipografia serifada nos painéis; testes e docs.

## Riscos e tradeoffs

- Fonte variável vs estática: optamos pelos estáticos (~624 KB) pela previsibilidade.
- Rótulos curtos ("Ouvir"/"Favoritar") quebram finders por tipo/texto → 8 testes atualizados.
- `find.byType(ListView)` → `CustomScrollView` no estresse C6; marcador de decodificação
  passa de "Livro 1:1" para "Capítulo 1" (o versículo virou `Text.rich` sem referência).
- `ScrollDirection` exige `import 'package:flutter/rendering.dart' show ScrollDirection;`.

## Validação

- `flutter analyze` limpo; `flutter test` verde (152).
- Casos U1–U6 registrados em `tool/QA_EDGE_CASES.md` e cobertos por teste.
