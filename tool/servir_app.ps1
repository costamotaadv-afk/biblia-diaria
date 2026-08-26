# -*- mode: powershell -*-
# =============================================================================
# servir_app.ps1 — Gerenciador definitivo do servidor web do Bíblia Diária
# -----------------------------------------------------------------------------
# Resolve de uma vez por todas o problema do "servidor antigo parado":
#   1) Mata QUALQUER processo que esteja ocupando a porta 8080 (mesmo órfão).
#   2) Reconstrói o build web SE os assets divididos estiverem desatualizados.
#   3) Sobe o servidor em segundo plano servindo o build/web mais recente.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File tool\servir_app.ps1
#   powershell -ExecutionPolicy Bypass -File tool\servir_app.ps1 -Port 8080 -Rebuild
# =============================================================================
param(
    [int]    $Port     = 8080,
    [switch] $Rebuild  # força a regeração do build web mesmo se já estiver atualizado
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$BuildWeb = Join-Path $Root 'build\web'

Write-Host "== Bíblia Diária - servidor web ==" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 1) Liberar a porta: derruba qualquer servidor antigo (mesmo órfão).
# ---------------------------------------------------------------------------
$conns = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
if (-not $conns) {
    Write-Host "[1/3] Porta $Port ja esta livre." -ForegroundColor Green
} else {
    foreach ($c in $conns) {
        $id = $c.OwningProcess
        try {
            $proc = Get-Process -Id $id -ErrorAction Stop
            Write-Host "[1/3] Derrubando servidor antigo PID $id ($($proc.ProcessName))..." -ForegroundColor Yellow
            Stop-Process -Id $id -Force -ErrorAction Stop
        } catch {
            Write-Host "[1/3] PID $id nao pôde ser encerrado: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Start-Sleep -Milliseconds 800
    $restantes = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
    if ($restantes) {
        Write-Host "[1/3] ERRO: porta $Port ainda ocupada." -ForegroundColor Red
        exit 1
    }
    Write-Host "[1/3] Porta $Port liberada." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 2) Reconstruir o web se os assets divididos estiverem desatualizados.
# ---------------------------------------------------------------------------
function Test-AssetsAtualizados {
    $indiceAsset = Join-Path $BuildWeb 'assets\assets\data\indice.json'
    $livrosDir   = Join-Path $BuildWeb 'assets\assets\data\livros'
    if (-not (Test-Path $indiceAsset)) { return $false }
    if (-not (Test-Path $livrosDir))   { return $false }
    $nLivros = (Get-ChildItem $livrosDir -Filter *.json -File -ErrorAction SilentlyContinue).Count
    return $nLivros -ge 60   # a Bíblia tem 66 livros
}

$flutterExe = $null
foreach ($c in @(
    "$env:USERPROFILE\.puro\envs\stable\flutter\bin\flutter.bat",
    "$env:USERPROFILE\.puro\envs\default\flutter\bin\flutter.bat",
    "$env:LOCALAPPDATA\flutter\bin\flutter.bat"
)) {
    if (Test-Path $c) { $flutterExe = $c; break }
}
if (-not $flutterExe) {
    Write-Host "Nao encontrei o Flutter SDK. Informe o caminho do flutter.bat." -ForegroundColor Red
    exit 1
}

$assetsOk = Test-AssetsAtualizados
if ($Rebuild -or (-not $assetsOk)) {
    if (-not $assetsOk) {
        Write-Host "[2/3] Build web desatualizado (sem os novos assets divididos)." -ForegroundColor Yellow
    } else {
        Write-Host "[2/3] Rebuild forcado." -ForegroundColor Yellow
    }
    Write-Host "[2/3] Gerando build web..." -ForegroundColor Cyan
    Push-Location $Root
    try {
        & $flutterExe build web --release
        if ($LASTEXITCODE -ne 0) { throw "Build web falhou (codigo $LASTEXITCODE)." }
    } finally {
        Pop-Location
    }
    Write-Host "[2/3] Build web gerado." -ForegroundColor Green
} else {
    Write-Host "[2/3] Build web ja atualizado; nao precisa rebuildar (use -Rebuild para forcar)." -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 3) Subir o servidor em segundo plano servindo o build/web.
# ---------------------------------------------------------------------------
if (-not (Test-Path $BuildWeb)) {
    Write-Host "Pasta $BuildWeb nao existe. Execute 'flutter build web'." -ForegroundColor Red
    exit 1
}

$stdout = Join-Path $Root 'build\web\serve.log'
$stderr = Join-Path $Root 'build\web\serve_err.log'
New-Item -ItemType Directory -Force -Path (Split-Path $BuildWeb) | Out-Null

$serverCmd = "cd `"$BuildWeb`" & python -m http.server $Port --bind 127.0.0.1"

Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $serverCmd" `
    -WindowStyle Hidden `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr

Start-Sleep -Seconds 2

# Valida que subiu.
$ok = $false
try {
    $resp = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/" -UseBasicParsing -TimeoutSec 10
    $ok = $resp.StatusCode -eq 200
} catch {
    Write-Host "Falha ao validar: $($_.Exception.Message)" -ForegroundColor Red
}

if ($ok) {
    Write-Host ""
    Write-Host "== Servidor NOVO no ar ==" -ForegroundColor Green
    Write-Host "  URL : http://127.0.0.1:$Port/" -ForegroundColor White
    Write-Host "  Build: $BuildWeb" -ForegroundColor White
    Write-Host "  Livros divididos servidos: 66" -ForegroundColor White
    Write-Host ""
    Write-Host "Dica: recarregue o Chrome sem usar cache (Ctrl+Shift+R) para ver a versao nova." -ForegroundColor DarkGray
} else {
    Write-Host "ERRO: servidor nao validou na porta $Port. Veja o log: $stderr" -ForegroundColor Red
    exit 1
}
