<#
.SYNOPSIS
  Gera imagem de post (cena fotorrealista) via OpenAI gpt-image-2 e salva em PNG.

.DESCRIPTION
  Usado pela skill linkedin-post-pessoal quando o Analista escolhe tipo de imagem
  = "cena" (foto realista), em vez do card de conceito em código.
  Chama POST https://api.openai.com/v1/images/generations, decodifica o base64
  e grava o arquivo. NUNCA imprime a chave. Em erro, sai com codigo != 0 para a
  skill cair no fallback (card em código).

  Lê OPENAI_API_KEY do ambiente; se ausente, tenta ler o .env na raiz do repo.

.EXAMPLE
  .\assets\gerar-imagem-openai.ps1 -Prompt "photorealistic ..." `
    -Out "posts_gerados\meu-slug\imagem.png"

.EXAMPLE
  .\assets\gerar-imagem-openai.ps1 -Prompt "..." -Out "...\imagem.png" `
    -Size "1024x1536" -Quality high
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string] $Prompt,
  [Parameter(Mandatory = $true)] [string] $Out,
  [ValidateNotNullOrEmpty()]     [string] $Size    = "1200x1200",
  [ValidateSet("low", "medium", "high", "auto")] [string] $Quality = "medium",
  [ValidateNotNullOrEmpty()]     [string] $Model   = "gpt-image-2",
  [int] $TimeoutSec = 300
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Resolve-ApiKey {
  if ($env:OPENAI_API_KEY) { return $env:OPENAI_API_KEY }
  # Fallback: .env na raiz do repo (assets/ é filha direta da raiz).
  $root = Split-Path -Parent $PSScriptRoot
  $envFile = Join-Path $root ".env"
  if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile) {
      if ($line -match '^\s*OPENAI_API_KEY\s*=\s*(.+?)\s*$') {
        return $Matches[1].Trim('"').Trim("'")
      }
    }
  }
  return $null
}

$apiKey = Resolve-ApiKey
if (-not $apiKey) {
  [Console]::Error.WriteLine("ERRO: OPENAI_API_KEY ausente (nem no ambiente nem no .env da raiz). Configure e tente de novo.")
  exit 2
}

# Caminho de saida absoluto (o arquivo ainda nao existe, entao nao usar Resolve-Path nele).
$absOut = if ([IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path (Get-Location).Path $Out }
$outDir = Split-Path -Parent $absOut
if ($outDir -and -not (Test-Path $outDir)) {
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

# A família gpt-image NÃO aceita "response_format"; sempre devolve b64_json em data[].
$payload = @{
  model   = $Model
  prompt  = $Prompt
  size    = $Size
  quality = $Quality
  n       = 1
}
$json  = $payload | ConvertTo-Json -Depth 5
$bytes = [Text.Encoding]::UTF8.GetBytes($json)

try {
  $resp = Invoke-RestMethod -Uri "https://api.openai.com/v1/images/generations" `
    -Method Post -TimeoutSec $TimeoutSec `
    -Headers @{ Authorization = "Bearer $apiKey" } `
    -ContentType "application/json; charset=utf-8" `
    -Body $bytes
}
catch {
  # Tentar extrair a mensagem de erro da API sem vazar a chave.
  $msg = $_.Exception.Message
  try {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object IO.StreamReader($stream)
    $errBody = $reader.ReadToEnd()
    if ($errBody) { $msg = "$msg | $errBody" }
  } catch {}
  [Console]::Error.WriteLine("ERRO: falha na API de imagem: $msg")
  exit 3
}

$b64 = $resp.data[0].b64_json
if (-not $b64) {
  [Console]::Error.WriteLine("ERRO: resposta sem b64_json (formato inesperado).")
  exit 4
}

[IO.File]::WriteAllBytes($absOut, [Convert]::FromBase64String($b64))
Write-Output "OK: $absOut"
