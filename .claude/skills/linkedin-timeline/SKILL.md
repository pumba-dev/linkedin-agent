---
name: linkedin-timeline
description: >-
  Varre a TIMELINE (feed) do LinkedIn, captura pelo menos 20 posts rolando até o
  fim e escolhe os MELHORES para interagir (curtir + comentar), gerando
  engajamento e construindo a imagem do usuário na rede. Prioriza stakeholders da
  lista (influenciadores tech e C-levels), mas também considera bons posts do feed
  relevantes à área do usuário. Use quando o usuário disser "interage com a
  timeline", "passa no feed e curte os melhores posts", "engaja com a galera do
  feed", "comenta nos posts importantes da timeline", "dá uma olhada no feed e
  interage". NÃO é para o perfil pessoal do usuário (use linkedin-post-pessoal) nem
  para a página da empresa (use linkedin-empresa): esta cuida da TIMELINE / feed.
---

# linkedin-timeline — interação com a timeline (feed)

Varrer o **feed do LinkedIn**, capturar um lote de posts e interagir com os
**melhores** para gerar engajamento e construir a imagem profissional do usuário na
rede. Conteúdo é **de terceiros**: agregar valor, nunca capturar o crédito.

> Aplica todo o **[contexto compartilhado](../_shared/contexto-compartilhado.md)**:
> persona e voz, regras de escrita (sem travessão, emoji com parcimônia, anti-stack,
> carreira não-pública, score, gate gramatical), browser MCP (tools + setup),
> estrutura de pastas, data/hora e log. **Não duplicar** essas regras aqui.

## Parâmetros (definidos)

- **Fonte única: a timeline (feed).** Rolar `https://www.linkedin.com/feed/` e
  capturar **pelo menos 20 posts**. **Não** abrir o perfil de cada stakeholder, nem
  fazer busca de conteúdo: tudo vem do que aparece no feed.
- **Interações:** curtir **e** comentar. Nunca compartilhar conteúdo de terceiros.
- **Aprovação:** **curtida é automática** (baixo risco, dentro dos limites).
  **Todo comentário passa por rascunho → aprovação** antes de publicar.
- **Disparo:** manual.

## Objetivo da seleção

Dos ~20 posts capturados, escolher os que mais constroem a presença do usuário.
Ordem de prioridade:

1. **Stakeholders da lista** (`data/stakeholders.json`) — influenciadores tech e
   C-levels da empresa. Casar pelo `/in/<handle>` do autor (mais confiável que
   nome). Prioridade `alta` na frente de `média`.
2. **Empresa-relacionada** (classificação dinâmica) — post de uma **empresa fora do
   ramo de CX** que marca/menciona a INDECX e apareceu **no próprio feed**. Tratar
   com cuidado extra (ver "Cuidados"). Não fazer busca dedicada: só vale se cair no
   feed.
3. **Bons posts do feed relevantes à área** — mesmo de autores fora da lista, quando
   o tema é forte para a marca do usuário (engenharia, liderança técnica, produto,
   IA, dados, experiência do cliente em nível de conceito) e um comentário
   substantivo ganha visibilidade. Evitar post promovido/ruído/fora de tema.

Critérios de "melhor post" dentro de cada grupo: recência (janela de 7 dias),
relevância para a persona, potencial de engajamento (autor relevante, thread ativa),
e espaço para agregar algo real. Post sensível (luto, crise, despedida) → no máximo
curtir, ou comentário breve e sóbrio (ver regras de escrita).

## Fontes de dados (específico desta skill)

### Lista de stakeholders — `data/stakeholders.json`

Mantida pelo usuário. Serve para **identificar e priorizar** autores que aparecem no
feed (não para visitar perfis). Array de entradas com os campos:

- `nome` — nome da pessoa.
- `perfil` — URL do perfil (`https://www.linkedin.com/in/...`). **Entrada com
  `perfil` vazio é ignorada** (serve de template).
- `categoria` — `comunidade-tech` | `empresa`. (A 3ª categoria,
  `empresa-relacionada`, é classificada dinamicamente e não fica na lista.)
- `relacao` — para `comunidade-tech`: `influenciador`; para `empresa`: `C-level` |
  `líder` | `cliente` | `parceiro` | `par estratégico`.
- `prioridade` — `alta` | `média` (ordena quem interagir primeiro ao bater limites).
- `observacoes` — contexto opcional (do que falar, do que evitar, sensibilidades).

### Anti-duplicação — `data/stakeholders_processados.json`

Registra cada post já interagido para nunca repetir. Não apagar; criar como `[]` se
não existir. Chave **por post**. O ideal é o `urn:li:activity:<id>`, mas a UI nova do
feed **não expõe o urn no DOM** (ver "Técnica de captura"): quando não houver urn,
usar uma chave estável de fallback `autor-handle + idade + hash-do-texto` e gravar o
urn assim que obtido (ao abrir o post para interagir).

```json
[
  {
    "postId": "urn:li:activity:7300000000000000000",
    "fallbackKey": "erickwendel|3 d|9f2a...",
    "autor": "Erick Wendel",
    "perfil": "https://www.linkedin.com/in/erickwendel/",
    "categoria": "comunidade-tech",
    "acao": ["curtir", "comentar"],
    "comentario": "Texto exato do comentário publicado, ou null se só curtiu.",
    "data": "2026-06-26T09:30:00-03:00"
  }
]
```

Antes de interagir, conferir se o post já está aqui (por `postId` ou `fallbackKey`);
se estiver, pular. Gravar **somente após** a ação ter sucesso no browser.

## Técnica de captura da timeline (revalidada 2026-06-26)

A UI do feed muda com frequência (classes ofuscadas, sem `data-view-name`,
virtualização, hidratação React que às vezes cai). Os marcos abaixo são por
**papel/aria-label**, não por classe, porque sobrevivem melhor às mudanças. Se um
seletor falhar, **sondar o DOM** (contar candidatos, listar `aria-label` dos botões)
e ajustar antes de prosseguir.

- **Estar no feed.** Navegar para `https://www.linkedin.com/feed/`. No carregamento o
  React pode logar `Minified React error #418` (mismatch de hidratação) e a coluna
  principal aparecer **sem nenhum post** por um instante: isso é recuperável, o app
  fica interativo. **Não** confiar em `[data-view-name]` (some quando a hidratação
  cai). Confiar na **lista**: `main [role="list"]` (ou `main ul`). Se ela ficar
  vazia/redirecionar para `/mynetwork/` mesmo após esperar e recarregar → log e parar.
- **O container que rola é o `<main>`, NÃO a `window`/`body`.** `window.scrollTo`
  não carrega mais posts (body fica em ~945px). Rolar o `<main>`:
  `const sc = document.querySelector('main'); sc.scrollTo(0, sc.scrollHeight)`.
  (Achar o scroller dinamicamente: o elemento com `overflowY` auto/scroll e
  `scrollHeight > clientHeight` — foi o `<main>` no último run.)
- **Feed VIRTUALIZADO:** nós do DOM são reciclados conforme rola. Para juntar 20+:
  - **Acumular em `window.__tl`** (objeto persistido), porque um `browser_evaluate`
    longo (loop com `await sleep`) é **morto** pelo re-render ("Execution context was
    destroyed"). Definir a função de captura uma vez em `window.__cap` e chamá-la em
    **passos curtos e discretos** (uma chamada por scroll), com `browser_wait_for`
    ~2,5s entre passos para o lazy-load. Repetir até `unique >= 20` ou a altura
    estabilizar por 2 ciclos. Costuma exigir ~4 passos.
- **Seletores do feed novo (por aria-label/role):**
  - Post = filho de `main [role="list"]` que contém um botão de reação. Identificar
    pela presença de `button[aria-label*="botão de reação"]`. ⚠️ O LinkedIn troca o
    **prefixo** desse aria-label com frequência (já vistos `Estado do botão de reação`
    e `Situação do botão de reação: nenhuma reação`). Casar SEMPRE pela substring
    estável `botão de reação` (`*=`), nunca pelo prefixo (`^=`).
  - **Autor real:** `button[aria-label^="Abrir menu de controle da publicação de "]`
    → o nome vem depois desse prefixo. **Confiável.** ⚠️ O **primeiro** link `/in/...`
    do nó pode ser o ator da **prova social** ("Fulano gostou/comentou/parabenizou"),
    **não** o autor. Não casar stakeholder pelo primeiro `/in/`; casar pelo **nome do
    autor** (botão de controle) e, quando o post for de fato dele, pelo `/in/` do
    bloco do autor (o link com a foto/nome do autor, não o da prova social).
  - Empresa = link `/company/<handle>`; promovido = texto contém `Promovida`/
    `Patrocinada` (pular); `Sugestões` = sugerido (ok, prioridade menor).
  - Idade/recência: primeiro trecho que casa `\b\d+\s*(min|h|d|sem|mês|meses|ano|anos|a)\b`.
  - Texto do post: `innerText` do nó (cortar ~600 chars).
- **Antes de ler estado ou clicar, `node.scrollIntoView({block:'center'})`** (barra
  de ações é lazy). Então:
  - **Curtir:** `button[aria-label*="botão de reação"]` (casa os dois prefixos:
    `Estado do botão de reação` e `Situação do botão de reação: ...`). Estado no
    próprio aria-label: contém `nenhuma reação` = não curtido; vira `gostar`/`Gostei`
    depois de clicar. Um `.click()` aplica "Gostei" padrão (não precisa abrir o menu).
    `node.querySelector(btn).click()` via `browser_evaluate` **funciona** para curtir.
  - Menu de reações (se quiser outra reação): `button[aria-label="Abrir menu de reações"]`.
  - **Comentar:** `button[aria-label="Comentar"]` (na barra de ações) abre a caixa.
    Editor agora é **tiptap/ProseMirror**: `div[contenteditable="true"][role="textbox"]`
    (aria-label "Editor de texto para criar comentário"), **não** mais `ql-editor`.
    Digitar com `browser_type`. **Publicar:** o `button` cujo texto é exatamente
    `Comentar` e **sem** `aria-label` (o botão de submit; o da barra tem
    `aria-label="Comentar"`). **Publicar comentário com `browser_click` (por `ref`),
    não com `.click()` via evaluate** — o classificador de segurança costuma barrar
    publicação por evaluate. Para localizar o submit, marcar o nó/botão com um
    atributo temporário e clicar pelo selector.
- **urn/activityId não está no DOM do feed.** Para registrar o urn de verdade, ao
  interagir abrir o post (clique no horário/permalink) e ler o `urn:li:activity:<id>`
  da URL. Sem isso, usar a chave de fallback no anti-dup.

> Esboço do passo de captura (definir em `window.__cap`, rolar o `<main>`, discreto):
>
> ```js
> () => {
>   if (!window.__tl) window.__tl = {};
>   const list = document.querySelector('main [role="list"]') || document.querySelector('main ul');
>   const sc = document.querySelector('main');
>   if (!list || !sc) return { err: 'no list/main', unique: Object.keys(window.__tl).length };
>   const hashs = s => { let h = 0; for (let i = 0; i < s.length; i++) { h = (h * 31 + s.charCodeAt(i)) | 0; } return (h >>> 0).toString(16); };
>   Array.from(list.children).forEach(node => {
>     const reactBtn = node.querySelector('button[aria-label*="botão de reação"]');  // casa "Estado..."/"Situação..."
>     if (!reactBtn) return;                       // não é post
>     const ctrl = node.querySelector('button[aria-label^="Abrir menu de controle da publicação de"]');
>     const author = ctrl ? ctrl.getAttribute('aria-label').replace(/^Abrir menu de controle da publicação de\s*/, '').trim() : null;
>     const inL = node.querySelector('a[href*="/in/"]'), coL = node.querySelector('a[href*="/company/"]');
>     const href = (inL && inL.getAttribute('href')) || (coL && coL.getAttribute('href')) || null;
>     const m = href ? href.match(/\/(in|company)\/([^/?#]+)/) : null;
>     const kind = m ? m[1] : null, handle = m ? m[2] : null;     // handle pode ser o ator da prova social
>     const txt = (node.innerText || '').replace(/\s+/g, ' ').trim();
>     const age = (txt.match(/\b(\d+)\s*(min|h|d|sem|m[êe]s|meses|ano|anos|a)\b/i) || [])[0] || null;
>     const promoted = /\bPromovid|Patrocinad/i.test(txt);
>     const key = (handle || author || '') + '|' + (age || '') + '|' + hashs(txt.slice(0, 200));
>     if (key && !window.__tl[key]) window.__tl[key] = { author, kind, handle, href, age, promoted, text: txt.slice(0, 600) };
>   });
>   sc.scrollTo(0, sc.scrollHeight);              // rolar o <main> p/ forçar render
>   return { unique: Object.keys(window.__tl).length, mounted: list.children.length, h: sc.scrollHeight };
> }
> ```
>
> Chamar `window.__cap()` repetidamente (uma chamada + wait por scroll) até `unique >= 20`.

## Interações permitidas

- **Curtir:** reação padrão "Gostei" (nada de reação exagerada em post sóbrio).
  **Automática**, dentro dos limites.
- **Comentar:** texto que agrega valor (ver regras de escrita no contexto
  compartilhado). **Curto: 1 frase padrão, máx. 2.** **Só publica após aprovação.**
- **Compartilhar:** **não** (conteúdo de terceiros).

Em post de C-level/empresa/empresa-relacionada, redobrar o cuidado com sobriedade e
com não expor relação comercial (ver "Cuidados").

## Limites (para não parecer bot)

- **Captura:** mínimo **20 posts** antes de selecionar.
- **Curtidas por execução:** até **8** (automáticas).
- **Comentários por execução:** até **3**.
- **Comentários por dia:** até **5** (somar pelo `data/log.txt` + anti-duplicação do
  dia corrente).
- **Por autor por execução:** no máximo **1 post** (o mais relevante elegível).
- **Janela de recência:** só posts dos **últimos 7 dias**; ignorar mais antigos.
- **Ritmo:** não interagir em rajada; parar ao bater qualquer teto. Captcha/
  verificação de segurança → **parar e registrar no log** (não contornar).

## Papéis: Analista → Redator

Reaproveitar as regras de escrita do contexto compartilhado, nos dois papéis:

1. **Analista** — dos posts capturados, classificar autor (stakeholder /
   empresa-relacionada / relevante), ler o post (texto, contexto, tom, se é
   sensível) e decidir o ângulo do comentário que agrega sem soar interesseiro.
   Post sensível → comentário breve e sóbrio, ou só curtir.
2. **Redator** — escrever o comentário curto (1 frase, máx. 2), aplicar
   **autoavaliação (score)** e **gate gramatical**. Olhar os últimos comentários
   (anti-dup + log) para não repetir abertura, léxico nem estrutura.

## Cuidados específicos desta skill

- **Não capturar o crédito:** comentar somando à ideia do autor, nunca redirecionar
  para si nem virar vitrine própria.
- **Não expor relação comercial:** em post de cliente/parceiro/C-level/empresa-
  relacionada, nunca citar contrato, projeto, valores ou informação não pública.
  **Não nomear a INDECX** no texto. Anti-stack vale igual.
- **Não soar interesseiro:** sem puxa-saquismo nem elogio vazio; agregar observação
  real.
- **Post sensível = tom sóbrio:** sem emoji comemorativo, sem venda, breve.
- **Respeitar `observacoes`** de cada stakeholder.

## Passos da execução

1. **Carregar estado.** Ler `data/stakeholders.json` (ignorar `perfil` vazio) e
   `data/stakeholders_processados.json` (criar `[]` se faltar). Calcular o que já foi
   feito hoje (limites) pelo histórico + `data/log.txt`.
2. **Abrir o LinkedIn.** Pré-requisitos do browser MCP no contexto compartilhado
   (rodar `mcp/launch-chrome-debug.ps1`; `.mcp.json` na raiz). Confirmar login com
   `browser_snapshot`; login/captcha → **parar e registrar no log**.
3. **Capturar a timeline.** Ir para `https://www.linkedin.com/feed/` e rodar o passo
   de captura (ver "Técnica de captura") em chamadas curtas, com **full scroll do
   `<main>`** a cada passo, **acumulando em `window.__tl`** até **≥20 posts** ou a
   altura estabilizar. Feed vazio/redirecionado → esperar, recarregar; persistir →
   log e parar.
4. **Selecionar os melhores.** Aplicar o "Objetivo da seleção": casar autores com a
   lista, classificar empresa-relacionada, marcar bons posts relevantes; filtrar por
   recência (7 dias) e tirar os já processados. Ordenar por prioridade e potencial de
   engajamento. Respeitar 1 post por autor e os tetos.
5. **Curtir (automático).** Para cada post selecionado, dentro do teto: rolar o post
   para a viewport (`scrollIntoView`), curtir via `button[aria-label^="Estado do botão
   de reação"]` (`.click()` aplica "Gostei"), confirmar pelo aria-label (passa de
   `nenhuma reação` para `gostar`/`Gostei`) e **registrar imediatamente** em
   `data/stakeholders_processados.json` (ação `curtir`).
6. **Gerar comentários (rascunho).** Para os posts que merecem comentário (até o
   teto), aplicar **Analista → Redator**, score e gate gramatical.
7. **Aprovação dos comentários.** Apresentar ao usuário a lista: autor + resumo do
   post + comentário proposto. Publicar **apenas os aprovados**. (As curtidas já
   foram feitas no passo 5; informar quais.)
8. **Publicar comentários aprovados** via browser MCP: `scrollIntoView` no post →
   `button[aria-label="Comentar"]` (abre a caixa) → editor tiptap
   `div[contenteditable="true"][role="textbox"]` → `browser_type` → publicar no
   `button` de texto `Comentar` **sem** `aria-label`, **via `browser_click` por `ref`**
   (não `.click()` por evaluate; o classificador barra publicação por evaluate) →
   confirmar com novo snapshot. Capturar o `urn:li:activity:<id>` do permalink para o
   registro.
9. **Registrar.** Atualizar `data/stakeholders_processados.json` (ação `comentar` +
   texto + urn) e dar **append no `data/log.txt`** (ISO 8601 `America/Sao_Paulo`),
   salvando os textos **mesmo se alguma ação falhar**.
10. **Limpar temporários do browser.** Apagar os artefatos da execução
    (`.playwright-mcp/`, `*-snap.yml`, `page-*.yml`, screenshots soltos na raiz).
    Nunca apagar o estado em `data/`. Detalhes na seção 4 do
    **[contexto compartilhado](../_shared/contexto-compartilhado.md)**.
11. **Persistir no Git.** Sincronizar o estado com o repositório privado (seção 7
    do **[contexto compartilhado](../_shared/contexto-compartilhado.md)**):
    `pwsh -File mcp/git-sync.ps1 -Message "timeline: <N> interações (curtir+comentar) em stakeholders"`.

## Caminhos (resumo)

- Lista: `data/stakeholders.json`
- Anti-duplicação: `data/stakeholders_processados.json`
- Log (compartilhado): `data/log.txt`
- Launcher do browser: `mcp/launch-chrome-debug.ps1`
- Config MCP: `.mcp.json` (raiz)
- Persistência no Git: `mcp/git-sync.ps1`
