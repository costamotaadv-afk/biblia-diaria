/// Paleta e tipografia do app (identidade visual acolhedora).
///
/// Mantém as regras de apresentação fora de `main.dart` (constituição,
/// princípio I) e as torna testáveis: contraste (WCAG) e escala de texto são
/// funções puras.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fonte serifada empacotada (`assets/fonts/`), usada no texto bíblico e nos
/// estudos. As serifas favorecem a fluidez da leitura contínua.
const String fonteSerifada = 'Lora';

/// Estilo do texto de versículo (corpo da leitura contínua na aba Bíblia).
/// A cor é aplicada no local de uso via `copyWith`, pois depende do tema.
const TextStyle estiloVersiculo = TextStyle(
  fontFamily: fonteSerifada,
  fontFamilyFallback: ['Georgia', 'Noto Serif', 'serif'],
  fontSize: 17.5,
  height: 1.65,
  letterSpacing: 0.1,
);

/// Estilo do corpo de estudos e da contextualização histórica (texto corrido).
const TextStyle estiloCorpoEstudo = TextStyle(
  fontFamily: fonteSerifada,
  fontFamilyFallback: ['Georgia', 'Noto Serif', 'serif'],
  fontSize: 17,
  height: 1.6,
  letterSpacing: 0.1,
);

/// Estilo da referência bíblica (sans, em destaque).
const TextStyle estiloReferencia = TextStyle(
  fontSize: 14.5,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.2,
);

// ---------------------------------------------------------------------------
// Paleta
// ---------------------------------------------------------------------------
//
// Fundos aquecidos (creme/off-white) no claro e carvão neutro no escuro —
// nunca branco (#FFFFFF) nem preto (#000000) puros, que cansam a vista e
// geram efeito "fantasma" ao rolar em telas OLED.

/// Dourado escuro: cor de destaque usada em textos/ícones (contraste ≥ 4.5:1
/// sobre o fundo creme). O dourado claro fica reservado a preenchimentos.
const Color douradoEscuro = Color(0xFF7A5A1E);

/// Modos de aparência do leitor.
///
/// [nome] é o valor persistido em `SharedPreferences` (chave `modo_tema`),
/// mantendo compatibilidade com o formato anterior (`tema_escuro`, booleano).
enum ModoTema {
  claro('claro'),
  escuro('escuro'),
  sepia('sepia');

  const ModoTema(this.nome);

  /// Valor persistido (string estável).
  final String nome;

  /// Converte o valor persistido em modo; nulo/desconhecido → [claro].
  static ModoTema deNome(String? nome) {
    return ModoTema.values.firstWhere(
      (m) => m.nome == nome,
      orElse: () => ModoTema.claro,
    );
  }
}

const ColorScheme _esquemaClaro = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF7A5A1E),
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFF3E3C3),
  onPrimaryContainer: Color(0xFF2B1F06),
  secondary: Color(0xFFA75A38), // terracota (favoritos, realces quentes)
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFF6DDD1),
  onSecondaryContainer: Color(0xFF34180A),
  tertiary: Color(0xFF2F4A6B), // azul-marinho (links, referências)
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFD6E3F5),
  onTertiaryContainer: Color(0xFF0B1D33),
  error: Color(0xFFBA1A1A),
  onError: Colors.white,
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFFDFBF7), // creme suave
  onSurface: Color(0xFF2A2620), // café
  surfaceContainerLowest: Color(0xFFFFFCF5),
  surfaceContainerLow: Color(0xFFF7F1E6),
  surfaceContainer: Color(0xFFF2EADD),
  surfaceContainerHigh: Color(0xFFEDE3D3),
  surfaceContainerHighest: Color(0xFFE7DCC9),
  onSurfaceVariant: Color(0xFF5A5245),
  outline: Color(0xFF8C8272),
  outlineVariant: Color(0xFFE3D8C6),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: Color(0xFF2E2A23),
  onInverseSurface: Color(0xFFF5EFE4),
  inversePrimary: Color(0xFFE3C27E),
);
const ColorScheme _esquemaEscuro = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE3C27E), // dourado claro (texto/ícones sobre o carvão)
  onPrimary: Color(0xFF2A1F06),
  primaryContainer: Color(0xFF4A3A16),
  onPrimaryContainer: Color(0xFFF5E3BE),
  secondary: Color(0xFFE9A98C),
  onSecondary: Color(0xFF3A1A0C),
  secondaryContainer: Color(0xFF54301F),
  onSecondaryContainer: Color(0xFFFFDBCF),
  tertiary: Color(0xFFA8C4E6),
  onTertiary: Color(0xFF0A2945),
  tertiaryContainer: Color(0xFF24405C),
  onTertiaryContainer: Color(0xFFD2E4F7),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF121212), // carvão, nunca preto absoluto
  onSurface: Color(0xFFE0E0E0),
  surfaceContainerLowest: Color(0xFF0D0D0D),
  surfaceContainerLow: Color(0xFF171717),
  surfaceContainer: Color(0xFF1E1E1E),
  surfaceContainerHigh: Color(0xFF262626),
  surfaceContainerHighest: Color(0xFF2E2E2E),
  onSurfaceVariant: Color(0xFFBDB6AC),
  outline: Color(0xFF8A8174),
  outlineVariant: Color(0xFF3A3A3A),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: Color(0xFFE0E0E0),
  onInverseSurface: Color(0xFF2A2620),
  inversePrimary: Color(0xFF7A5A1E),
);
const ColorScheme _esquemaSepia = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF7A5A1E), // dourado escuro (mantém o acento do app)
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFEAD9B4),
  onPrimaryContainer: Color(0xFF2B1F06),
  secondary: Color(0xFFA75A38), // terracota (favoritos, realces)
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFEED3C4),
  onSecondaryContainer: Color(0xFF34180A),
  tertiary: Color(0xFF2F4A6B), // azul-marinho (links, referências)
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFD6E3F5),
  onTertiaryContainer: Color(0xFF0B1D33),
  error: Color(0xFFBA1A1A),
  onError: Colors.white,
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFF4ECD8), // papiro sépia
  onSurface: Color(0xFF4A3A28), // tinta marrom
  surfaceContainerLowest: Color(0xFFFAF4E6),
  surfaceContainerLow: Color(0xFFF2E8D0),
  surfaceContainer: Color(0xFFECE0C4),
  surfaceContainerHigh: Color(0xFFE6D8B8),
  surfaceContainerHighest: Color(0xFFDFCFAC),
  onSurfaceVariant: Color(0xFF5B4636),
  outline: Color(0xFF8A7A5E),
  outlineVariant: Color(0xFFD9C9A6),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: Color(0xFF3A2F1E),
  onInverseSurface: Color(0xFFF5EFE4),
  inversePrimary: Color(0xFFE3C27E),
);
/// Monta o tema (claro ou escuro) com uma paleta coerente, pensada para boa
/// legibilidade de pessoas idosas: contraste alto, destaques quentes, alvos de
/// toque generosos e rótulos visíveis na navegação.
ThemeData construirTema(Brightness brightness) =>
    _montarTema(brightness == Brightness.light ? _esquemaClaro : _esquemaEscuro);

/// Tema sépia (fundo de papiro e tinta marrom) para leitura noturna confortável.
ThemeData construirTemaSepia() => _montarTema(_esquemaSepia);

ThemeData _montarTema(ColorScheme esquema) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    brightness: esquema.brightness,
  );

  return base.copyWith(
    scaffoldBackgroundColor: esquema.surface,
    textTheme: base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: esquema.surface,
      foregroundColor: esquema.onSurface,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: esquema.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: esquema.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: esquema.outlineVariant),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: esquema.surface,
      indicatorColor: esquema.primary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        final selecionado = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 13,
          fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
          color: selecionado ? esquema.primary : esquema.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final selecionado = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 26,
          color: selecionado ? esquema.primary : esquema.onSurfaceVariant,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: esquema.outline),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: esquema.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: esquema.inverseSurface,
      contentTextStyle: TextStyle(color: esquema.onInverseSurface, fontSize: 15),
    ),
  );
}
/// Combina o ajuste do app (fonte grande) com a escala de acessibilidade do
/// sistema, com teto de 2.0 para nunca estourar telas de 320 px (caso B12 da
/// matriz de QA). O valor antigo de 1.18 vira o mínimo quando `fonteGrande`.
double escalaDeTexto({
  required bool fonteGrande,
  required double escalaSistema,
}) {
  final base = fonteGrande ? 1.18 : 1.0;
  return (base * escalaSistema).clamp(1.0, 2.0);
}

/// Razão de contraste entre duas cores (WCAG 2.x). Valor ≥ 4.5 é o alvo para
/// texto normal; ≥ 3.0 para texto grande. Função pura, testável.
double razaoContraste(Color a, Color b) {
  final la = _luminanciaRelativa(a);
  final lb = _luminanciaRelativa(b);
  final maisClara = math.max(la, lb);
  final maisEscura = math.min(la, lb);
  return (maisClara + 0.05) / (maisEscura + 0.05);
}

double _luminanciaRelativa(Color cor) {
  double linearizar(double canal) => canal <= 0.03928
      ? canal / 12.92
      : math.pow((canal + 0.055) / 1.055, 2.4).toDouble();
  final r = linearizar(cor.r);
  final g = linearizar(cor.g);
  final b = linearizar(cor.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}



