---
name: linkedin-empresa
description: >-
  Use quando o usuário pedir para interagir com os posts da PÁGINA DA EMPRESA
  (INDECX) no LinkedIn: "curte e comenta os posts da empresa", "interage com os
  posts da indecx", "processa os posts novos da página", "roda o engajamento na
  página da empresa", "curtir, comentar e compartilhar os posts da indecx".
  Acessa a página de posts da empresa, lê os posts via JavaScript, ignora os já
  curtidos e, para cada post novo, executa as 3 interações: curtir, comentar e
  compartilhar com suas ideias. NÃO é o perfil pessoal (use `linkedin-post-pessoal`)
  nem a timeline/feed de terceiros (use `linkedin-timeline`) — é só a página da
  empresa.
---

# LinkedIn — interação na página da empresa (INDECX)

Acessar a página da empresa no LinkedIn, identificar posts ainda não curtidos
lendo os dados embutidos no HTML, e para cada um abrir em nova aba e executar as
3 interações: **curtir, comentar e compartilhar**.

> Base comum (persona e voz, carreira não-pública, anti-vazamento de stack,
> regras de escrita comuns — sem travessão/emoji/blacklist/contexto
> sensível/português/score/gate — browser MCP tools+setup, estado persistente,
> data/hora e log): ver [`../_shared/contexto-compartilhado.md`](../_shared/contexto-compartilhado.md).
> Não duplicar essas regras aqui; abaixo só o específico do fluxo da empresa.

---

## Contexto da empresa (eventos internos)

A empresa tem 2 eventos internos recorrentes. Quando um post for sobre um deles,
**escrever na voz de quem participou**, não na voz de observador externo. Continua
valendo tom curto no comentário e todas as regras de escrita do `_shared` (sem
nomear a empresa, sem expor nada interno que o próprio post não mostre).

**1. Team Building** — evento anual com palestras (gerência, colaboradores e
clientes), gincanas e sempre um tema/ideal do ano. Temas:

- 2026 (ano atual): **"Time Único"**
- 2025: **"UFC — Único Time, Fanático por Clientes e Compromisso com Qualidade e Entrega"**
- 2024: **"Eu faço parte do DNA da IndeCX"**
- 2023: **"Eu faço a Roda Girar (Roda Gigante)"**

**2. Confraternização de Natal** — celebração de fim de ano, integração entre os
times.

**Como detectar:** o post cita "Team Building", o tema do ano (ex.: "Time Único"),
"confraternização", "Natal", gincana, palestras internas, ou mostra fotos de
colaboradores reunidos no evento. Na dúvida entre evento interno e evento de
mercado (ex.: Web Summit), tratar como interno só se houver sinal claro de ser um
desses dois.

**Tom quando for evento interno:**

- primeira pessoa de participante — algo como "foi muito bom estar lá", "viver
  isso de perto", sem clichê e sem exagero
- pode citar o tema do ano se ele aparecer no post (reforça que participou), mas
  sem soar decorado
- comentário segue a regra geral de comprimento (curto — ver "Comprimento dos
  textos"); o compartilhamento pode ampliar para cultura, integração e propósito
  do time, sem virar institucional ou promocional
- não expor detalhes internos que o post não tornou públicos; não nomear a
  empresa nem tecnologias

## Regra específica: NÃO nomear a empresa

Não mencionar **"INDECX"** pelo nome em nenhum texto. Em vez de "Parabéns,
INDECX!" usar só "Parabéns!"; em vez de "A INDECX está liderando..." usar "A empresa está liderando...". Esta regra vale para o comentário e para o compartilhamento, sempre.

## Comprimento dos textos

- **Comentário (curto por padrão):** imita comentário humano real de LinkedIn.
  **Padrão: 1 frase.** No máximo 2 frases; 3 frases só em casos raros, quando o
  post for muito forte e houver algo concreto a acrescentar. Vale para todos os
  comentários, sem exceção (inclusive eventos, cases, lançamentos). Nunca escrever
  comentário longo e dissertativo — isso entrega automação. Olhar os últimos
  comentários em `data/posts_data.json`: se vierem crescendo, voltar para 1 frase.
- **Compartilhamento (pode ser maior):** transmite uma mensagem para fora, então
  pode ser mais desenvolvido — **1 a 4 frases**, seguindo a estrutura do passo 6c.
  Não precisa ser curto como o comentário.

## Regra de validação

**Curtida = post registrado.** Se um post já estiver curtido (`liked: true`),
adicione-o ao `data/posts_processados.json` (se ainda não estiver) e pule-o.

## Estado persistente desta skill

Arquivos em `data/` (nunca apagar — ver `_shared` §5):

- **`data/posts_processados.json`** — array de `activityId` (string) de todos os
  posts já curtidos (pelo task ou manualmente). Usado para evitar reprocessamento.
- **`data/posts_data.json`** — array de objetos com os dados de cada post extraído
  via JavaScript, mais os textos gerados. Acumula entre execuções (merge por
  `activityId`).
- **`data/log.txt`** — histórico de execuções (compartilhado por todas as skills).

### Sintaxe — `data/posts_processados.json`

Array simples de strings:

```json
["7012345678901234567", "7012345678901234568"]
```

### Sintaxe — `data/posts_data.json`

Array de objetos. Um objeto por `activityId` (sem duplicatas). Campos:

```json
[
  {
    "activityId": "7012345678901234567",
    "permalink": "https://www.linkedin.com/feed/update/urn:li:activity:7012345678901234567/",
    "text": "texto completo do post extraído da página",
    "liked": true,
    "comentario": "texto do comentário gerado, ou null se não gerado",
    "compartilhamento": "texto de compartilhamento gerado, ou null se não gerado",
    "processadoEm": "2026-06-05T14:30:00-03:00"
  }
]
```

Regras de campo:

- `activityId`, `permalink`, `text`, `liked` — vêm direto da extração JavaScript
  (passo 3b).
- `comentario`, `compartilhamento` — `null` até o post ser interagido; preenchidos
  com o texto gerado no passo 6. Salvar o texto mesmo se a ação falhar.
- `processadoEm` — timestamp ISO 8601 com offset, timezone `America/Sao_Paulo`
  (ex. `2026-06-05T09:30:00-03:00`) do momento da interação; `null` se o post só
  foi capturado mas não interagido.

> Formato de data/hora e regras de log: ver `_shared` §6.

---

## Passos

### 1. Carregar histórico

Leia `data/posts_processados.json` e `data/posts_data.json` na working folder. Se
algum não existir, considere `[]`. `activityId` presente em
`data/posts_processados.json` é ignorado sem verificação no LinkedIn.

### 2. Navegar para a página de posts da empresa

Use `browser_navigate` para acessar:

`https://www.linkedin.com/company/indecxbr/posts/?feedView=all`

Aguarde a página carregar completamente. Use `browser_snapshot` para verificar se
está logado. Se aparecer tela de login, pare e registre no log: "Erro: usuário
não está logado no LinkedIn." (não tentar logar sozinho — ver `_shared` §4).

### 2b. Ordenar por Recentes

Após a página carregar, tire um `browser_snapshot` para localizar o botão
"Classificar por:" e obter seu `ref`, depois clique nele com `browser_click`. No
menu que abrir, tire novo snapshot se necessário e clique na opção "Recentes" com
`browser_click`. Use `browser_wait_for` (~2s) para a página reordenar antes de
prosseguir.

### 3. Extrair dados dos posts via JavaScript

Use `browser_evaluate` para executar os seguintes passos e obter os dados dos 5
posts mais recentes (passe o código como uma função `() => { ... }` que retorna o
valor — os blocos abaixo terminam em `JSON.stringify(...)`; envolver em função e
dar `return`).

**Passo 3a — Scroll para carregar os posts**

Execute 2 scrolls até o final da página para garantir que os posts renderizem.
Entre cada scroll aguarde 1 segundo:

```javascript
// Scroll 1

window.scrollTo({ top: document.body.scrollHeight, behavior: "smooth" });

("scroll 1 done");
```

Aguarde 1 segundos. Depois:

```javascript
// Scroll 2

window.scrollTo({ top: document.body.scrollHeight, behavior: "smooth" });

("scroll 2 done");
```

Aguarde mais 3 segundos antes de capturar.

**Passo 3b — Capturar os posts do DOM**

```javascript
const container = document.querySelector(".scaffold-finite-scroll__content");

if (!container) {
  JSON.stringify({ error: "Container não encontrado" });
}

// Posts são elementos .occludable-update que já renderizaram (innerHTML não vazio)

const postEls = [...container.querySelectorAll(".occludable-update")].filter(
  (p) => p.innerHTML.trim().length > 50,
);

const posts = postEls
  .map((el) => {
    // URN do activity — posts sem ele são promoções, ignorar

    const urnEl = el.querySelector('[data-urn*="urn:li:activity"]');

    if (!urnEl) return null;

    const urn = urnEl.dataset.urn;

    const activityId = urn.match(/urn:li:activity:(\d+)/)?.[1];

    // Texto do post

    const textEl = el.querySelector(
      ".feed-shared-update-v2__description, .update-components-text__text",
    );

    const text = textEl?.innerText?.trim() || null;

    // Curtida: botão .react-button__trigger com aria-pressed="true" e classe react-button--active

    const likeBtn = el.querySelector(".react-button__trigger");

    const liked =
      likeBtn?.getAttribute("aria-pressed") === "true" ||
      likeBtn?.classList.contains("react-button--active") === true;

    return {
      activityId,

      permalink: `https://www.linkedin.com/feed/update/urn:li:activity:${activityId}/`,

      text,

      liked,
    };
  })
  .filter(Boolean);

// Ordenar por activityId decrescente (maior = mais recente) e pegar os 5 primeiros

const sorted = posts

  .sort((a, b) => (BigInt(b.activityId) > BigInt(a.activityId) ? 1 : -1))

  .slice(0, 5);

JSON.stringify(sorted);
```

Parse o JSON retornado para obter a lista de posts.

Se o JavaScript retornar erro ou `container` for null, registre no log e encerre:
`[DATA/HORA] Erro ao capturar dados da página.`

### 4. Gerar/atualizar `data/posts_data.json`

Para cada post da lista extraída, faça **merge** no array carregado de
`data/posts_data.json` usando `activityId` como chave:

- Se o `activityId` **não existe** no array: adicione um novo objeto com os campos
  extraídos (`activityId`, `permalink`, `text`, `liked`) e `comentario: null`,
  `compartilhamento: null`, `processadoEm: null`.
- Se o `activityId` **já existe**: atualize `liked` e `text` com os valores novos;
  preserve `comentario`, `compartilhamento` e `processadoEm` já gravados.

Salve `data/posts_data.json`. Esse arquivo é a fonte de dados; os campos de texto
e timestamp serão completados no passo 6 durante a interação.

### 5. Classificar posts

Ignorar completamente posts onde `activityId` já está em
`data/posts_processados.json`. (Promoções já foram descartadas na extração: posts
sem URN de activity retornam `null` no passo 3b.)

Para os posts restantes:

**Se `liked: true`:** adicione o `activityId` ao `data/posts_processados.json` (se
ainda não estiver) e pule. Não registrar no log.

**Se `liked: false` ou `liked: null`:** prosseguir para o passo 6.

### 6. Para cada post não curtido — abrir em nova aba e interagir

A geração de texto usa dois papéis separados: o **Analista** estrutura o post e o
**Redator** escreve a partir só dessa análise. Isso reduz resposta superficial e
evita ecoar o texto do post.

**Papel Analista** — antes de escrever, produzir internamente esta análise
estruturada:

- tipo do post (ver lista abaixo)
- sentimento do post: positivo, neutro, comemorativo, técnico, educacional,
  convite, case, lançamento ou **sensível/triste** (luto, perda, crise,
  despedida, pedido de desculpas, notícia difícil)
- assunto principal
- conceitos envolvidos
- tendência de mercado relacionada
- público-alvo do post
- melhor ângulo de comentário
- melhor ângulo de compartilhamento
- estilo escolhido (da biblioteca de estilos) e comprimento-alvo (comentário
  curto, compartilhamento maior — ver "Comprimento dos textos")
- se o post é sobre um **evento interno recorrente** (Team Building ou
  Confraternização de Natal — ver "Contexto da empresa"); se sim, marcar para usar
  tom de participante

Use essa análise para evitar respostas genéricas e escolher um estilo de escrita
diferente a cada post.

Tipos de post que podem orientar a resposta:

- caso de sucesso
- produto novo
- funcionalidade
- evento
- contratação
- cultura
- inteligência artificial
- dados
- ESG
- parceiro
- premiação
- cliente
- bastidores
- pesquisa
- institucional

Diretrizes por tipo:

- **produto ou funcionalidade:** comentar inovação, usabilidade, ganho prático ou
  adoção
- **cliente ou caso de sucesso:** comentar geração de valor, impacto e resultado
  real
- **evento:** se for **evento interno** (Team Building ou Confraternização de
  Natal — ver "Contexto da empresa"), usar tom de quem participou (estive lá),
  focando time, cultura e propósito; se for **evento de mercado** (ex.: Web
  Summit), comentar troca de aprendizado, networking e maturidade do mercado
- **IA, dados ou tecnologia:** comentar tendência, responsabilidade, escala ou
  aplicação concreta
- **cultura, contratação ou bastidores:** comentar consistência, clareza de
  propósito e qualidade do ambiente
- **institucional ou premiação:** comentar credibilidade, evolução e sinais de
  maturidade

**Biblioteca de estilos.** Antes de escrever, escolha UM estilo. Rotacione de
forma determinística: índice do estilo = (quantidade de objetos com `comentario`
já preenchido em `data/posts_data.json`) mod 5. Nunca repita o estilo usado no
post imediatamente anterior. Os exemplos abaixo são apenas o ÂNGULO de abertura,
não frases para copiar:

- **Engenharia** — como o sistema sustenta a escala da escuta do cliente. Ex.:
  "Sustentar cobertura total de feedback é menos sobre coletar e mais sobre o que
  categoriza tudo isso em tempo real."
- **Dados / IA** — ingestão, categorização, análise de sentimento, leitura de
  feedback em escala. Ex.: "Análise de sentimento só vira ativo quando alimenta a
  decisão antes do churn, não no relatório do mês seguinte."
- **Produto** — como a decisão técnica vira valor para o cliente. Ex.: "A parte
  difícil não é medir o indicador, é fechar o loop entre o dado e a ação de quem
  mexe no produto."
- **Mercado** — maturidade de experiência do cliente e SaaS B2B no Brasil. Ex.:
  "O mercado está saindo da fase de dashboard para a de inteligência acionável."
- **Liderança técnica** — trade-offs, priorização, qualidade (lente de Tech
  Lead). Ex.: "Toda decisão centrada no cliente esbarra num trade-off técnico
  real; é aí que a conversa fica boa."

Regras dos estilos:

- Falar sempre em nível de conceito. Os estilos Engenharia e Dados/IA jamais
  nomeiam tecnologia, ferramenta, framework ou stack (ver anti-vazamento no
  `_shared` §1).
- Variar o léxico: se "roadmap", "produto" ou "dados" já apareceu nos últimos 3
  textos salvos em `data/posts_data.json`, trocar de palavra ou de ângulo.
- Se o post for muito parecido com os anteriores, trocar o estilo e reescrever
  antes de publicar.

**Papel Redator** — recebe APENAS a análise do Analista (não reescreve nem copia
o texto do post). Com base nela:

- escolhe um ângulo que AGREGUE valor, nunca só elogio
- escreve o comentário (diretrizes em 6b) e o texto de compartilhamento
  (diretrizes em 6c), aplicando todas as regras de escrita do `_shared` e o
  comprimento-alvo definido. Exceção: em contexto sensível/triste, escrever apenas
  o comentário sóbrio e NÃO gerar compartilhamento (ver 6c)
- roda a autoavaliação (score) em cada texto; se reprovar, reescreve antes de
  prosseguir (ver `_shared` §2)

Só com os dois textos aprovados, execute as interações abaixo.

Use `browser_tabs` (action `new`) para abrir o `permalink` do post em uma nova aba
e selecione-a. Aguarde carregar completamente.

**a) Curtir**

Tire um `browser_snapshot`, localize o botão "Curtir" e clique com
`browser_click`.

**Assim que a curtida for confirmada, adicione imediatamente o `activityId`
(string) ao `data/posts_processados.json` (se ainda não estiver) e salve** — antes
de comentar e compartilhar. Curtida = post registrado. Isso evita que uma execução
concorrente ou uma falha no meio do fluxo reprocesse o mesmo post (já houve caso de
post interagido em duplicado).

**b) Comentar**

- **Se `text` for null (post sem texto — imagem, vídeo, carrossel etc.):**
  - Tire um screenshot do post aberto na aba usando `browser_take_screenshot` para
    entender o contexto visualmente
  - Se conseguir identificar o tema pelo visual, gere um comentário
    contextualizado normalmente
  - Se não conseguir identificar o contexto, use uma frase genérica curta, mas
    ainda humana, como: "Bom ver esse tipo de movimento 💚", "Isso tem bastante
    valor na prática ✅" ou "Interessante acompanhar essa evolução 🌿". Essas
    frases positivas só servem para contexto neutro ou positivo; se houver
    qualquer sinal de luto, crise ou notícia difícil na imagem, aplicar a regra de
    **contexto sensível ou triste** (`_shared` §2) e usar tom sóbrio, sem emoji.

- **Se `text` não for null:** gere um comentário com base no texto do post

- Diretrizes gerais do comentário:
  - **Audiência:** colaboradores e clientes da empresa que irão ler
  - **Tom:** próximo, engajado, valorizando o trabalho e o impacto para os
    clientes
  - **Formato:** curto — **1 linha (uma frase) por padrão**, no máximo 2 linhas; 3
    linhas só em casos raros (post muito forte). Comentário humano de LinkedIn é
    curto; texto longo entrega automação. Ver "Comprimento dos textos".
  - **Conteúdo mínimo:** uma observação ou reflexão útil que caiba em 1 linha. Não
    precisa esgotar o assunto no comentário — o aprofundamento vai no
    compartilhamento
  - **Evitar:** elogio vazio, excesso de entusiasmo e frases muito parecidas com
    posts anteriores
  - Aplicar todas as **regras de escrita** do `_shared` §2
  - **Se o texto estiver genérico demais:** reescrever antes de publicar

- Use `browser_snapshot` para localizar a caixa de comentário, digite com
  `browser_type` e publique (clicar no botão "Publicar" com `browser_click`)

**c) Compartilhar com suas ideias**

- **Se o sentimento do post for sensível/triste (luto, perda, crise, despedida,
  pedido de desculpas): NÃO compartilhar.** Pular esta etapa inteira: não clicar
  em Compartilhar, deixar `compartilhamento: null` no `data/posts_data.json` e
  registrar `Compartilhamento: pulado (contexto sensível)` no log. Seguir direto
  para o fechamento. A curtida e o comentário sóbrio já bastam.

- Caso contrário, clique em "Compartilhar" e selecione **"Compartilhe com suas
  ideias"**.

  **Como clicar no botão certo (evita erro de seletor duplicado):** a página pode
  ter MAIS DE UM botão de compartilhar — o da barra de ações do post E um dentro
  do player de vídeo/mídia. Clicar pelo seletor genérico
  (`button.social-reshare-button`) dá "strict mode violation: resolved to 2
  elements". Para acertar sempre:
  - O botão correto é o **dropdown trigger da barra de ações do post**: tem as
    classes `social-reshare-button` **e** `artdeco-dropdown__trigger`, atributo
    `aria-expanded`, e fica dentro de `.feed-shared-social-action-bar`. NÃO é o que
    está dentro do player de vídeo.
  - Seletor recomendado:
    `.feed-shared-social-action-bar button.social-reshare-button.artdeco-dropdown__trigger`.
    Se ainda houver mais de um match, usar o primeiro que tenha `aria-expanded` e
    que NÃO esteja dentro de um container de vídeo/mídia
    (`.update-components-linkedin-video`, `.feed-shared-update-v2__content`,
    player).
  - Confirmar que o menu abriu (procurar o item "Compartilhe com suas ideias")
    antes de prosseguir; se não abriu, tirar `browser_snapshot` e clicar pelo `ref`
    do botão correto.
  - Depois, clicar no item **"Compartilhe com suas ideias"** (cria publicação
    nova) — não no "Compartilhar" simples (repost sem texto).

- Escreva um texto autoral seguindo estas diretrizes:
  - **Audiência:** amigos de trabalho e stakeholders de outras empresas que podem
    ser futuros contratantes
  - **Tom:** profissional e reflexivo, demonstrando conhecimento do tema e
    agregando valor
  - **Conteúdo:** relacione o tema com tendências de mercado, experiência
    profissional ou impacto no negócio; pode fechar com uma reflexão afirmativa.
    **NÃO terminar com pergunta dirigida a outras empresas** (ex.: "Que estruturas
    a sua empresa tem criado...?", "Como a sua empresa faz...?"). Como o usuário
    trabalha na empresa, divulgar o conteúdo dela e ainda interpelar terceiros soa
    a provocação. Fechar afirmando, no lado positivo, não perguntando ao leitor.
  - **Formato:** 2 a 4 frases (pode ser maior que o comentário, pois transmite uma
    mensagem para fora), com uma estrutura natural que siga esta ordem quando
    possível:
    - abrir com uma observação sobre o tema
    - conectar com uma leitura prática de mercado ou experiência profissional
    - fechar com uma reflexão afirmativa curta (nunca pergunta dirigida a outras
      empresas — ver Conteúdo acima)
  - **Estilo:** diferente do comentário, com mais amplitude e visão de contexto
  - **Evitar:** parecer institucional demais, parecer promocional demais ou
    repetir o mesmo argumento do comentário
  - Aplicar todas as **regras de escrita** do `_shared` §2

  - **Se o texto estiver repetitivo ou superficial:** reescrever antes de publicar

- Publique

- **Antes de postar, faça uma checagem final:**
  - não contém "—"
  - não menciona "INDECX"
  - **o compartilhamento não termina com pergunta dirigida a outras empresas**
    (fecha com afirmação positiva, não interpela o leitor)
  - não usa frases da blacklist
  - tem a profundidade adequada ao post
  - não repete muito os últimos textos salvos
  - **português 100% correto:** sem erro de vírgula, ortografia, acentuação,
    concordância, regência ou crase; sem contração coloquial ("pra"/"pro") —
    passou pelo gate gramatical (`_shared` §2)
  - soa como uma opinião humana, não como um modelo genérico

Após as 3 interações, atualize os arquivos e feche a aba:

- **`data/posts_processados.json`:** confirme que o `activityId` (string) está
  presente — ele já foi adicionado logo após a curtida no passo 6a; se por algum
  motivo não estiver, adicione e salve.
- **`data/posts_data.json`:** no objeto desse `activityId`, grave `comentario` e
  `compartilhamento` com os textos gerados (mesmo se a ação falhou) e
  `processadoEm` com o timestamp ISO 8601 atual. Salve. Em contexto
  sensível/triste, `compartilhamento` permanece `null` (etapa pulada).

### 7. Registrar execução no log

Append no `data/log.txt` na working folder. `[DATA/HORA]` no formato ISO 8601 com
offset, timezone `America/Sao_Paulo` (ex. `2026-06-05T09:30:00-03:00`):

```

[DATA/HORA] Execução concluída | Novos processados: X | Ignorados: Y



*  [permalink do post]

* Curtida: [feita / erro]

* Comentário: [feito / erro]

   * Texto: "[texto completo do comentário]"

* Compartilhamento: [feito / erro / pulado (contexto sensível)]

   * Texto: "[texto completo do texto de compartilhamento]"



#############################################################



```

Se não houver posts novos: `[DATA/HORA] Nenhum post novo para processar.`

### 8. Limpar temporários do browser

Apagar os artefatos temporários gerados na execução (`.playwright-mcp/`,
`*-snap.yml`, `page-*.yml`, screenshots de checagem na raiz). Detalhes e o que
**nunca** apagar (estado em `data/`) na seção 4 do
**[contexto compartilhado](../_shared/contexto-compartilhado.md)**.

### 9. Persistir no Git

Sincronizar o estado com o repositório privado (seção 7 do
**[contexto compartilhado](../_shared/contexto-compartilhado.md)**):

```powershell
& "C:\Users\eduar\github\linkedin-indecx-engajamento\mcp\git-sync.ps1" -Message "empresa: <N> posts interagidos (curtir+comentar+share)"
```

## Observações

- Os arquivos `data/posts_processados.json` e `data/posts_data.json` são
  persistentes entre execuções — nunca apague-os.
- Limpar os temporários do browser ao final (passo 8); nunca apagar `data/`.
- Se o LinkedIn solicitar verificação de segurança ou captcha, pare e registre no
  log.
- Salvar textos gerados no log mesmo quando a ação resultar em erro.
- Se o JavaScript retornar erro ou `raw` for undefined, aguardar 3 segundos e
  tentar novamente (a página pode não ter terminado de renderizar).
- Quando o post exigir texto, priorize clareza, contexto e naturalidade acima de
  elogio.
- Quando houver pouca informação visual ou textual, prefira uma leitura ampla e
  segura em vez de inventar detalhes.
