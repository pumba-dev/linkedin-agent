# Orquestrador — Engajamento no LinkedIn

Este repositório automatiza engajamento no LinkedIn dirigindo o Chrome do usuário
por um MCP de browser (Playwright via CDP). O trabalho é dividido em **três skills
por função**. Este arquivo orquestra: identifica o fluxo certo, garante os
pré-requisitos e delega para a skill correspondente, que tem o passo a passo.

## As três skills (roteamento)

Ao receber um pedido de engajamento no LinkedIn, escolha UMA skill. Na dúvida
entre duas, pergunte em uma linha antes de agir (publicar/interagir é difícil de
desfazer).

| Skill | Quando usar | Sinais |
|-------|-------------|--------|
| **linkedin-post-pessoal** | Criar/postar/agendar publicação no **perfil pessoal** do usuário; gerar texto, hashtags ou card; cumprir a meta semanal | "cria um post", "posta algo que engaje", "card azul pro linkedin", "gera os posts da semana", "tenho uma imagem agendada" |
| **linkedin-empresa** | Curtir, comentar e compartilhar nos posts da **página da empresa (INDECX)** | "interage com a empresa", "curte e comenta os posts da indecx", "processa os posts novos da página" |
| **linkedin-timeline** | Varrer a **timeline (feed)**, capturar ≥50 posts e interagir (curtir/comentar) com os melhores p/ engajar | "interage com a timeline", "passa no feed e curte os melhores", "engaja com a galera do feed", "comenta nos posts importantes do feed" |

As skills disparam sozinhas pela descrição. Se nenhuma cobrir o pedido ou o
contexto estiver ambíguo, pergunte: "É post no seu perfil, interação na página da
empresa, ou na timeline de stakeholders?"

## Contexto compartilhado

Persona, voz, regras de escrita, paleta da marca, render do card, tools e setup do
browser MCP, estado persistente e formato de data/hora são comuns às três skills e
ficam em [`.claude/skills/_shared/contexto-compartilhado.md`](skills/_shared/contexto-compartilhado.md).
Ler antes de gerar qualquer texto ou imagem, em qualquer fluxo. As skills referem
esse arquivo em vez de repetir as regras.

## Pré-requisitos do browser (todas as skills)

1. Chrome de debug aberto: `mcp/launch-chrome-debug.ps1` (perfil dedicado, porta
   9222). Sem ele, o MCP não conecta.
2. MCP `chrome` conectado (config em `.mcp.json`, na raiz; o Claude Code descobre
   sozinho). Como rodar: `mcp/RUN-AGENT.md`.
3. Confirmar login no LinkedIn via `browser_snapshot`. Tela de login → parar e
   registrar no log; não tentar logar sozinho. Captcha/verificação → parar.

## Estrutura de pastas

| Caminho | Conteúdo |
|---------|----------|
| `.claude/skills/` | as três skills + `_shared/` (contexto comum) |
| `.mcp.json` | config do MCP (raiz, não mover) |
| `mcp/` | `launch-chrome-debug.ps1`, `RUN-AGENT.md`, `git-sync.ps1` |
| `data/` | estado persistente: `posts_processados.json`, `posts_data.json`, `posts_publicados.json`, `stakeholders.json`, `log.txt` (nunca apagar) |
| `posts_agendados/<slug>/` | posts agendados pelo usuário (imagem + `contexto.md`) |
| `posts_gerados/<slug>/` | drafts gerados (texto, card, imagem) |
| `assets/gerar-imagem-openai.ps1` | gerador de imagem por IA (gpt-image-2) |

## Princípios (valem para todas as skills)

- **Nunca publicar/interagir sem o gate de qualidade da skill.** Texto só vai ao ar
  com português 100% correto e autoavaliação aprovada.
- **Postagem pessoal é rascunho → aprovação:** nunca publicar sem o OK do usuário.
- **Ação no LinkedIn é difícil de desfazer:** na dúvida sobre o fluxo ou o
  conteúdo, perguntar antes.
- **Estado é sagrado:** os arquivos em `data/` são persistentes; nunca apagar.
- **Persistir no Git ao fim de todo fluxo:** como último passo, sincronizar estado
  (`data/`) e entregáveis (`posts_gerados/`, `posts_agendados/`) com o repositório
  privado `pumba-dev/linkedin-agent` via `mcp/git-sync.ps1` (seção 7 do contexto
  compartilhado). Edições de skill/config o usuário commita à mão; o `.env` nunca vai.
