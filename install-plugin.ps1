#Requires -Version 5.1
$ErrorActionPreference = "Stop"


# ── Banner ────────────────────────────────────────────────────────────────────
$OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::UTF8
Clear-Host
Write-Host ""
Write-Host "  #                                #####                          " -ForegroundColor Cyan
Write-Host "  #       #    #   ##   #####  #  #     #  ####   ####  #       #####" -ForegroundColor Cyan
Write-Host "  #       #    #  #  #    #    #  #       #    # #    # #       #    #" -ForegroundColor Cyan
Write-Host "  #       #    # #    #   #    #   #####  #    # #    # #       #####" -ForegroundColor Cyan
Write-Host "  #       #    # ######   #    #        # #    # #    # #       #    #" -ForegroundColor Cyan
Write-Host "  #       #    # #    #   #    #  #     # #    # #    # #       #    #" -ForegroundColor Cyan
Write-Host "  #######  ####  #    #   #    #   #####   ####   ####  ####### #####" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Plugin Installer  v7.2.2" -ForegroundColor DarkCyan
Write-Host "  -------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# -- Funcoes ───────────────────────────────────────────────────────────────────
function Write-Step  { param($msg) Write-Host "  [ " -NoNewline; Write-Host "*" -ForegroundColor Cyan -NoNewline; Write-Host " ] $msg" }
function Write-Ok    { param($msg) Write-Host "  [ " -NoNewline; Write-Host "OK" -ForegroundColor Green -NoNewline; Write-Host " ] $msg" }
function Write-Fail  { param($msg) Write-Host "  [ " -NoNewline; Write-Host "!!" -ForegroundColor Red -NoNewline; Write-Host " ] $msg"; Read-Host "  Pressione Enter para sair"; exit 1 }
function Write-Warn  { param($msg) Write-Host "  [ " -NoNewline; Write-Host "!" -ForegroundColor Yellow -NoNewline; Write-Host " ] $msg" }

# ── Localizar Steam ───────────────────────────────────────────────────────────
Write-Step "Localizando instalacao da Steam..."

$steamPath = $null
$regPaths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
    "HKLM:\SOFTWARE\Valve\Steam",
    "HKCU:\SOFTWARE\Valve\Steam"
)
foreach ($rp in $regPaths) {
    try {
        $val = (Get-ItemProperty -Path $rp -Name InstallPath -ErrorAction Stop).InstallPath
        if (Test-Path "$val\steam.exe") { $steamPath = $val; break }
    } catch {}
}
if (-not $steamPath -and (Test-Path "C:\Program Files (x86)\Steam\steam.exe")) {
    $steamPath = "C:\Program Files (x86)\Steam"
}
if (-not $steamPath) {
    Write-Warn "Steam nao encontrada automaticamente."
    $steamPath = Read-Host "  Cole o caminho da Steam"
}
if (-not (Test-Path "$steamPath\steam.exe")) {
    Write-Fail "steam.exe nao encontrado em: $steamPath"
}
Write-Ok "Steam: $steamPath"

# ── Verificar Millennium ──────────────────────────────────────────────────────
Write-Step "Verificando Millennium..."
$millenniumFound = (Test-Path "$steamPath\user32.dll") -or `
                   (Test-Path "$steamPath\millennium.dll") -or `
                   (Test-Path "$steamPath\plugins") -or `
                   (Test-Path "$steamPath\ext\millennium.pyd")
if (-not $millenniumFound) {
    Write-Fail "Millennium nao esta instalado. Acesse: https://millennium.web.app"
}
Write-Ok "Millennium detectado"

# ── Download do plugin ────────────────────────────────────────────────────────
Write-Step "Baixando plugin atualizado..."

$zipUrl    = "https://raw.githubusercontent.com/KendallCk2/steamtols/main/luatools.zip"
$tmpZip    = "$env:TEMP\luatools_updated.zip"
$pluginDir = "$steamPath\plugins\luatools"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $zipUrl -OutFile $tmpZip -UseBasicParsing
} catch {
    Write-Fail "Falha no download: $_"
}
Write-Ok "Download concluido"

# ── Fechar Steam ──────────────────────────────────────────────────────────────
$steamProc = Get-Process -Name "steam" -ErrorAction SilentlyContinue
if ($steamProc) {
    Write-Step "Fechando Steam..."
    $steamProc | Stop-Process -Force
    Start-Sleep -Seconds 3
    Write-Ok "Steam encerrada"
}

# ── Instalar ──────────────────────────────────────────────────────────────────
Write-Step "Instalando plugin..."

if (Test-Path $pluginDir) {
    Remove-Item -Recurse -Force $pluginDir
}
New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null
Expand-Archive -Path $tmpZip -DestinationPath $pluginDir -Force
Remove-Item $tmpZip -Force

if (-not (Test-Path "$pluginDir\plugin.json")) {
    Write-Fail "Instalacao incompleta - plugin.json nao encontrado."
}
Write-Ok "Plugin instalado em: $pluginDir"

# -- Concluido ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  -------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Instalacao concluida com sucesso!" -ForegroundColor Green
Write-Host "  -------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

$launch = Read-Host "  Abrir a Steam agora? [S/N]"
if ($launch -match "^[Ss]$") {
    Start-Process "$steamPath\steam.exe"
}

Write-Host ""
