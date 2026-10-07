# -*- coding: utf-8 -*-
# Gera artefatos de release otimizados em tamanho (sem perder funcionalidade):
#   1. App Bundle (AAB)  -> distribuição via Google Play (menor download por dispositivo)
#   2. APKs por ABI       -> distribuição direta / sideload (só a arquitetura certa)
#
# Obfuscação + separação de símbolos reduzem o libapp.so e preservam stack traces
# (guarde build/symbols/ para simbolizar crashes).
#
# Uso:  powershell -ExecutionPolicy Bypass -File tool/build_release.ps1
# Pré-requisitos: flutter no PATH e android/key.properties configurado (assinar release).

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Resolve-Flutter {
    $cmd = Get-Command flutter -ErrorAction SilentlyContinue
    if ($cmd) { return "flutter" }

    foreach ($env in @("stable", "default")) {
        $p = Join-Path $env:USERPROFILE ".puro\envs\$env\flutter\bin\flutter.bat"
        if (Test-Path $p) { return $p }
    }

    $lp = Join-Path $root "android\local.properties"
    if (Test-Path $lp) {
        $line = (Select-String -Path $lp -Pattern '^flutter\.sdk\s*=(.*)$').Line | Select-Object -First 1
        if ($line) {
            $sdk = (($line -split '=', 2)[1]).Trim()
            $sdk = $sdk.Replace('\\', '\').Replace('\:', ':')
            $p = Join-Path $sdk "bin\flutter.bat"
            if (Test-Path $p) { return $p }
        }
    }

    throw "flutter nao encontrado. Adicione ao PATH ou instale via puro."
}

$flutter = Resolve-Flutter
Write-Host "Flutter: $flutter" -ForegroundColor DarkGray

function Resolve-Jdk {
    $roots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Microsoft",
        "C:\Program Files\Java",
        "C:\Program Files (x86)\Java",
        (Join-Path $env:LOCALAPPDATA "Programs\Eclipse Adoptium"),
        (Join-Path $env:USERPROFILE ".jdks")
    )
    foreach ($r in $roots) {
        if (Test-Path $r) {
            $dir = Get-ChildItem $r -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^(jdk|jbr)-?(11|17|21|22|23|24)' } |
                Sort-Object Name -Descending | Select-Object -First 1
            if ($dir -and (Test-Path (Join-Path $dir.FullName "bin\java.exe"))) {
                return $dir.FullName
            }
        }
    }
    return $null
}

$jdk = Resolve-Jdk
if ($jdk) {
    $env:JAVA_HOME = $jdk
    Write-Host "JAVA_HOME: $jdk" -ForegroundColor DarkGray
} else {
    Write-Warning "JDK 17+ nao encontrado. O build Android vai falhar; instale um JDK 17 (ex.: winget install EclipseAdoptium.Temurin.17.JDK)."
}

$symbolsDir = "build\symbols"

Write-Host "`n[1/2] App Bundle (AAB) - Google Play" -ForegroundColor Cyan
& $flutter build appbundle --obfuscate --split-debug-info=$symbolsDir

Write-Host "`n[2/2] APKs por ABI - distribuicao direta" -ForegroundColor Cyan
& $flutter build apk --split-per-abi --obfuscate --split-debug-info=$symbolsDir

Write-Host "`n=== Artefatos gerados ===" -ForegroundColor Green
Get-ChildItem "build\app\outputs\bundle\release\*.aab", "build\app\outputs\flutter-apk\*-release.apk" -ErrorAction SilentlyContinue |
    ForEach-Object { "{0,10:N2} MB  {1}" -f ($_.Length / 1MB), $_.Name }
