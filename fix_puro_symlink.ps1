# fix_puro_symlink.ps1
#
# Correção definitiva para o erro do frontend_server (CFE) do Dart com o Puro.
#
# Problema:
#   O Puro cria o flutter_web_sdk como um SYMBOLIC LINK (SYMLINKD) apontando
#   para o cache compartilhado (~/.puro/shared/caches/<hash>/...). O CFE do Dart
#   falha ao validar symlinks puros (Link.exists), quebrando
#   `flutter run -d chrome` / `flutter build web`.
#
# Solução:
#   Substituir o symlink por um JUNCTION POINT (mklink /J). O Windows resolve
#   junctions nativamente no nível do sistema de arquivos e o Dart os enxerga
#   como diretórios reais - sem duplicar arquivos pesados na máquina.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File .\fix_puro_symlink.ps1
#   Ou informe o caminho: .\fix_puro_symlink.ps1 -FlutterWebSdkPath "C:\...\flutter_web_sdk"

param(
    # Caminho real do flutter_web_sdk no env do Puro (ajuste se necessário)
    [string]$FlutterWebSdkPath = "C:\Users\Keynes\.puro\envs\stable\flutter\bin\cache\flutter_web_sdk"
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message, [string]$Color = 'Gray')
    Write-Host $Message -ForegroundColor $Color
}

Write-Step "Analisando $FlutterWebSdkPath..." -Color Cyan

# 1. Caminho existe?
if (-not (Test-Path -LiteralPath $FlutterWebSdkPath)) {
    Write-Step "[ERRO] Caminho nao encontrado. Verifique a variavel FlutterWebSdkPath." -Color Red
    exit 1
}

$item = Get-Item -LiteralPath $FlutterWebSdkPath -Force
$isReparsePoint = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
$targetPath = $null

if ($isReparsePoint) {
    # Extrai o alvo real do reparse point (symlink ou junction)
    $targetPath = $item.Target
    if (-not $targetPath) {
        # Fallback: resolve via fsutil (formato \\?\C:\...)
        $raw = fsutil reparsepoint query "$FlutterWebSdkPath" 2>$null | Select-String 'Print Name'
        if ($raw) {
            $targetPath = ($raw.Line -replace 'Print Name:\s*', '').Trim()
            if ($targetPath -like '\\?\*') { $targetPath = $targetPath.Substring(4) }
        }
    }

    if (-not $targetPath) {
        Write-Step "[ERRO] Nao foi possivel extrair o alvo do reparse point." -Color Red
        exit 1
    }

    $isJunction = $item.LinkType -eq 'Junction'
    if ($isJunction) {
        Write-Step "Ja e um JUNCTION -> $targetPath" -Color Green
        Write-Step "Nenhuma acao necessaria. Execucao idempotente concluida." -Color Green
        exit 0
    }

    # 2. Validacao de seguranca antes de remover
    if (-not (Test-Path -LiteralPath $targetPath)) {
        Write-Step "[ERRO] O alvo $targetPath nao existe. Abortando para nao corromper o cache." -Color Red
        exit 1
    }
    if ($targetPath -eq $FlutterWebSdkPath) {
        Write-Step "[ERRO] Alvo igual ao proprio caminho. Abortando." -Color Red
        exit 1
    }

    Write-Step "Symlink do Puro detectado (tipo: $($item.LinkType))." -Color Yellow
    Write-Step "Alvo real: $targetPath" -Color DarkGray

    # 3. Remove SOMENTE o link (rmdir nao segue o alvo; Remove-Item -Recurse apagaria o cache!)
    cmd /c rmdir "$FlutterWebSdkPath"
    if (Test-Path -LiteralPath $FlutterWebSdkPath) {
        Write-Step "[ERRO] Falha ao remover o symlink. Verifique se algum processo esta usando o caminho." -Color Red
        exit 1
    }
    Write-Step "Symlink removido com sucesso (apenas o link, o cache foi preservado)." -Color Green

    # 4. Cria o Junction Point no lugar (resolvido nativamente pelo Windows/Dart)
    Write-Step "Criando Junction Point..." -Color Cyan
    cmd /c mklink /J "$FlutterWebSdkPath" "$targetPath"

    # 5. Validacao final
    $newItem = Get-Item -LiteralPath $FlutterWebSdkPath -Force
    if ($newItem.LinkType -eq 'Junction') {
        Write-Step "`n[OK] Correcao aplicada! flutter_web_sdk agora e um JUNCTION." -Color Green
        Write-Step "Alvo: $targetPath" -Color DarkGray
        Write-Step "Voce pode executar 'flutter run -d chrome' normalmente." -Color White
    } else {
        Write-Step "[ERRO] A criacao da Junction falhou. Verifique permissoes (administrador) e tente novamente." -Color Red
        exit 1
    }
} else {
    # Não é reparse point: diretório real ou inexistente como link
    Write-Step "[OK] O caminho existe e nao e um symlink problemático. Nenhuma acao necessaria." -Color Green
}
