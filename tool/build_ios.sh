#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# Gera o build de iOS. PRECISA rodar em um macOS com Xcode (e CocoaPods, se
# aplicável) instalados. Não funciona no Windows/Linux.
#
#   verificar : compila em release SEM assinar (Runner.app) — ideal para CI
#               e validação de que o projeto iOS compila.
#   ipa       : gera o IPA assinado para distribuição (TestFlight/App Store).
#               Exige certificado + perfil de provisionamento no Xcode.
#
# Uso:  bash tool/build_ios.sh [verificar|ipa]

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Localiza o Flutter (PATH ou instalação via puro).
resolve_flutter() {
  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return
  fi
  local env_name
  for env_name in stable default; do
    local p="$HOME/.puro/envs/$env_name/flutter/bin/flutter"
    if [[ -x "$p" ]]; then
      echo "$p"
      return
    fi
  done
  # Última tentativa: deixa o comando falhar com a mensagem padrão do Flutter.
  echo "flutter"
}

FLUTTER="$(resolve_flutter)"
echo "Flutter: $FLUTTER"

MODE="${1:-verificar}"
SYMBOLS="build/symbols"

case "$MODE" in
  verificar)
    echo "==> Build iOS (release, sem assinar) para validacao =="
    "$FLUTTER" build ios --release --no-codesign
    echo
    echo "Artefato: build/ios/iphoneos/Runner.app"
    ;;
  ipa)
    echo "==> Gerando IPA assinado (exige certificado/perfil no Xcode) =="
    "$FLUTTER" build ipa --release --obfuscate --split-debug-info="$SYMBOLS"
    echo
    echo "Artefato: build/ios/ipa/*.ipa"
    echo "Simbolos (guardar para simbolizar crashes): $SYMBOLS"
    ;;
  *)
    echo "Modo desconhecido: '$MODE'. Use 'verificar' ou 'ipa'." >&2
    exit 2
    ;;
esac
