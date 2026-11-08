# Capital do Reino — melhorias da cidade (Reinos 3D: Dinastias)

Arquivo: `Reinos_3D_Dinastias_Salvamento.html` (função `royalCapital`).

## O que mudou
- **Fosso** com água e margem em volta da muralha, com pontes de madeira nos três portões
  (some sozinho onde o chão é mar ou praia).
- **Bandeiras da casa real** nas torres de telhado de ardósia.
- **Ruas**: as ruas principais ganharam meio-fio, há uma rua circular por dentro da muralha
  e becos ligando os bairros.
- **Casas** em três estilos (enxaimel com sobrado avançado, pedra com chaminé, sobrado estreito
  de três pisos), enfileiradas ao longo das ruas com a porta virada para a rua; quintais com
  árvores no miolo dos quarteirões.
- **Praça do mercado** com piso em dois tons, chafariz de dois andares e um anel de barracas coloridas.
- **Arredores**: campos cercados com montes de feno, pomares, moinho de vento num ponto alto,
  vilarejo com hortas junto às estradas e carroças chegando aos portões.
- **Bem de perto**: janelas (algumas acesas), chaminés, mercadorias nas barracas e pessoas nas ruas.

## Desempenho (celular)
A cidade é dividida em três camadas de malha:

| camada | quando aparece | triângulos |
|---|---|---|
| principal (muralha, torres, cidadela, catedral, fosso) | sempre | ~8,0 mil (antes 7,5 mil) |
| detalhe (ruas, casas, praça, campos, moinho) | câmera a menos de 1100 | ~8,8 mil (antes 4,4 mil) |
| fina (janelas, chaminés, pessoas, barracas, feno, cercas) | a menos de 430 no celular / 560 no PC | ~5,2 mil |

No celular a camada fina não entra no mapa de sombras. A montagem da cidade leva cerca de 5 ms a mais.
