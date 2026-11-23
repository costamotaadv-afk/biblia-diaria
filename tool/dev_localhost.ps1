# -*- mode: powershell -*-
# =============================================================================
# dev_localhost.ps1 — Sobe os DOIS serviços locais do Bíblia Diária
# -----------------------------------------------------------------------------
#   Streamlit (webapp Python) : http://127.0.0.1:8501  (recarrega no navegador)
#   Flutter Web (hot reload)   : http://127.0.0.1:7357  (aperte "r" p/ hot reload)
#
# Mantém os dois processos em janelas separadas e independentes, para que
# reiniciar o Flutter não derrube o Streamlit (e vice-versa). É idempotente:
# se a porta já estiver em uso, assume que o serviço já está no ar.
#
# A porta 8080 fica reservada ao tool/servir_app.ps1 (build estático) e NUNCA é
# tocada aqui.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File tool\dev_localhost.ps1
#   powershell -ExecutionPolicy Bypass -File tool\dev_localhost.ps1 -OnlyStreamlit
#   powershell -ExecutionPolicy Bypass -File tool\dev_localhost.ps1 -OnlyFlutter -FlutterChrome
#   powershell -ExecutionPolicy Bypass -File tool\dev_localhost.ps1 -SkipVenv
#
# Parar tudo: tool\stop_localhost.ps1
# =============================================================================
param(
    [int]    $StreamlitPort = 8501,
    [int]    $FlutterPort   = 7357,
    [switch] $SkipVenv,        # não cria/usa .venv (usa Python global)
    [switch] $OnlyStreamlit,   # sobe apenas o Streamlit
    [switch] $OnlyFlutter,     # sobe apenas o Flutter Web
    [switch] $NoBrowser,       # não abre o navegador automaticamente
    [switch] $FlutterChrome    # usa "flutter run -d chrome" em vez de web-server
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$PidsFile = Join-Path $Root 'build\dev-pids.json'
$StreamlitUrl = "http://127.0.0.1:$StreamlitPort"
$FlutterUrl   = "http://127.0.0.1:$FlutterPort"
$streamlitPid = $null
$flutterPid   = $null

Set-Location $Root

Write-Host '== Bíblia Diária - dev localhost (2 serviços) ==' -ForegroundColor Cyan
Write-Host "  Streamlit : $StreamlitUrl" -ForegroundColor White
Write-Host "  Flutter   : $FlutterUrl" -ForegroundColor White
Write-Host ''

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Test-PortaEmUso([int]$Porta) {
    $conns = Get-NetTCPConnection -State Listen -LocalPort $Porta -ErrorAction SilentlyContinue
    return [bool]$conns
}

function Wait-Url([string]$Url, [int]$TimeoutSec = 180) {
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
            if ($resp.StatusCode -eq 200) { return $true }
        } catch {
            # serviço ainda subindo
        }
        Start-Sleep -Seconds 2
    }
    return $false
}

function Resolve-Python {
    $venvPy = Join-Path $Root '.venv\Scripts\python.exe'

    if (-not $SkipVenv) {
        if (Test-Path $venvPy) { return $venvPy }

        $cmd = Get-Command python -ErrorAction SilentlyContinue
        if (-not $cmd) { throw 'python não encontrado no PATH. Instale o Python ou use -SkipVenv.' }

        Write-Host '[venv] criando .venv ...' -ForegroundColor Cyan
        & $cmd.Source -m venv (Join-Path $Root '.venv')
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar .venv.' }
        if (-not (Test-Path $venvPy)) { throw '.venv criado sem python.exe.' }

        Write-Host '[venv] instalando requirements.txt ...' -ForegroundColor Cyan
        & $venvPy -m pip install -r (Join-Path $Root 'requirements.txt')
        if ($LASTEXITCODE -ne 0) { throw 'pip install falhou.' }
        Write-Host '[venv] pronto.' -ForegroundColor Green
        return $venvPy
    }

    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $cmd) { throw 'python não encontrado no PATH.' }
    Write-Host '[venv] usando Python global (-SkipVenv).' -ForegroundColor DarkGray
    return $cmd.Source
}

function Resolve-FlutterInvoke {
    $puro = Get-Command puro -ErrorAction SilentlyContinue
    if ($puro) { return 'puro flutter' }
    foreach ($e in @('stable', 'default')) {
        $fb = Join-Path $env:USERPROFILE ".puro\envs\$e\flutter\bin\flutter.bat"
        if (Test-Path $fb) { return "& $fb" }
    }
    throw 'flutter/puro não encontrado. Instale o puro (https://puro.dev).'
}

function Save-Pids {
    $obj = New-Object -TypeName psobject
    if ($streamlitPid) { $obj | Add-Member -NotePropertyName streamlit -NotePropertyValue ([int]$streamlitPid) }
    if ($flutterPid)   { $obj | Add-Member -NotePropertyName flutter   -NotePropertyValue ([int]$flutterPid) }
    New-Item -ItemType Directory -Force -Path (Split-Path $PidsFile) | Out-Null
    $obj | ConvertTo-Json | Set-Content -Path $PidsFile -Encoding UTF8
}

# ---------------------------------------------------------------------------
# 1) Streamlit (webapp Python) — porta 8501
# ---------------------------------------------------------------------------
$pythonExe = Resolve-Python

if ($OnlyFlutter) {
    Write-Host '[Streamlit] ignorado (-OnlyFlutter).' -ForegroundColor DarkGray
} elseif (Test-PortaEmUso $StreamlitPort) {
    Write-Host "[Streamlit] porta $StreamlitPort já em uso; assumindo que já está no ar." -ForegroundColor DarkGray
} else {
    Write-Host "[Streamlit] subindo em $StreamlitUrl ..." -ForegroundColor Cyan
    $env:BIBLIA_PERSIST = '1'   # favoritos/preferências persistem durante os testes
    $streamlitArgs = @(
        '-m', 'streamlit', 'run', 'webapp/streamlit_app.py',
        '--server.address', '127.0.0.1',
        '--server.port', "$StreamlitPort"
    )
    $proc = Start-Process -FilePath $pythonExe -ArgumentList $streamlitArgs -WorkingDirectory $Root -PassThru
    $streamlitPid = $proc.Id
    Write-Host "[Streamlit] PID $streamlitPid." -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# 2) Flutter Web (hot reload) — porta 7357
# ---------------------------------------------------------------------------
if ($OnlyStreamlit) {
    Write-Host '[Flutter] ignorado (-OnlyStreamlit).' -ForegroundColor DarkGray
} elseif (Test-PortaEmUso $FlutterPort) {
    Write-Host "[Flutter] porta $FlutterPort já em uso; assumindo que já está no ar." -ForegroundColor DarkGray
} else {
    $flutterInvoke = Resolve-FlutterInvoke
    $device = if ($FlutterChrome) { 'chrome' } else { 'web-server' }
    Write-Host "[Flutter] subindo em $FlutterUrl (device=$device) ..." -ForegroundColor Cyan

    $inner = "Set-Location -LiteralPath '$Root'; $flutterInvoke run -d $device --web-hostname 127.0.0.1 --web-port $FlutterPort"
    $argStr = "-NoExit -NoProfile -Command `"$inner`""
    $proc = Start-Process powershell.exe -ArgumentList $argStr -WorkingDirectory $Root -PassThru
    $flutterPid = $proc.Id
    Write-Host "[Flutter] janela aberta (PID $flutterPid). Aperte 'r' nela para hot reload." -ForegroundColor DarkGray
}

Save-Pids

# ---------------------------------------------------------------------------
# 3) Abrir navegador (após o serviço responder HTTP 200)
# ---------------------------------------------------------------------------
if (-not $NoBrowser) {
    if (-not $OnlyFlutter) {
        if (Wait-Url $StreamlitUrl 60) {
            Start-Process $StreamlitUrl
            Write-Host "[Streamlit] no ar: $StreamlitUrl" -ForegroundColor Green
        } else {
            Write-Host "[Streamlit] não respondeu a tempo; abra manualmente $StreamlitUrl" -ForegroundColor Yellow
        }
    }
    if (-not $OnlyStreamlit) {
        if (Wait-Url $FlutterUrl 180) {
            Start-Process $FlutterUrl
            Write-Host "[Flutter] no ar: $FlutterUrl" -ForegroundColor Green
        } else {
            Write-Host "[Flutter] não respondeu a tempo (1º build é lento); abra manualmente $FlutterUrl" -ForegroundColor Yellow
        }
    }
}

Write-Host ''
Write-Host '== Pronto ==' -ForegroundColor Green
Write-Host '  Streamlit  : ' -NoNewline; Write-Host $StreamlitUrl -ForegroundColor White
Write-Host '  Flutter web: ' -NoNewline; Write-Host $FlutterUrl -ForegroundColor White
Write-Host '  Parar tudo : powershell -ExecutionPolicy Bypass -File tool\stop_localhost.ps1' -ForegroundColor DarkGray
Write-Host '  Hot reload : aperte "r" na janela do Flutter; o Streamlit recarrega sozinho.' -ForegroundColor DarkGray
