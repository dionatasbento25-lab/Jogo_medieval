# Reinos 3D — City Builder

City-builder em estilo *idle* construído sobre o mapa **Reinos 3D — O Continente**.
O jogo final é um único arquivo: `../Reinos_City_Builder.html` (abre direto no navegador, celular ou PC).

## Como jogar
1. **Funde o castelo** em qualquer lugar do continente. Ele define as fronteiras (linha dourada).
2. Construa **casas** (moradores), **fazendas** (comida), **lenhadores** (madeira, perto de florestas),
   **pedreiras** e **minas** (perto de montanhas), **mercados**, **tavernas**, **poços**, **armazéns** e **torres** (expandem o território).
3. Os **construtores** (camisa laranja) andam até o canteiro e martelam até a obra ficar pronta. Toque no canteiro para ajudar.
4. Toque numa construção para ver a produção e **melhorar** (até o nível 5). Cada nível muda o modelo 3D.
5. Evolua o **castelo** para liberar novas construções. Siga os **objetivos** para ganhar prêmios.
6. O jogo salva sozinho; ao voltar, você recebe parte do que o reino produziu enquanto esteve fora.

Controles: arrastar move • pinça/roda dá zoom • 2 dedos/botão direito gira • `R` gira a construção • `B` abre o menu.

## Estrutura do código
- `src/engine.js`: motor WebGL do mapa (terreno, água, sombras) + shaders novos (território, grade, aldeões animados).
- `src/models.js`: modelos low-poly de todas as construções (5 níveis cada) e o aldeão articulado.
- `src/game.js`: regras (economia, população, empregos, construção, rotina dos aldeões, efeitos animados).
- `src/main.js`: câmera, desenho, interface, toques, salvar/carregar.
- `assets/map_data.js`: relevo e cores do mapa original (base64). `assets/Reinos_3D_Continente_original.html`: mapa original.

Para gerar o HTML depois de editar: `python3 citybuilder/build.py`
