# Redes ópticas elásticas com SDM — o problema de RMSA

- Fonte: comunidade (educativo, redes ópticas)
- Pilar: full-stack / arquitetura (trade-offs e alocação de recurso escasso)
- Imagem: gancho, pixel 8-bit, formato palavra-herói ("RMSA" + pills ROTA / MODULAÇÃO / ESPECTRO) — posts_gerados/redes-opticas-elasticas-rmsa/imagem.png (gpt-image-2, gate aprovado)

## Texto

Uma fibra pode estar com metade do espectro livre e ainda assim recusar uma conexão nova. Não falta capacidade. Falta capacidade no lugar certo.

Isso acontece nas redes ópticas elásticas, a espinha dorsal do tráfego de longa distância. A rede antiga trabalhava com grade fixa, entregando um canal do mesmo tamanho para qualquer demanda, precisando ou não. A elástica corta o espectro em fatias finas e monta a banda sob medida, só que essa flexibilidade cobra em decisão. Para atender um pedido, três escolhas saem juntas. A rota, entre os vários caminhos da topologia. O formato de modulação, onde mora o trade-off, porque empacotar mais bits por símbolo gasta menos espectro e encurta o alcance do sinal. E as fatias de espectro, que precisam ficar lado a lado e ocupar a mesma posição em todos os enlaces da rota.

Essa última restrição é a que morde. Parece reservar poltronas numeradas em uma viagem com baldeação, onde não basta haver lugares livres, porque eles precisam ser vizinhos e ter os mesmos números em cada trecho. Conforme conexões entram e saem, o espectro vai ficando furado, com capacidade de sobra espalhada em pedaços pequenos demais para caber qualquer coisa nova.

Com SDM entra a dimensão espacial. Vários núcleos dentro da mesma fibra multiplicam a capacidade, só que núcleos vizinhos usando as mesmas fatias interferem entre si, então escolher o núcleo passa a fazer parte do problema. Juntando rota, modulação, espectro e núcleo, o resultado é NP-difícil. Rede de verdade responde em milissegundos com heurística, não com a solução ótima.

Já precisou lidar com recurso que sobrava e mesmo assim não dava para usar por causa da fragmentação?

## Hashtags

#redesdecomputadores #cienciadacomputacao #telecomunicacoes #otimizacao
