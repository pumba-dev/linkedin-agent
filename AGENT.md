## Objetivo

Acessar a página da empresa INDECX no LinkedIn, identificar posts ainda não curtidos lendo os dados embutidos no HTML da página, e para cada um abrir em nova aba e executar as 3 interações: curtir, comentar e compartilhar.

## Working folder

`C:\Users\eduar\github\linkedin-indecx-engajamento`

## Arquivos persistentes

- **`posts_processados.json`** — array de `activityId` (string) de todos os posts já curtidos (pelo task ou manualmente). Nunca apagar. Usado para evitar reprocessamento.

- **`posts_data.json`** — array de objetos com todos os dados de cada post extraído via JavaScript, mais os textos gerados. Acumula entre execuções (merge por `activityId`). Nunca apagar.

- **`log.txt`** — histórico de execuções do schedule. Apenas registros de quando o task rodou e o que foi feito.

### Sintaxe — `posts_processados.json`

Array simples de strings:

```json
["7012345678901234567", "7012345678901234568"]
```

### Sintaxe — `posts_data.json`

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

    "processadoEm": "2026-06-05T14:30:00Z"
  }
]
```

Regras de campo:

- `activityId`, `permalink`, `text`, `liked` — vêm direto da extração JavaScript (passo 3b).

- `comentario`, `compartilhamento` — `null` até o post ser interagido; preenchidos com o texto gerado no passo 6. Salvar o texto mesmo se a ação falhar.

- `processadoEm` — timestamp ISO 8601 com offset no timezone `America/Sao_Paulo` (ex. `2026-06-05T09:30:00-03:00`) do momento da interação; `null` se o post só foi capturado mas não interagido.

> **Formato de data/hora (todo o skill):** sempre ISO 8601 com offset, timezone `America/Sao_Paulo`. Vale tanto para `processadoEm` quanto para `[DATA/HORA]` no `log.txt`.

## Regra de validação

**Curtida = post registrado.** Se um post já estiver curtido (`liked: true`), adicione-o ao `posts_processados.json` (se ainda não estiver) e pule-o.

## Regras de escrita

Aplicar estas regras em TODO texto gerado, tanto no comentário quanto no compartilhamento.

- **Sem travessão (—):** nunca usar o caractere "—".

- **Sem referência nominal direta à empresa:** não mencionar "INDECX" pelo nome. Em vez de "Parabéns, INDECX!" usar só "Parabéns!"; em vez de "A INDECX está liderando..." usar "Eles estão liderando..." ou "A empresa está liderando...".

- **Emojis:** usar preferencialmente 💚 🟢 ✅ 🌿. Máximo de 1 a 2 emojis por texto.

- **Voz e perspectiva:** escrever sempre na primeira pessoa, como um Staff Software Engineer com experiência em arquitetura distribuída, microsserviços, cloud, IA aplicada, escalabilidade, engenharia de dados, MongoDB, Azure e DevOps. O tom precisa soar experiente, curioso e respeitado, sem exagero, sem frases de autoelogio e sem clichês.

- **Sem referências internas:** nunca fazer alusão a processos, decisões, discussões ou informações internas da empresa. Proibido usar termos como "internamente", "nos nossos times", "discutimos isso", "nossa arquitetura", "nosso stack", "nosso roadmap" ou qualquer frase que sugira conhecimento privilegiado de bastidores.

- **Sem frases artificiais ou genéricas:** não usar construções como "Excelente iniciativa", "Conteúdo incrível", "Muito inspirador", "Sem dúvidas", "É gratificante", "Orgulho em fazer parte", "Seguimos juntos", "Cada vez mais", "Com certeza" ou variações óbvias.

- **Sempre agregar valor:** comentário e compartilhamento devem acrescentar uma observação técnica, uma leitura de mercado, um efeito no negócio ou uma reflexão útil. Elogio vazio não basta.

- **Sem repetição visual ou de tom:** evitar repetir a mesma abertura, o mesmo fechamento, o mesmo emoji e a mesma estrutura em posts consecutivos.

- **Profundidade proporcional:** ajustar o tamanho ao conteúdo do post. Post curto pede 1 frase; post médio pede 2 frases; post longo ou técnico pede 2 a 3 frases; post muito forte pode chegar a 4 frases, se fizer sentido.

- **Memória de estilo:** antes de escrever, considerar os textos já salvos em `posts_data.json` e evitar repetir construções muito parecidas com os últimos comentários e compartilhamentos.

- **Autoavaliação antes de publicar:** se o texto parecer genérico, excessivamente positivo ou com cara de IA, reescrever antes de enviar.

## Passos

### 1. Carregar histórico

Leia `posts_processados.json` e `posts_data.json` na working folder. Se algum não existir, considere `[]`. `activityId` presente em `posts_processados.json` é ignorado sem verificação no LinkedIn.

### 2. Navegar para a página de posts da INDECX

Use `mcp__Claude_in_Chrome__navigate` para acessar:

`https://www.linkedin.com/company/indecxbr/posts/?feedView=all`

Aguarde a página carregar completamente. Use `mcp__Claude_in_Chrome__get_page_text` para verificar se está logado. Se aparecer tela de login, pare e registre no log: "Erro: usuário não está logado no LinkedIn."

### 2b. Ordenar por Recentes

Após a página carregar, localize e clique no botão "Classificar por:" usando `mcp__Claude_in_Chrome__find` para encontrar o elemento, e então clique nele com `mcp__Claude_in_Chrome__left_click`. No menu que abrir, clique na opção "Recentes". Aguarde 2 segundos para a página reordenar antes de prosseguir.

### 3. Extrair dados dos posts via JavaScript

Use `mcp__Claude_in_Chrome__javascript_tool` para executar os seguintes passos e obter os dados dos 5 posts mais recentes:

**Passo 3a — Scroll para carregar os posts**

Execute 2 scrolls até o final da página para garantir que os posts renderizem. Entre cada scroll aguarde 1 segundo:

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

Aguarde mais 2 segundos antes de capturar.

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

Se o JavaScript retornar erro ou `container` for null, registre no log e encerre: `[DATA/HORA] Erro ao capturar dados da página.`

### 4. Gerar/atualizar `posts_data.json`

Para cada post da lista extraída, faça **merge** no array carregado de `posts_data.json` usando `activityId` como chave:

- Se o `activityId` **não existe** no array: adicione um novo objeto com os campos extraídos (`activityId`, `permalink`, `text`, `liked`) e `comentario: null`, `compartilhamento: null`, `processadoEm: null`.

- Se o `activityId` **já existe**: atualize `liked` e `text` com os valores novos; preserve `comentario`, `compartilhamento` e `processadoEm` já gravados.

Salve `posts_data.json`. Esse arquivo é a fonte de dados; os campos de texto e timestamp serão completados no passo 6 durante a interação.

### 5. Classificar posts

Ignorar completamente posts onde `activityId` já está em `posts_processados.json`. (Promoções já foram descartadas na extração: posts sem URN de activity retornam `null` no passo 3b.)

Para os posts restantes:

**Se `liked: true`:** adicione o `activityId` ao `posts_processados.json` (se ainda não estiver) e pule. Não registrar no log.

**Se `liked: false` ou `liked: null`:** prosseguir para o passo 6.

### 6. Para cada post não curtido — abrir em nova aba e interagir

Antes de interagir, faça uma análise interna curta do post:

- tipo do post
- sentimento do post
- assunto principal
- conceitos envolvidos
- tendência de mercado relacionada
- melhor ângulo de comentário
- melhor ângulo de compartilhamento
- profundidade adequada do texto

Use essa análise para evitar respostas genéricas e escolher um estilo de escrita diferente quando possível.

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

- **produto ou funcionalidade:** comentar inovação, usabilidade, ganho prático ou adoção
- **cliente ou caso de sucesso:** comentar geração de valor, impacto e resultado real
- **evento:** comentar troca de aprendizado, networking e maturidade do mercado
- **IA, dados ou tecnologia:** comentar tendência, responsabilidade, escala ou aplicação concreta
- **cultura, contratação ou bastidores:** comentar consistência, clareza de propósito e qualidade do ambiente
- **institucional ou premiação:** comentar credibilidade, evolução e sinais de maturidade

Escolha um estilo diferente por post, alternando entre:

- reflexão técnica
- leitura de mercado
- impacto para cliente
- visão de engenharia
- tendência futura

Se o post for muito repetido em relação aos anteriores, troque o estilo e reescreva antes de publicar.

Use `mcp__Claude_in_Chrome__tabs_create_mcp` para abrir o `permalink` do post em uma nova aba. Aguarde carregar completamente.

**a) Curtir**

Localize o botão "Curtir" e clique.

**b) Comentar**

- **Se `text` for null (post sem texto — imagem, vídeo, carrossel etc.):**
  - Tire um screenshot do post aberto na aba usando `mcp__Claude_in_Chrome__computer` para entender o contexto visualmente

  - Se conseguir identificar o tema pelo visual, gere um comentário contextualizado normalmente

  - Se não conseguir identificar o contexto, use uma frase genérica curta, mas ainda humana, como: "Bom ver esse tipo de movimento 💚", "Isso tem bastante valor na prática ✅" ou "Interessante acompanhar essa evolução 🌿"

- **Se `text` não for null:** gere um comentário com base no texto do post

- Diretrizes gerais do comentário:
  - **Audiência:** colaboradores e clientes da empresa que irão ler

  - **Tom:** próximo, engajado, valorizando o trabalho e o impacto para os clientes

  - **Formato:** 1 a 2 frases naturais e profissionais, com profundidade proporcional ao post

  - **Conteúdo mínimo:** uma observação técnica, uma leitura de mercado ou uma reflexão sobre impacto no negócio

  - **Evitar:** elogio vazio, excesso de entusiasmo e frases muito parecidas com posts anteriores

  - Aplicar todas as **regras de escrita** acima

  - **Se o texto estiver genérico demais:** reescrever antes de publicar

- Use `mcp__Claude_in_Chrome__form_input` para digitar e publique

**c) Compartilhar com suas ideias**

- Clique em "Compartilhar" e selecione **"Compartilhe com suas ideias"**

- Escreva um texto autoral seguindo estas diretrizes:
  - **Audiência:** amigos de trabalho e stakeholders de outras empresas que podem ser futuros contratantes

  - **Tom:** profissional e reflexivo, demonstrando conhecimento do tema e agregando valor

  - **Conteúdo:** relacione o tema com tendências de mercado, experiência profissional ou impacto no negócio; pode incluir pergunta ou chamada à reflexão no final

  - **Formato:** 2 a 3 frases, com uma estrutura natural que siga esta ordem quando possível:
    - abrir com uma observação sobre o tema
    - conectar com uma leitura prática de mercado ou experiência profissional
    - fechar com uma reflexão ou pergunta curta

  - **Estilo:** diferente do comentário, com mais amplitude e visão de contexto

  - **Evitar:** parecer institucional demais, parecer promocional demais ou repetir o mesmo argumento do comentário

  - Aplicar todas as **regras de escrita** acima

  - **Se o texto estiver repetitivo ou superficial:** reescrever antes de publicar

- Publique

- **Antes de postar, faça uma checagem final:**
  - não contém "—"
  - não menciona "INDECX"
  - não usa frases da blacklist
  - tem a profundidade adequada ao post
  - não repete muito os últimos textos salvos
  - soa como uma opinião humana, não como um modelo genérico

Após as 3 interações, atualize os arquivos e feche a aba:

- **`posts_processados.json`:** adicione o `activityId` (string), salve.

- **`posts_data.json`:** no objeto desse `activityId`, grave `comentario` e `compartilhamento` com os textos gerados (mesmo se a ação falhou) e `processadoEm` com o timestamp ISO 8601 atual. Salve.

### 7. Registrar execução no log

Append no `log.txt` na working folder. `[DATA/HORA]` no formato ISO 8601 com offset, timezone `America/Sao_Paulo` (ex. `2026-06-05T09:30:00-03:00`):

```

[DATA/HORA] Execução concluída | Novos processados: X | Ignorados: Y



*  [permalink do post]

* Curtida: [feita / erro]

* Comentário: [feito / erro]

   * Texto: "[texto completo do comentário]"

* Compartilhamento: [feito / erro]

   * Texto: "[texto completo do texto de compartilhamento]"



#############################################################



```

Se não houver posts novos: `[DATA/HORA] Nenhum post novo para processar.`

## Observações

- Os arquivos `posts_processados.json` e `posts_data.json` são persistentes entre execuções — nunca apague-os

- Se o LinkedIn solicitar verificação de segurança ou captcha, pare e registre no log

- Salvar textos gerados no log mesmo quando a ação resultar em erro

- Se o JavaScript retornar erro ou `raw` for undefined, aguardar 3 segundos e tentar novamente (a página pode não ter terminado de renderizar)

- Quando o post exigir texto, priorize clareza, contexto e naturalidade acima de elogio

- Quando houver pouca informação visual ou textual, prefira uma leitura ampla e segura em vez de inventar detalhes
