# materialize_sdk.ps1
#
# Solução DEFINITIVA para o erro:
#   "Error: SDK root directory not found: ../.puro/envs/stable/flutter/bin/cache/flutter_web_sdk/."
#   ao executar `flutter run -d chrome` / `flutter run -d web-server` com o Puro.
#
# Causa raiz:
#   1. O Puro cria o flutter_web_sdk como REPARSE POINT (symlink/junction)
#      apontando para o cache compartilhado (~/.puro/shared/caches/<hash>/...).
#   2. O frontend_server (CFE) do Dart SEMPRE adiciona barra final no sdk-root
#      (função _ensureFolderPath) e valida com:
#          File.fromUri(uri).existsSync()              // false: é diretório, não arquivo
#          FileSystemEntity.isDirectorySync(path)      // FALSE no Windows com barra final
#                                                      // quando o caminho é um reparse point!
#   3. Resultado: .exists() retorna false => "SDK root directory not found".
#
# Solução: substituir o link por um DIRETÓRIO FÍSICO REAL (cópia do cache).
# Diretórios reais passam no isDirectorySync mesmo com barra final no Windows.
# Custo: ~116 MB (1ª vez). O cache compartilhado do Puro permanece intacto.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File .\materialize_sdk.ps1
#   powershell -ExecutionPolicy Bypass -File .\materialize_sdk.ps1 -SdkPath "C:\...\flutter_web_sdk"

param(
    # Caminho do flutter_web_sdk no env do Puro (ajuste se necessário)
    [string]$SdkPath = "C:\Users\Keynes\.puro\envs\stable\flutter\bin\cache\flutter_web_sdk"
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message, [string]$Color = 'Gray')
    Write-Host $Message -ForegroundColor $Color
}

Write-Step "Verificando o estado do flutter_web_sdk..." -Color Cyan

# 1. Caminho existe?
if (-not (Test-Path -LiteralPath $SdkPath)) {
    Write-Step "[ERRO] Caminho nao encontrado: $SdkPath. Verifique a variavel SdkPath." -Color Red
    exit 1
}

$item = Get-Item -LiteralPath $SdkPath -Force
$isReparsePoint = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0

if ($isReparsePoint) {
    # Extrai o alvo real (symlink ou junction)
    $targetPath = $item.Target
    if (-not $targetPath) {
        $raw = fsutil reparsepoint query "$SdkPath" 2>$null | Select-String 'Print Name'
        if ($raw) {
            $targetPath = ($raw.Line -replace 'Print Name:\s*', '').Trim()
            if ($targetPath -like '\\?\*') { $targetPath = $targetPath.Substring(4) }
        }
    }
    if (-not $targetPath -or -not (Test-Path -LiteralPath $targetPath)) {
        Write-Step "[ERRO] Nao foi possivel resolver/validar o alvo: $targetPath" -Color Red
        exit 1
    }

    Write-Step "Reparse point detectado ($($item.LinkType)) apontando para: $targetPath" -Color Yellow

    # 2. Checagem de espaço em disco
    $drive = [System.IO.Path]::GetPathRoot($SdkPath)
    $free = [System.IO.DriveInfo]::new($drive).AvailableFreeSpace
    $targetSize = (Get-ChildItem -LiteralPath $targetPath -Recurse -Force -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    Write-Step ("Espaco livre em $drive : {0:N1} GB | Tamanho a copiar: {1:N1} MB" -f `
        ($free / 1GB), ($targetSize / 1MB)) -Color DarkGray
    if ($free -lt ($targetSize * 1.5)) {
        Write-Step "[ERRO] Espaco em disco insuficiente. Abortando." -Color Red
        exit 1
    }

    # 3. Remove SOMENTE o link. ATENÇÃO: NÃO usar Remove-Item -Recurse aqui
    #    (apagaria o conteúdo do ALVO). rmdir remove apenas o reparse point.
    Write-Step "Removendo o reparse point (apenas o link, preservando o cache)..." -Color DarkGray
    cmd /c rmdir "$SdkPath"
    if (Test-Path -LiteralPath $SdkPath) {
        Write-Step "[ERRO] Falha ao remover o link. Feche processos que usam o caminho e tente novamente." -Color Red
        exit 1
    }

    # 4. Cópia física (materialização) do cache para o env
    Write-Step "Copiando arquivos fisicos (115 MB aprox., pode levar alguns segundos)..." -Color DarkGray
    New-Item -ItemType Directory -Path $SdkPath | Out-Null
    Copy-Item -Path (Join-Path $targetPath '*') -Destination $SdkPath -Recurse -Force

    # 5. Validação final
    $newItem = Get-Item -LiteralPath $SdkPath -Force
    $isStillReparsePoint = ($newItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    if ($isStillReparsePoint) {
        Write-Step "[ERRO] O diretorio ainda e um reparse point. Materializacao falhou." -Color Red
        exit 1
    }
    $sdkMarkers = @('dart-sdk', 'kernel', 'flutter_js', 'libraries.json')
    $found = ($sdkMarkers | Where-Object { Test-Path (Join-Path $SdkPath $_) }).Count
    Write-Step "[OK] Diretorio materializado com sucesso!" -Color Green
    Write-Step "     Novo tipo: $($newItem.Attributes)" -Color DarkGray
    Write-Step "     Marcadores encontrados: $found de $($sdkMarkers.Count)" -Color DarkGray
    Write-Step "O frontend_server agora passara no isDirectorySync mesmo com a barra final." -Color White
} elseif ($null -ne $item) {
    Write-Step "[OK] O caminho ja e um diretorio fisico real. Nenhuma acao necessaria." -Color Green
}
