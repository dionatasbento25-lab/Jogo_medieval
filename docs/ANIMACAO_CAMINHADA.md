# Animação de caminhada dos soldados

## Como os soldados são desenhados

- Tudo é desenhado em **WebGL2**: cada soldado é um quad instanciado (8 floats: posição, quadro, flags, rotação, tinta, fase e z).
- O shader lê o retângulo e a âncora de cada quadro numa **tabela de quadros** (`uFrames`, via `texelFetch`) e amostra o atlas.
- O atlas original tem 481 quadros: 2 times × 8 tipos × 5 direções desenhadas (`front`, `side`, `back`, `fd`, `bd`) × 6 fases (parado + 5 do golpe), mais a flecha. As outras 3 direções são obtidas por espelhamento, o que dá **8 direções** no total.
- Antes desta versão não existia nenhum quadro de caminhada: o shader só deslocava a faixa dos pés e balançava a imagem inteira.

## O que foi implementado

### Geração dos spritesheets (`bakeWalk`)
Na carga, cada sprite parado vira um boneco articulado:

1. **Segmentação das pernas.** Cada perna é rastreada do chão para cima, linha a linha, até sumir sob a túnica ou o caparazão. Cabos de lança e mastros encostados no pé são reconhecidos (linhas finas que continuam acima da túnica) e ficam no corpo. Pontas de escudo são descartadas.
2. **Esqueleto.** Cada perna tem quadril, joelho e tornozelo. A coxa fica escondida sob a túnica, a canela e o pé são peças separadas, e um **IK de 2 ossos** posiciona o joelho.
3. **Ciclo de 8 quadros:**
   - fase de apoio: o pé fica parado no chão enquanto o corpo avança, então não há deslizamento;
   - fase de balanço: o pé sobe, o joelho flexiona e a ponta do pé se inclina;
   - o quadril sobe e desce como um pêndulo invertido (a perna de apoio fica quase esticada);
   - nas vistas de frente e de costas o peso passa de um pé para o outro;
   - o tronco faz contra-rotação dos ombros. Braços, arma e escudo se movem juntos com o tronco (que é como se marcha segurando lança ou escudo); a amplitude depende do tipo (`WALK_ARM`).
   - Cavalos andam em 4 tempos (posterior, anterior, posterior, anterior), com o jarrete das patas traseiras dobrando para trás.
4. **Empacotamento.** Os 640 quadros (2 × 8 × 5 × 8) vão para página(s) de atlas próprias de 2048 px de largura (normalmente 1 página de 2048×~1900) e entram na mesma tabela de quadros do shader.

A geração é feita aos poucos (fatias de ~10 ms), sem travar a carga. Enquanto ela não termina, o jogo usa o modo antigo.

### Sistema de movimentação
- A fase do passo avança **proporcionalmente à distância andada** (`WALK.invCycle[tipo]` = ciclos por unidade do mundo, calculado a partir da passada do boneco). Por isso a animação acompanha a velocidade real: marcha, carga e fuga.
- Ao parar, o soldado termina o passo até apoiar os dois pés (`walkSettle`) e volta ao quadro parado.
- A direção desenhada vem da orientação do soldado. Em ajustes laterais curtos ele vira para onde anda; em recuos curtos ele anda de ré (o ciclo roda ao contrário).
- O golpe tem prioridade sobre a caminhada.

### Formações
- Cada soldado tem a sua própria fase. Ao começar a andar, o pé de saída e o instante do passo variam um pouco de soldado para soldado.
- Fileiras, colunas, combate e IA dos regimentos não foram alterados.

### Desempenho
- Na GPU, cada soldado continua sendo um sprite com um índice de quadro: nenhum cálculo extra por soldado.
- Os soldados são agrupados por página de atlas, com 1 desenho extra por página.
- `dirOf` deixou de alocar um array por soldado a cada quadro (`dirFace`).
- Os canvases da geração ficam na CPU (`willReadFrequently`), o que evita leituras da GPU nos celulares.

## Importar spritesheets desenhados à mão

Quadros importados substituem os gerados para a combinação time/tipo/direção indicada. Formato: uma imagem com os quadros em grade, da esquerda para a direita e de cima para baixo, começando com o pé direito à frente apoiando no chão.

```js
// antes do jogo carregar (por exemplo, num <script> antes do script principal):
window.SDG_WALK_SHEETS = [
  { team: 'blue',          // 'blue' | 'red' — se omitido, vale para os dois times
    kind: 'lanceiro',      // lanceiro, espadachim, escudeiro, arqueiro, machadeiro, piqueiro, estandarte, cavaleiro
    dir: 'side',           // front, side (olhando para a direita), back, fd (frente-direita), bd (costas-direita)
    src: 'data:image/png;base64,...',  // data: ou mesma origem (necessário para o WebGL)
    frames: 8, cols: 8,    // quadros por ciclo e colunas na grade
    fw: 96, fh: 96,        // tamanho de cada célula
    ax: 48, ay: 88,        // âncora (ponto entre os pés, no chão) dentro da célula
    stride: 14 }           // opcional: distância (unidades do mundo) andada em 1 ciclo
];

// ou com o jogo já rodando (regera as páginas):
__G.importWalkSheet({ team: 'red', kind: 'cavaleiro', dir: 'fd', src: '...', fw: 128, fh: 128, ax: 60, ay: 118 });

// exporta uma página gerada como PNG (base para redesenhar quadros):
__G.walkSheetURL(0).then(url => window.open(url));
```

As direções espelhadas (esquerda, frente-esquerda e costas-esquerda) são obtidas automaticamente por espelhamento.

## Limitações conhecidas
- Os sprites originais não têm os braços separados do tronco. Por isso os braços, a arma e o escudo se movem como uma peça só com o tronco. Um balanço livre do braço exige quadros desenhados à mão, que podem ser importados pela estrutura acima.
- Quando um escudo grande cobre uma perna (escudeiro de frente), só a perna visível é animada.
