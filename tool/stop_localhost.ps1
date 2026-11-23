# -*- mode: powershell -*-
# =============================================================================
# stop_localhost.ps1 — Encerra os serviços locais (Streamlit + Flutter Web)
# -----------------------------------------------------------------------------
# 1) Lê os PIDs gravados por dev_localhost.ps1 e encerra a árvore de processos;
# 2) Garante que as portas 8501 e 7357 estejam livres (fallback por porta para
#    casos órfãos — ex.: janela do Flutter fechada na mão).
#
# NUNCA toca a porta 8080 (tool/servir_app.ps1) nem encerra python.exe genérico.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File tool\stop_localhost.ps1
#   powershell -ExecutionPolicy Bypass -File tool\stop_localhost.ps1 -StreamlitPort 8501 -FlutterPort 7357
# =============================================================================
param(
    [int] $StreamlitPort = 8501,
    [int] $FlutterPort   = 7357
)

$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $PSScriptRoot
$PidsFile = Join-Path $Root 'build\dev-pids.json'

Write-Host '== Bíblia Diária - parar serviços locais ==' -ForegroundColor Cyan

function Stop-Arvore([int]$Id, [string]$Rotulo) {
    $proc = Get-Process -Id $Id -ErrorAction SilentlyContinue
    if (-not $proc) { return }
    Write-Host "[$Rotulo] encerrando árvore do PID $Id ($($proc.ProcessName))..." -ForegroundColor Yellow
    taskkill /PID $Id /T /F 2>$null | Out-Null
}

function Stop-OuvintePorta([int]$Porta, [string]$Rotulo) {
    $conns = Get-NetTCPConnection -State Listen -LocalPort $Porta -ErrorAction SilentlyContinue
    if (-not $conns) {
        Write-Host "[$Rotulo] porta $Porta já livre." -ForegroundColor Green
        return
    }
    foreach ($c in $conns) {
        $id = $c.OwningProcess
        $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
        $nome = if ($proc) { $proc.ProcessName } else { 'desconhecido' }
        Write-Host "[$Rotulo] encerrando PID $id ($nome) na porta $Porta..." -ForegroundColor Yellow
        taskkill /PID $id /T /F 2>$null | Out-Null
    }
    Start-Sleep -Milliseconds 600
    $resto = Get-NetTCPConnection -State Listen -LocalPort $Porta -ErrorAction SilentlyContinue
    if ($resto) {
        Write-Host "[$Rotulo] ERRO: porta $Porta ainda ocupada." -ForegroundColor Red
    } else {
        Write-Host "[$Rotulo] porta $Porta liberada." -ForegroundColor Green
    }
}

# 1) PIDs rastreados pelo dev_localhost.ps1
if (Test-Path $PidsFile) {
    try {
        $pids = Get-Content $PidsFile -Raw | ConvertFrom-Json
        foreach ($rotulo in @('streamlit', 'flutter')) {
            $id = $pids.$rotulo
            if ($id) { Stop-Arvore ([int]$id) $rotulo }
        }
    } catch {
        Write-Host 'Não consegui ler os PIDs salvos; seguindo para o fallback por porta.' -ForegroundColor DarkGray
    }
    Remove-Item $PidsFile -Force -ErrorAction SilentlyContinue
}

# 2) Fallback por porta (cobre processos órfãos)
Stop-OuvintePorta $StreamlitPort 'Streamlit'
Stop-OuvintePorta $FlutterPort 'Flutter'

Write-Host ''
Write-Host 'Portas 8501 e 7357 verificadas. A 8080 (servir_app.ps1) não foi tocada.' -ForegroundColor DarkGray
