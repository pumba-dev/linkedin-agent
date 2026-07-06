# git-sync.ps1 — persiste o ESTADO no GitHub após um fluxo de skill terminar.
#
# Uso (no fim de cada skill, depois da limpeza de temporários):
#   pwsh -File mcp/git-sync.ps1 -Message "empresa: 3 posts interagidos (curtir+comentar+share)"
#
# O QUE versiona: estado persistente (data/) + entregáveis (posts_gerados/,
# posts_agendados/). NÃO versiona edições de skill/config nem .env (essas o
# usuário commita à mão; o .env está no .gitignore). Repo privado
# pumba-dev/linkedin-agent.

param(
  [Parameter(Mandatory = $true)][string]$Message
)

$repo = "C:\Users\eduar\github\linkedin-indecx-engajamento"
Set-Location $repo

# Só estado + entregáveis. Edições de skill/config ficam de fora de propósito.
$paths = @("data", "posts_gerados", "posts_agendados") | Where-Object { Test-Path $_ }
if ($paths.Count -eq 0) { Write-Host "git-sync: nada a versionar."; exit 0 }

git add -- $paths

# Sem mudanças staged? (git diff --cached --quiet: exit 0 = nada, exit 1 = há diff)
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Host "git-sync: sem mudanças no estado."; exit 0 }

git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-Error "git-sync: commit falhou."; exit 1 }

git push
if ($LASTEXITCODE -ne 0) {
  Write-Error "git-sync: push falhou (mudanças commitadas localmente; rode 'git push' depois)."
  exit 1
}

Write-Host "git-sync: OK -> $Message"
