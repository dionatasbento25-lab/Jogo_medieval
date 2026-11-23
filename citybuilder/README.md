# Reinos 3D — City Builder

City-builder em estilo *idle* construído sobre o mapa **Reinos 3D — Reinos Independentes** (61 reinos, 374 províncias, dinastias e calendário).
O jogo final é um único arquivo: `../Reinos_City_Builder.html` (abre direto no navegador, celular ou PC).

## Como jogar
1. **Escolha o seu reino**: toque numa província e em *Governar este reino*. O castelo nasce na capital e você constrói em todas as províncias do reino.
   Os outros 60 reinos têm seus castelos nas capitais e suas dinastias seguem vivendo (📜 Crônica).
2. Construa **casas** (moradores), **fazendas** (comida), **lenhadores** (madeira, perto de florestas),
   **pedreiras** e **minas** (perto de montanhas), **mercados**, **tavernas**, **poços**, **armazéns** e **torres de vigia** (segurança e felicidade).
3. Os **construtores** (camisa laranja) andam até o canteiro e martelam até a obra ficar pronta. Toque no canteiro para ajudar.
4. Toque numa construção para ver a produção e **melhorar** (até o nível 5). Cada nível muda o modelo 3D.
5. Evolua o **castelo** para liberar novas construções. Siga os **objetivos** para ganhar prêmios.
6. O jogo salva sozinho; ao voltar, você recebe parte do que o reino produziu enquanto esteve fora.

O calendário (▶/⏸ e 5 velocidades) também acelera ou pausa a cidade.

Controles: arrastar move • pinça/roda dá zoom • 2 dedos/botão direito gira • `R` gira a construção • `B` abre o menu.

## Estrutura do código
- `assets/Reinos_3D_Reinos_Independentes.html`: o mapa. O `build.py` reaproveita dele o motor (relevo, rios, províncias, fronteiras, modos de mapa, calendário e dinastias) e aplica 3 pequenos ajustes nos shaders.
- `src/extra_shaders.js`: shaders dos aldeões animados.
- `src/view.js`: árvores, câmera, sombras, desenho e laço principal.
- `src/models.js`: modelos low-poly de todas as construções (5 níveis cada) e o aldeão articulado.
- `src/game.js`: regras (economia, população, empregos, construção, rotina dos aldeões, efeitos animados).
- `src/main.js`: câmera, desenho, interface, toques, salvar/carregar.
- `assets/Reinos_3D_Continente_original.html`: primeiro mapa (não é mais usado).

Para gerar o HTML depois de editar: `python3 citybuilder/build.py`
