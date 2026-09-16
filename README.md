# Loyalty System Predict

Projeto de Data Science para propor uma solução de ML para gerar um sistema de pontos para estimar a lealdade de um cliente.
 
## Contexto

### O Negócio
O sistema de pontos no chat da Twitch consiste nas seguintes regras:

- `!join` para se cadastrar: funciona uma única vez e garante 50 pontos;
- `!presente` para assinar a lista de presença, recompensa de 1 cubo;
- Cada mensagem enviada no chat, recompensa de 1 cubo;
- `!troca` realiza a troca de cubos por datapoints, moeda da nossa loja no StreamElements;

Com base nessas transações são identificamos a atividade das pessoas e o nível de engajamento.

### Plataforma de Cursos

- Todo catálogo de cursos e projetos que estão disponíveis no YouTube;
- A pessoa salva sua progressão completando vídeos;
- É possível preencher os dados de PDI que também ficam salvos;
- Há recompensas e integração com o sistema de pontos anterior;

## O que se espera responder
- O que está acontecendo com o engajamento das pessoas?

### Conceitos
- MAU: monthly active user
- WAC
- DAC

### Ciclo de Vida Do Usuário

Como parte do modelo de loyalty prediction, cada usuário é classificado em um estágio de ciclo de vida com base no seu padrão de recência e frequência de compras. Essa segmentação permite direcionar ações de retenção, reativação e fidelização de forma mais assertiva, de acordo com o momento de relacionamento de cada usuário com a marca.

Os estágios definidos são:

- Curioso — Usuário novo, que iniciou seu relacionamento recentemente.
- Fiel — Usuário ativo e recorrente, com interações frequentes e recentes.
- Reconquistado — cliente que havia dado sinais de esfriamento e voltou a comprar recentemente.
- Recuperado — Usuário que estava inativo há bastante tempo e retomou o consumo recentemente.
- Turista — Usuário com engajamento moderado, sem comprar há algumas semanas.
- Desencantado — Usuário com sinais de afastamento, sem comprar há um período mais longo.
- Perdido — Usuário inativo há muito tempo, com baixa probabilidade de retorno espontâneo.