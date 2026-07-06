# Abre o Chrome com a porta de debug (CDP) ligada, para o MCP de browser conectar.
# Perfil dedicado (nao mexe no seu Chrome normal). Loga no simulador 1x e fica salvo.

$port = 9222
$userData = "$env:LOCALAPPDATA\chrome-indecx-agent"   # perfil dedicado deste agente

# Acha o chrome.exe
$chrome = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $chrome) { Write-Error "chrome.exe nao encontrado. Ajuste o caminho no script."; exit 1 }

if (-not (Test-Path $userData)) { New-Item -ItemType Directory -Path $userData | Out-Null }

# Ja existe algo escutando na porta?
$inUse = Test-NetConnection -ComputerName 127.0.0.1 -Port $port -WarningAction SilentlyContinue
if ($inUse.TcpTestSucceeded) {
  Write-Host "Porta $port ja em uso. Chrome de debug provavelmente ja aberto." -ForegroundColor Yellow
  exit 0
}

& $chrome `
  "--remote-debugging-port=$port" `
  "--user-data-dir=$userData" `
  "--no-first-run" `
  "--no-default-browser-check"

Write-Host "Chrome debug aberto na porta $port (perfil: $userData)." -ForegroundColor Green
Write-Host "Na 1a vez: navegue ate o simulador do LinkedIn e faca login. Depois fica salvo." -ForegroundColor Cyan
