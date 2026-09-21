# LinkedIn Agent

Agente de engajamento no LinkedIn operado pelo [Claude Code](https://claude.com/claude-code).
O agente dirige **o seu próprio Chrome** por um MCP de browser (Playwright via CDP),
reaproveitando a sessão já logada, e executa três fluxos: publicar no perfil pessoal,
interagir com a página de uma empresa e interagir com a timeline.

Não há bot rodando em servidor, nem API não-oficial do LinkedIn, nem credencial
armazenada: tudo acontece no navegador da sua máquina, sob comando manual, com os
textos passando por um gate de qualidade e (nos fluxos sensíveis) por aprovação
explícita antes de ir ao ar.

> Este repositório é a configuração de um agente, não uma aplicação. O "código" são
> arquivos Markdown (skills do Claude Code) mais alguns scripts PowerShell de apoio.

---

## Como funciona

```
você ──▶ Claude Code ──▶ .claude/CLAUDE.md (roteador)
                              │
                              ├─▶ skill linkedin-post-pessoal
                              ├─▶ skill linkedin-empresa
                              └─▶ skill linkedin-timeline
                                        │
                                        ▼
                              MCP chrome (Playwright)
                                        │  CDP :9222
                                        ▼
                              Chrome com perfil dedicado ──▶ linkedin.com
```

1. Você pede algo em linguagem natural ("cria um post sobre X", "curte e comenta os
   posts novos da empresa").
2. O `.claude/CLAUDE.md` funciona como orquestrador e escolhe **uma** das três skills.
   Em caso de ambiguidade, o agente pergunta antes de agir.
3. A skill segue seu passo a passo, lê a página pelo MCP de browser, gera os textos
   seguindo as regras de escrita compartilhadas e interage.
4. Ao final, o estado vai para `data/` e é sincronizado com o Git.

## As três skills

| Skill | O que faz | Frases que disparam |
|-------|-----------|---------------------|
| `linkedin-post-pessoal` | Cria e publica posts autorais no **perfil pessoal**: texto, hashtags e imagem gerada por IA. Meta de ≥ 3 posts/semana. Sempre rascunho → aprovação. | "cria um post sobre X", "gera os posts da semana", "tenho uma imagem agendada" |
| `linkedin-empresa` | Percorre os posts novos da **página de uma empresa** e executa três interações por post: curtir, comentar e compartilhar. | "interage com os posts da empresa", "processa os posts novos da página" |
| `linkedin-timeline` | Varre a **timeline (feed)**, captura ≥ 20 posts, seleciona os melhores e interage (curtir automático, comentar mediante aprovação). Prioriza uma lista de stakeholders. | "passa no feed e curte os melhores", "interage com a timeline" |

O contexto comum às três — persona e voz, regras de escrita, paleta da marca,
geração de imagem, tools do browser, formato de data/hora e persistência no Git —
fica em [`.claude/skills/_shared/contexto-compartilhado.md`](.claude/skills/_shared/contexto-compartilhado.md).
As skills referenciam esse arquivo em vez de repetir as regras.

## Pré-requisitos

- **Windows** com PowerShell 5.1 (os scripts são `.ps1`; não foi testado em outro SO).
- **Google Chrome** instalado.
- **Claude Code** instalado e autenticado.
- **Node.js** (o MCP roda via `npx @playwright/mcp`).
- **Conta no LinkedIn** (login manual, feito uma vez no perfil dedicado).
- *(Opcional)* **Chave de API da OpenAI**, apenas para a geração de imagem dos posts
  pessoais (`gpt-image-2`). Sem ela, o fluxo de imagem não roda.

## Setup

```powershell
git clone https://github.com/pumba-dev/linkedin-agent.git
cd linkedin-agent
```

**1. Credenciais (opcional, só para imagem por IA)**

```powershell
Copy-Item .env.example .env
# edite .env e preencha OPENAI_API_KEY
```

O `.env` está no `.gitignore` e nunca é commitado.

**2. Abrir o Chrome de debug**

```powershell
./mcp/launch-chrome-debug.ps1
```

Abre um Chrome em perfil dedicado (`%LOCALAPPDATA%\chrome-indecx-agent`), com
`--remote-debugging-port=9222`, sem tocar no seu Chrome do dia a dia. **Na primeira
vez, faça login no LinkedIn nesse perfil** — a sessão fica salva. O agente nunca
tenta logar sozinho: se cair na tela de login ou em captcha, ele para e registra no log.

**3. Abrir o Claude Code na pasta do projeto**

O `.mcp.json` da raiz registra o servidor `chrome` apontando para `127.0.0.1:9222`.
Na primeira execução o Claude Code pede aprovação do MCP server. Confira com:

```
/mcp
```

Deve listar `chrome` como conectado, expondo `browser_navigate`, `browser_snapshot`,
`browser_click`, `browser_type`, `browser_evaluate`, entre outras.

**4. Pedir a ação**

Em linguagem natural, no chat do Claude Code. Detalhes em [`mcp/RUN-AGENT.md`](mcp/RUN-AGENT.md).

## Estrutura de pastas

| Caminho | Conteúdo |
|---------|----------|
| `.claude/CLAUDE.md` | orquestrador: roteia o pedido para a skill certa |
| `.claude/skills/` | as três skills + `_shared/` (contexto comum) |
| `.mcp.json` | config do MCP de browser (fica na raiz; o Claude Code só descobre lá) |
| `mcp/` | `launch-chrome-debug.ps1`, `git-sync.ps1`, `RUN-AGENT.md` |
| `assets/` | `gerar-imagem-openai.ps1` (geração de imagem por IA) |
| `data/` | estado persistente — nunca apagar |
| `posts_agendados/<slug>/` | posts agendados por você (imagem + `contexto.md`) |
| `posts_gerados/<slug>/` | entregáveis do agente (`post.md`, `imagem.png`) |

### Estado persistente (`data/`)

| Arquivo | Para quê |
|---------|----------|
| `posts_processados.json` | `activityId`s já interagidos na página da empresa (anti-duplicação) |
| `posts_data.json` | dados e textos gerados por post da empresa |
| `posts_publicados.json` | posts publicados no perfil (conta a meta semanal) |
| `stakeholders.json` | lista de perfis prioritários da timeline |
| `stakeholders_processados.json` | anti-duplicação da timeline |
| `log.txt` | histórico de execuções, compartilhado pelas três skills |

Timestamps sempre em ISO 8601 com offset, fuso `America/Sao_Paulo`.

## Posts agendados

Para pedir um post a partir de material seu, crie `posts_agendados/<slug>/` com a
imagem e um `contexto.md` baseado em
[`posts_agendados/TEMPLATE-contexto.md`](posts_agendados/TEMPLATE-contexto.md)
(mensagem/intenção, tom, hashtags desejadas, observações). O agente escreve o texto
e completa o que faltar. Agendado tem prioridade máxima, mesmo com a meta semanal
já cumprida. Depois de publicado, a pasta vai para `posts_agendados/publicados/`.

## Guard-rails

Regras que valem para todos os fluxos:

- **Publicação pessoal é sempre rascunho → aprovação.** O agente nunca publica no seu
  perfil sem um OK explícito. Comentário na timeline também passa por aprovação.
- **Gate de qualidade antes de qualquer texto ir ao ar:** português 100% correto e
  autoavaliação aprovada, com regras de escrita explícitas (comentário curto, sem
  clichê de IA, enquadramento positivo, sem expor stack ou assunto interno).
- **Limites anti-bot na timeline:** até 8 curtidas e 3 comentários por execução, no
  máximo 5 comentários por dia, 1 post por autor por execução, janela de 7 dias.
- **Sem login automático.** Tela de login, captcha ou verificação de segurança →
  o agente para e registra no log.
- **Estado é sagrado.** Os arquivos de `data/` são persistentes e nunca são apagados;
  a limpeza de fim de execução só remove artefatos temporários do browser.
- **Persistência no Git como último passo de todo fluxo:** `mcp/git-sync.ps1` faz
  `add` apenas de `data/`, `posts_gerados/` e `posts_agendados/`, commita e dá push.
  Edições de skill e de config você commita à mão; o `.env` nunca vai.

## Adaptando para o seu caso

Este repositório está configurado para uma pessoa e uma empresa específicas. Para
reaproveitar, ajuste:

1. **Persona e voz** — seção 1 de `.claude/skills/_shared/contexto-compartilhado.md`
   (cargo, formação, domínio, tom, o que não pode virar post).
2. **Paleta e estética das imagens** — seção 3 do mesmo arquivo.
3. **Empresa** — `.claude/skills/linkedin-empresa/SKILL.md`: URL da página, contexto
   de eventos internos e a regra de não nomear a empresa.
4. **Stakeholders** — `data/stakeholders.json` (handles `/in/<handle>` e prioridade).
5. **Caminhos absolutos** — `mcp/git-sync.ps1` e a seção 5 do contexto compartilhado
   apontam para `C:\Users\eduar\github\linkedin-indecx-engajamento`. Troque pelo seu.
6. **Remote do Git** — o `origin` aponta para este repositório; aponte para o seu.

Comece zerando o estado: `data/*.json` com `[]` ou `{}` conforme a sintaxe descrita
em cada skill, e `data/log.txt` vazio.

## Avisos

- **Automatizar interações no LinkedIn pode conflitar com os Termos de Uso da
  plataforma.** O projeto opera de forma deliberadamente conservadora (disparo manual,
  volume baixo, ritmo humano, nada de scraping em massa), mas o risco sobre a conta é
  de quem usa.
- Todo texto publicado sai com o seu nome. Revise os rascunhos — o gate de qualidade
  reduz o erro, não o elimina.
- O conteúdo de `data/` e `posts_gerados/` é versionado neste repositório. Se ele for
  público, o histórico de interações e a lista de stakeholders ficam públicos também.
