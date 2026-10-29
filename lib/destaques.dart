/// Paleta de destaques de versículo (nome → hexadecimal `#RRGGBB`).
///
/// Mantida como strings hex (sem dependência de Flutter) para permitir teste
/// unitário puro. A conversão para `Color` fica na camada de UI.
library;

const Map<String, String> paletaDestaques = {
  'amarelo': '#FFF59D',
  'verde': '#C5E1A5',
  'azul': '#90CAF9',
  'rosa': '#F48FB1',
  'laranja': '#FFCC80',
};
