# Como rodar pelo Claude Code (via MCP de browser)

Um MCP dirige o **seu próprio Chrome** via CDP (Chrome DevTools Protocol),
reaproveitando a sessão já logada no LinkedIn. O Claude Code escolhe a skill certa
(ver `.claude/CLAUDE.md`) e executa o fluxo.

## 1. Abrir o Chrome com porta de debug

```powershell
./mcp/launch-chrome-debug.ps1
```

- Abre um Chrome em **perfil dedicado** (`%LOCALAPPDATA%\chrome-indecx-agent`),
  sem mexer no seu Chrome normal.
- **Só na 1ª vez:** navegue até o LinkedIn e faça login. Fica salvo no perfil.
- Pode manter esse Chrome aberto entre execuções.

## 2. Iniciar o Claude Code nesta pasta

O `.mcp.json` (raiz) registra o servidor `chrome` (Playwright MCP) apontando para
`127.0.0.1:9222`. Na primeira vez o Claude Code pede para aprovar o MCP server —
aprove.

Conferir conexão:
```
/mcp
```
Deve listar `chrome` como conectado e expor tools `browser_navigate`,
`browser_snapshot`, `browser_click`, `browser_type`, etc.

## 3. Pedir a ação

Peça em linguagem natural; o `CLAUDE.md` roteia para a skill certa:

- **Perfil pessoal:** "cria um post sobre X", "gera os posts da semana" →
  skill `linkedin-post-pessoal`.
- **Página da empresa:** "curte e comenta os posts novos da empresa" →
  skill `linkedin-empresa`.
- **Timeline de stakeholders:** "interage com os posts dos stakeholders" →
  skill `linkedin-timeline`.

Cada skill segue seu spec e atualiza o estado em `data/` (`posts_processados.json`,
`posts_data.json`, `posts_publicados.json`, `stakeholders.json`) e o `data/log.txt`.

## Notas

- **Só conecta em Chrome aberto com `--remote-debugging-port`.** Não dá para anexar
  a um Chrome normal já rodando — use sempre o launcher.
- Tools do Playwright MCP: `browser_navigate`, `browser_snapshot` (lê a página),
  `browser_click`, `browser_type`, `browser_tabs`, `browser_file_upload`,
  `browser_evaluate`, `browser_take_screenshot`, `browser_wait_for`.
- Alternativa ao Playwright MCP: `chrome-devtools-mcp` (Google). Trocar o
  `command/args` no `.mcp.json` (raiz) se preferir.
