Clicar duas vezes em "pagar" não deveria cobrar duas vezes. Idempotência é o nome dessa garantia.

Toda rede falha em algum momento. A requisição sai, a resposta se perde, o cliente tenta de novo. A pergunta é o que acontece na segunda tentativa.

Uma operação idempotente pode rodar uma ou dez vezes e o resultado final é o mesmo.

Pensa no botão do elevador. Apertar cinco vezes não faz o elevador chegar mais rápido. O primeiro toque registrou a chamada, os outros não mudam nada.

Criar um pedido sem essa proteção é o oposto. Dois cliques, dois pedidos. Um retry automático da rede, cobrança duplicada.

Na prática, a saída costuma ser uma chave de idempotência. O cliente manda um identificador único na operação. O servidor guarda o resultado da primeira execução e devolve essa mesma resposta se a chave voltar, em vez de rodar tudo de novo.

Isso muda o projeto do sistema. Retry deixa de ser risco e vira comportamento seguro. A fila pode reentregar a mensagem, o webhook pode chegar em dobro. Nada disso quebra.

O detalhe é que idempotência não vem de graça. Ela se projeta na operação, não se adiciona depois.

Onde você já se queimou com uma operação que rodou duas vezes sem querer?

#engenhariadesoftware #backend #arquiteturadesoftware #sistemasdistribuidos
