# Reinos 3D — versão Godot 4 (celular)

Porte do city builder web (`../Reinos_City_Builder.html`) para o **Godot 4.3**, usando o
renderizador **Compatibility** (OpenGL ES 3), que roda na maioria dos celulares Android.

Tudo o que existe na versão web está aqui:
- mapa dos **61 reinos independentes** (374 províncias, rios, estreitos, regiões, modos de mapa Terreno/Províncias/Reinos/Regiões);
- **calendário** com pausa e 5 velocidades, e **dinastias** (reis, herdeiros, casamentos, nascimentos, mortes, crônica);
- **city builder**: escolha do reino, castelo na capital, 11 construções com 5 níveis cada, aldeões animados
  com profissões, economia, felicidade, armazéns, objetivos, ganhos enquanto você está fora e salvamento automático.

## Como abrir
1. Instale o Godot **4.3** (ou mais novo, da série 4.x): https://godotengine.org/download
2. No Godot, *Importar* → escolha `godot/project.godot`.
3. Aperte ▶ (F5) para jogar no computador.

## Gerar o APK para Android
1. No Godot: *Editor → Gerenciar modelos de exportação* → baixar os modelos da sua versão.
2. *Editor → Configurações do editor → Exportar → Android*: informe o caminho do Java (JDK 17) e do Android SDK
   (o Godot explica como, em https://docs.godotengine.org/pt-br/4.x/tutorials/export/exporting_for_android.html).
3. *Projeto → Exportar* → preset **Android** (já vem configurado: horizontal, tela cheia, arm64) → *Exportar projeto*.

## Estrutura
- `scripts/world.gd` — dados do mapa (relevo, biomas, províncias, rios, reinos) e consultas.
- `scripts/models.gd` — modelos 3D low-poly de todas as construções, árvores e do aldeão articulado.
- `scripts/game.gd` — regras: economia, construção, população, empregos, rotina dos aldeões, salvar/carregar.
- `scripts/dyn.gd` — calendário e dinastias dos 61 reinos.
- `scripts/main.gd` — cena 3D: terreno em blocos, água, árvores e aldeões instanciados, câmera e gestos.
- `scripts/ui.gd` — interface (recursos, objetivos, menus, painéis, ficha do reino, crônica).
- `shaders/` — terreno (fronteiras, rios, neve, grade), água, construções, árvores e aldeões animados.
- `data/` — gerado por `tools/export_assets.py` a partir do HTML do mapa (relevo, províncias, texturas pré-calculadas).

Se o mapa mudar, rode `python3 godot/tools/export_assets.py caminho/do/mapa.html` para atualizar `data/`.

Teste automático (gera capturas de tela): `godot --path godot -- --autotest --out=/pasta/de/saida`
