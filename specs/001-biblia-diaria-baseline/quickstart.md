# Quickstart — Bíblia Diária (Validação rápida e testes locais)

Guia curto para abrir o projeto, rodar a suíte de testes e validar as
funcionalidades da linha de base (spec em [spec.md](spec.md), plano em
[plan.md](plan.md)). Fluxo "se quebrou algo, rode isto primeiro".

**Ambiente atual**: Flutter SDK (`>=3.0.0 <4.0.0`, env Puro `stable`).
Desenvolvimento e validação em **web e Windows**; o Android SDK ainda não está
instalado nesta máquina, então builds Android ficam para uma etapa posterior.

## 1. Pré-requisitos

1. Flutter SDK instalado e `flutter doctor` sem erros bloqueantes.
2. Dependências baixadas:
   ```powershell
   flutter pub get
   ```

## 2. Validação automatizada (suíte completa)

```powershell
flutter analyze          # lint estático (flutter_lints)
flutter test             # todos os testes unitários + widget
```

A suíte cobre os casos da matriz de QA (`tool/QA_EDGE_CASES.md`) — todos os
arquivos de teste referenciam os casos E/C/B que protegem:

| Arquivo de teste | Casos | O que valida |
| :--- | :--- | :--- |
| `test/dados_biblicos_test.dart` | — | Integridade dos ~31.100 versículos reais (assets) |
| `test/limites_dados_test.dart` | E1–E9, E13, B5 | Guardiões de dados, fallbacks e determinismo do dia |
| `test/edge_cases_e10_test.dart` | E10 | TTS lê livros com prefixo numérico corretamente |
| `test/concurrency_c4_test.dart` | C4 | Favoritos: fila last-write-wins (sem perda em toques rápidos) |
| `test/cache_livros_test.dart` | C5 | Cache com retry após falha transiente |
| `test/tts_concorrencia_test.dart` | C1, C13 | Duplo-toque em Ouvir e em Copiar Pix não quebram |
| `test/tts_qualidade_test.dart` | B6, B7, TTS | Configuração de voz (pt-BR, 0.36) e fallback de `voz_tts_id` |
| `test/platform_c10_c11_test.dart` | C10, C11 | AdMob sem GMS e TTS na web não crasham |
| `test/banner_c9_test.dart` | C9 | Falha de `load()` do banner é tratada |
| `test/clipboard_b2_test.dart` | B2 | Clipboard negado → erro amigável (nunca "sucesso" falso) |
| `test/config_negocio_test.dart` | B3, B8 | Chave Pix válida; sem ID de anúncio de teste em release |
| `test/virada_dia_b4_test.dart` | B4 | Versículo do dia muda na virada do dia |
| `test/overflow_b12_test.dart` | B12 | 320 px × fonte 1.18 sem overflow nas 4 abas |
| `test/estresse_e15_test.dart` | E15 | 200+ favoritos carregam e rolam sem travar |
| `test/widget_test.dart` | fluxo geral | Abertura, favoritos persistentes e navegação |

Para rodar um arquivo isolado (mais rápido durante o desenvolvimento):

```powershell
flutter test test/clipboard_b2_test.dart
```

## 3. Rodar o app localmente

```powershell
flutter run -d windows     # desktop: onde o TTS funciona
flutter run -d chrome      # web: plataforma de validação atual
flutter run -d <android>   # emulador/aparelho (exige Android SDK)
```

O que conferir em cada plataforma:

- **Web (Chrome)**: versículo do dia determinístico, Bíblia offline, favoritos e
  Pix funcionam. O TTS **não** existe na web → botões "Ouvir" ficam
  desabilitados (comportamento esperado, caso C11). Sem banner.
- **Windows (desktop)**: adicione a validação de **leitura em voz alta**
  (pausar/continuar) e a cópia de Pix; anúncios continuam indisponíveis.
- **Android (quando houver SDK)**: validação final — banner AdMob (degradação
  sem GMS), TTS com voz real do aparelho e publicação.

## 4. Roteiro de validação manual (5 minutos)

1. Abrir o app sem rede → "Versículo do Dia" aparece com referência + mensagem;
   reabrir na mesma data → mesmo conteúdo (FR-001, SC-002).
2. Navegar pelos 66 livros e abrir capítulos sob demanda; testar nomes como
   "1 Coríntios" (FR-002/FR-003).
3. Salvar um versículo e um capítulo, reiniciar o app → continuam em "Salvos"
   (FR-004/FR-005, SC-004).
4. No Windows: "Ouvir versículo" → começa, pausa, continua e para no fim do
   trecho (FR-006/FR-007/FR-008/FR-009).
5. Alternar tema escuro/fonte grande em janela estreita → sem texto cortado
   (FR-011, SC-006).
6. "Copiar chave Pix" → diálogo numerado com aviso de conferir o recebedor
   (FR-012). Bloquear a permissão no navegador → mensagem de falha amigável.
7. Em aparelho/emulador sem serviços do Google → o app abre sem anúncios e sem
   erro (FR-013/FR-014).

## 5. Convenções de teste (importante ao alterar código)

- **Um único `testWidgets` por arquivo quando há carga de assets**: o `runAsync`
  do `rootBundle` deixa estado residual entre testes do mesmo arquivo (o 2º
  `testWidgets` falha ao abrir o app). Fases combinadas em um teste só — ver
  `test/clipboard_b2_test.dart`.
- **Mocks de canal**: TTS (`flutter_tts`), Clipboard (`SystemChannels.platform`)
  e `SharedPreferences.setMockInitialValues` são mockados via
  `TestDefaultBinaryMessengerBinding`.
- **Toda mudança**: atualizar a matriz `tool/QA_EDGE_CASES.md` e criar/adicionar
  teste referenciando o caso; contratos em `contracts/` devem ser atualizados em
  conjunto.

## 6. Troubleshooting rápido

| Sintoma | Causa provável / ação |
| :--- | :--- |
| `flutter test` falha no 2º teste de um arquivo de UI | Regra do `runAsync`: combine as fases em um único `testWidgets` (seção 5) |
| Botões "Ouvir" desabilitados na web/Linux | Esperado — plugin `flutter_tts` não existe nessas plataformas (C11) |
| Banner nunca aparece em web/Windows | Esperado — AdMob é só Android/iOS (C10/C9) |
| Copiar Pix não mostra diálogo de sucesso no navegador | Permissão `clipboard-write` negada — deve aparecer a mensagem de cópia manual (B2) |
| Erro de plugin após mudar `pubspec.yaml` | Rodar `flutter pub get` novamente |

## 7. Antes de publicar (release)

1. `flutter analyze` e `flutter test` 100% verdes (SC-007).
2. Trocar IDs de anúncio de teste pelos reais (Manifest + `banner_anuncio.dart`)
   — nenhum `ca-app-pub-3940…` em release (B8/FR-015).
3. Confirmar que `chavePix` é um e-mail válido ativo (B3/FR-015).
4. Com o Android SDK instalado: `flutter build appbundle`.
