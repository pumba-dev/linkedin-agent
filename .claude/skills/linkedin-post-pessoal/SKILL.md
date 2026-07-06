---
name: linkedin-post-pessoal
description: >-
  Cria e publica posts autorais no PERFIL PESSOAL do LinkedIn do usuário (NÃO na
  página da empresa, NÃO na timeline de terceiros). Dispare quando o usuário
  disser coisas como "cria um post sobre X", "posta algo que engaje", "preciso
  de um card azul pro LinkedIn", "gera os posts da semana", "tenho uma imagem
  agendada", "faz um post de trending", "escreve um post pra comunidade tech",
  "to precisando bater a meta de posts" ou "monta um rascunho pro meu LinkedIn".
  Trabalha em modo rascunho → aprovação (NUNCA publica sem o OK do usuário),
  é disparada manualmente, gera o texto + hashtags + imagem (card de conceito
  ou cena fotorrealista por IA), apresenta o rascunho e só publica via browser depois da
  aprovação. Meta de no mínimo 3 posts por semana.
---

# LinkedIn — Post no perfil pessoal

Cria postagens originais no **perfil pessoal** do usuário para gerar engajamento,
garantindo **no mínimo 3 publicações por semana**. Trabalha em **modo rascunho →
aprovação** (NUNCA publica sem o OK) e é **disparado manualmente**.

Leia primeiro o **[contexto compartilhado](../_shared/contexto-compartilhado.md)** —
persona e voz, carreira não-pública, anti-vazamento de stack, regras de escrita
comuns (incl. score e gate gramatical), paleta da marca + render do card, browser
MCP (tools e setup), estado em `data/` e formato de data/hora/log. Aqui fica só o
que é específico do fluxo de post pessoal.

Para o outro fluxo (comentar/compartilhar na página da empresa), use a skill
`linkedin-empresa`. Para interagir com posts de terceiros, use `linkedin-timeline`.

## O que é específico desta skill

Conteúdo **autoral e mais opinativo** (marca própria) — pode ter posição própria,
mais pessoal e direto que o da página da empresa. Emoji mais livre que nas outras
skills (mesmo limite: 1-2, ~40% sem nenhum). Estilo: experiente, curioso, direto,
sem autoelogio.

### Pilares de conteúdo

Todo post cai em **pelo menos um** pilar; **rotacionar** ao longo da semana (não
repetir o mesmo pilar em posts consecutivos):

1. **Full-stack / arquitetura / Tech Lead** — decisões técnicas, trade-offs,
   qualidade de código, priorização, liderança técnica.
2. **IA & dados** — tendências de IA, NLP, análise de sentimento, leitura de
   dados/feedback em escala, aplicação responsável e concreta.
3. **CX / SaaS B2B** — experiência e voz do cliente, produto SaaS B2B, como o dado
   vira ação (sempre em nível de conceito, sem vazar stack).
4. **Atualidades & trending tech** — assuntos quentes do momento, conectados a uma
   leitura técnica ou de mercado própria.

### Fontes do post (ordem de prioridade)

1. **Agendado** — o usuário coloca imagem + contexto numa subpasta de
   `posts_agendados/`. O agente gera texto, hashtags e o que faltar. **Prioridade
   máxima**, mesmo que a meta semanal já esteja cumprida.
2. **Trending** — o agente busca na internet os assuntos quentes/relevantes (tech
   e atualidade) que combinam com a persona e propõe um post com tese própria.
3. **Comunidade (fallback)** — sem agendado e meta não cumprida: post autoral de
   engajamento na comunidade tech.

**Meta: ≥ 3 posts/semana** (segunda a domingo, `America/Sao_Paulo`).

### Estrutura de um post de LinkedIn

Diferente de comentário (que é curto): corpo desenvolvido e formato escaneável.

- **Gancho na 1ª linha** — aparece antes do "ver mais". Prende: afirmação forte,
  pergunta ou dado. Nunca "Hoje quero falar sobre...".
- **Corpo escaneável** — linhas e parágrafos curtos, com quebras de linha. Sem
  blocão.
- **Uma ideia central** — desenvolver um ponto com profundidade, não vários rasos.
- **Fechamento com CTA/pergunta** — reflexão ou pergunta curta que convide ao
  comentário.
- **Comprimento-alvo:** geralmente **100 a 250 palavras**. Em dúvida, mais curto
  e direto engaja mais.

### Hashtags

- **3 a 5**, no fim do post. Nunca o padrão spam de 20-30.
- Misturar **amplas** (ex.: `#tecnologia`, `#engenhariadesoftware`) com
  **específicas/nicho** (ex.: `#techlead`, `#analisedesentimento`).
- Em português por padrão (público BR), salvo tema global com tag em inglês usual.
- Coerentes com o conteúdo; nada de tag descolada só por alcance.
- Respeitar hashtags forçadas no `contexto.md`, se houver.

### Imagem do post (estratégia)

Post sem imagem engaja pouco. **Toda postagem sai com imagem.** O Analista escolhe
o **tipo** (ver "Papéis"):

- **Post agendado:** usa a imagem que o usuário colocou em
  `posts_agendados/<slug>/`. Não gerar nada.
- **Conceito / tese / opinião abstrata → card de conceito** gerado em código
  (a maioria dos posts de trending/comunidade).
- **Cena / situação concreta → foto realista** gerada por IA (`gpt-image-2`,
  OpenAI). Ex.: alguém revisando arquitetura, time em code review, mesa de
  trabalho, bastidor de evento. Regras de prompt anti "cara de IA", comando e gate
  no **[contexto compartilhado, seção 3](../_shared/contexto-compartilhado.md)**.
- **Rotacionar** card e cena ao longo da semana (não virar sempre foto); alvo
  **~40-50%** dos posts com cena, o resto card.
- **Nunca** usar imagem aleatória da web (copyright).

A imagem final vai para `posts_gerados/<slug>/imagem.png` (posts gerados) ou fica
na própria `posts_agendados/<slug>/` (agendados); o caminho e os metadados da
geração são gravados em `data/posts_publicados.json`.

**Card de conceito:** criar `posts_gerados/<slug>/`, copiar
`assets/card-template.html` substituindo `{{HOOK}}` (1ª linha do post, curta — não
o post inteiro), `{{ACCENT}}` (2ª parte do gancho em destaque, pode ficar vazia) e
`{{FOOT}}` (assinatura, ex.: `Paulo Araujo · Engenharia de Software`); salvar como
`posts_gerados/<slug>/card.html` e renderizar para PNG 1200x1200 com o comando do
**[contexto compartilhado, seção 3](../_shared/contexto-compartilhado.md)**.
Conferir o PNG; se o texto estourar, encurtar o gancho ou baixar o `font-size` e
renderizar de novo. A paleta (azul, não verde) já está no template.

**Cena fotorrealista (`gpt-image-2`):** requer `OPENAI_API_KEY` no `.env` da raiz
(billing de API, não a assinatura do ChatGPT). Montar o prompt seguindo as
**regras anti "cara de IA"** e rodar `assets/gerar-imagem-openai.ps1` (defaults
1200x1200, `medium`) — passo a passo na
**[seção 3 do contexto compartilhado](../_shared/contexto-compartilhado.md)**.
Passar pelo **gate da imagem** (checar uncanny; regenerar até 2x). **Sem key ou
erro de API → fallback para o card.**

_Alternativa opcional (não default): foto de banco livre (Unsplash/Pexels) se
houver `UNSPLASH_ACCESS_KEY`/`PEXELS_API_KEY`, para cena real sem IA._

### Papéis: Analista → Redator

Separação de papéis para evitar texto raso.

**Analista** (produz internamente): pilar escolhido (checar ≠ do post anterior);
assunto e ângulo próprio (a tese); público-alvo (pares de tech, lideranças,
stakeholders, recrutadores); gancho candidato; estrutura do corpo (ideia, exemplo /
leitura de mercado, fecho); CTA de fechamento; sentimento (normal ou
sensível/triste); comprimento-alvo; **tipo de imagem** (card de conceito ou cena
fotorrealista — mirar ~40-50% cena na semana; se card, definir o texto do gancho;
se cena, definir o prompt em inglês com o enquadramento e as regras anti "cara de
IA" da seção 3 do contexto compartilhado).

**Redator** (recebe só a análise): escreve o **corpo** seguindo "Estrutura de um
post"; gera as **hashtags** (3-5); roda o **score** e reescreve se reprovar; passa
pelo **gate gramatical** (ver contexto compartilhado, seção 2). Em contexto
sensível/triste, manter sobriedade e não usar CTA que soe oportunista.

## Passos

### 1. Carregar histórico

Ler `data/posts_publicados.json` (se não existir, `[]`) e `data/log.txt`. Contar
quantos posts já saíram **na semana corrente** (segunda a domingo,
`America/Sao_Paulo`) → `postsNaSemana`. Usar o histórico para evitar repetir pilar,
abertura, fechamento, emoji e léxico.

### 2. Escolher a fonte

Decidir nesta ordem:

1. **Há agendado?** Listar subpastas de `posts_agendados/` (ignorando
   `publicados/`). Se houver ≥ 1 → fonte = **agendado** (processar a mais antiga
   primeiro, ou todas se o usuário pedir). Agendado tem prioridade mesmo com a meta
   cumprida.
2. **Sem agendado e `postsNaSemana < 3`?** → escolher entre **trending** (preferir
   quando houver tema quente e relevante para os pilares) e **comunidade** (quando
   não houver tema trending bom o bastante).
3. **Sem agendado e `postsNaSemana >= 3`?** → avisar que a meta da semana foi
   cumprida e perguntar se quer um post extra (trending/comunidade) ou parar.

Se o usuário pedir uma fonte explícita (ex.: "faça um post de trending"), respeitar.

### 3. Gerar o conteúdo

Aplicar Analista → Redator. Por fonte:

- **Agendado** — ler o `contexto.md` da subpasta (template abaixo) e, se houver
  imagem, inspecioná-la para entender o visual. Construir a análise a partir da
  intenção descrita e do que a imagem mostra. Respeitar tom, hashtags e observações
  do `contexto.md`. Pode haver imagem sem contexto (inferir do visual) ou contexto
  sem imagem (post só de texto).
- **Trending** — usar `WebSearch` (e `WebFetch` p/ detalhe de fonte) p/ levantar os
  assuntos quentes em tech/atualidade. Filtrar os que combinam com os pilares e a
  persona. Escolher 1 tema e formar **tese própria** (não resumir a notícia:
  comentar com leitura técnica/de mercado). Citar a tendência em nível de conceito.
- **Comunidade** — escolher um pilar pouco usado recentemente e gerar post autoral
  de opinião/experiência que convide a comunidade a comentar (trade-off de
  arquitetura, lição de carreira rumo a Tech Lead, leitura sobre IA aplicada).

#### Template do `contexto.md` (posts agendados)

O usuário agenda criando `posts_agendados/<slug-do-post>/` com a imagem
(`imagem.png|jpg|jpeg|webp`, opcional) e um `contexto.md`:

```markdown
# Contexto da postagem

## Imagem

(o que a imagem mostra; deixe em branco se não houver imagem)

## Mensagem / intenção

(o que você quer comunicar com este post — o ponto principal)

## Tom (opcional)

(ex.: reflexivo, técnico, descontraído, comemorativo)

## Hashtags desejadas (opcional)

(se quiser forçar alguma; senão o agente escolhe)

## Observações (opcional)

(CTA específico, mencionar um evento, evitar tal palavra, etc.)
```

Cada subpasta direta de `posts_agendados/` (exceto `publicados/`) é um post
pendente; fica pendente até ser movida para `posts_agendados/publicados/` (passo 6).

### 4. Apresentar o rascunho e aguardar aprovação

**Antes de apresentar, gerar a imagem** conforme o tipo escolhido pelo Analista:
**card de conceito** (render local) ou **cena fotorrealista** (`gpt-image-2` via
`assets/gerar-imagem-openai.ps1`, com o gate anti "cara de IA"; erro/sem key →
fallback para o card). Salvar em `posts_gerados/<slug>/imagem.png`.

**Não publicar ainda.** Mostrar ao usuário, claramente:

- **Fonte/tipo** e **pilar**
- **Imagem** gerada (caminho + o próprio card/foto p/ ver)
- **Texto completo** do post (como vai aparecer, com as quebras de linha)
- **Hashtags**
- (se trending) a **referência** do tema e por que é relevante agora

Então perguntar: **publicar, ajustar ou descartar?**

- **Ajustar** → aplicar o pedido (reescrever, mudar tom, encurtar, trocar
  hashtags...) e mostrar de novo. Repetir até aprovar.
- **Descartar** → não publicar; registrar no log que o rascunho foi descartado e
  parar (ou ir para o próximo, se havia vários).
- **Publicar** → seguir para o passo 5.

Se o usuário pediu vários posts, gerar e apresentar cada um, aprovando
individualmente.

### 5. Publicar no LinkedIn (após aprovação)

Navegar para o feed: `https://www.linkedin.com/feed/`. Tirar `browser_snapshot`
para confirmar login. Se cair em tela de login, parar e registrar no log: "Erro:
usuário não está logado no LinkedIn." (não tentar logar sozinho).

Fluxo (usar sempre `browser_snapshot` para achar o `ref` antes de cada clique — a
UI muda):

1. Clicar no botão de iniciar publicação no topo do feed ("**Começar
   publicação**" / "**Iniciar publicação**"). Abre o modal.
2. **Se houver imagem:** clicar em adicionar mídia/foto ("**Adicionar uma foto**"
   ou ícone de mídia); enviar com `browser_file_upload` apontando para o caminho
   absoluto da imagem; aguardar o preview; se houver "Avançar"/"Concluído" no
   editor de imagem, confirmar.
3. Clicar na área de texto e digitar **texto completo + hashtags** com
   `browser_type` (manter as quebras de linha).
4. Conferir no `browser_snapshot` que texto e imagem entraram.
5. Clicar em "**Publicar**".
6. Aguardar (`browser_wait_for`) a confirmação (modal fecha / aparece no feed).
   Capturar o `permalink` se possível; senão, `null`.

Se qualquer passo falhar (botão não encontrado, captcha, verificação), parar,
registrar no log com o erro e **não** marcar como publicado.

### 6. Atualizar arquivos

Após publicação confirmada:

- **`data/posts_publicados.json`** — adicionar o objeto do post (sintaxe abaixo),
  com `status: "publicado"`, `publicadoEm` no horário ISO 8601 atual e `permalink`
  se capturado. Salvar.
- **Post agendado** — mover a subpasta de `posts_agendados/<slug>` para
  `posts_agendados/publicados/<slug>`.
- **`data/log.txt`** — append (passo 7).

Se a ação falhou: salvar mesmo assim o texto gerado em
`data/posts_publicados.json` com `status: "erro"` e registrar o erro no log (não
mover a pasta agendada, para permitir nova tentativa).

#### Sintaxe — `data/posts_publicados.json`

Array de objetos, um por post publicado. **Nunca apagar.**

```json
[
  {
    "id": "slug-do-post-ou-timestamp",
    "tipo": "agendado | trending | comunidade",
    "fonte": "posts_agendados/<slug> | <tema trending> | <pilar>",
    "pilar": "full-stack | ia-dados | cx-saas | atualidades",
    "texto": "texto completo publicado",
    "hashtags": ["#exemplo", "#outra"],
    "imagem": "posts_gerados/<slug>/imagem.png ou posts_agendados/<slug>/imagem.png ou null",
    "imagemTipo": "card | cena | agendada",
    "imagemModelo": "gpt-image-2 (só cena) ou null",
    "imagemPrompt": "prompt usado na cena, ou null",
    "permalink": "url do post publicado ou null",
    "publicadoEm": "2026-06-26T09:30:00-03:00",
    "status": "publicado | erro"
  }
]
```

### 7. Registrar execução no log

Append em `data/log.txt`. `[DATA/HORA]` em ISO 8601 com offset,
`America/Sao_Paulo`:

```
[DATA/HORA] Postagem pessoal | Fonte: [agendado/trending/comunidade] | Pilar: [pilar] | Posts na semana: [N/3]

* Status: [publicado / descartado / erro]
* Imagem: [caminho / nenhuma] ([card / cena / agendada])
* Texto:
"[texto completo do post]"
* Hashtags: [#... #...]
* Permalink: [url / null]

#############################################################
```

Se não houver nada a postar (sem agendado, meta cumprida e usuário não quis extra):
`[DATA/HORA] Nada a postar (meta semanal cumprida).`

### 8. Limpar temporários do browser

Apagar os artefatos temporários gerados na execução (`.playwright-mcp/`,
`*-snap.yml`, `page-*.yml`, screenshots de checagem na raiz). Detalhes e o que
**nunca** apagar (estado em `data/`, entregáveis em `posts_gerados/`) na seção 4
do **[contexto compartilhado](../_shared/contexto-compartilhado.md)**.

### 9. Persistir no Git

Só depois da publicação aprovada e do estado atualizado. Sincronizar com o
repositório privado (seção 7 do
**[contexto compartilhado](../_shared/contexto-compartilhado.md)**):

```powershell
pwsh -File mcp/git-sync.ps1 -Message 'pessoal: post "<slug>" publicado'
```

## Lembretes

- **Nunca publica sem aprovação** do usuário (rascunho). Aprovação por post.
- `data/posts_publicados.json` e `data/log.txt` são persistentes — nunca apagar.
- Limpar os temporários do browser ao final (passo 8); nunca apagar `data/` nem
  `posts_gerados/`.
- Captcha/verificação de segurança → parar e registrar.
- Salvar o texto gerado mesmo quando a publicação falhar.
- Trending: comentar com leitura própria, nunca só resumir a notícia.
- Pouca informação (imagem sem contexto, tema vago) → leitura ampla e segura, sem
  inventar detalhes.
- Rotacionar pilar, estilo, abertura e emoji em relação aos últimos posts.
