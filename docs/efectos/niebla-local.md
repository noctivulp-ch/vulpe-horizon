# Niebla local de bioma y de clima (subsistema 21)

Especificación: `../vulpe-horizon-spec/subsistemas/21-niebla-local-de-bioma.md`. Escena: `pruebas/escenas/niebla-local.ctl`.

## Qué hay (F-28, 2026-11-12)

- **Medio** (`vol_niebla_local`, `nucleo/volumen/medios.wgsl`): densidad uniforme + manchas, **sin** elevar al cubo. Las
  manchas usan el canal A de `ruido3d` en celdas de 48 × 12 bloques (más finas que las de la niebla global y aplastadas en
  vertical, `VOL_LOCAL_ESCALA`, sin medir), se mueven con el viento y bajan 0,3 bloques por segundo, y solo cuenta el ruido
  por encima de 0,2 (huecos limpios).
- **En el raymarch** (`vol_tramo_niebla`): solo hasta **64 bloques** (`OPC_LOCAL_ALCANCE`); su luz es el **color del
  perfil por la luminancia** de la directa (con la fase de la niebla y la sombra) y de la ambiente (con la fase de cielo).
  Se corta en la primera nube como la global.
- **Con un perfil activo la niebla global se apaga** (`1 − peso`): no se suman.
- **Elección** (`adp_niebla_local`, por el bioma de la cámara):
  - **Calor** (temperatura > 1, sin precipitación, lloviendo): despejado / polvo / tormenta de arena.
  - **Frío** (temperatura < 0,4, nieve, nevando): nevada ligera / tormenta de nieve / ventisca.
  - Uno de los tres por día (`día % 3`). **Sin el mod el día es 0**: siempre el primero (despejado y nevada ligera).
  - **Pantano, jungla, jardín pálido**, siempre: la categoría la da el mod en `mods[1].w` (1, 2, 3). Sin él, por los
    valores públicos de vanilla: pantano y manglar con temperatura 0,8 y humedad 0,9; junglas con 0,95 y 0,8–0,9. El
    jardín pálido no se distingue del bosque sin el mod: se queda sin perfil.
- Perfiles por defecto (del inventario de 21) como constantes `OPC_LOCAL_*` en `opciones/volumen.wgsl`. Fuera la
  «tormenta de nieve» propia que había (densidad global ×0,8 y ambiente ×8 con `precipitation == 2`).

## Límites

- **Sin suavizado temporal:** el pack no guarda estado del clima; los perfiles de clima entran con la fuerza de la lluvia
  (enteros a 0,3, `OPC_LOCAL_RAMPA_LLUVIA`) y los de bioma de golpe al cruzar la frontera. Lo arreglaría que el mod
  entregue la categoría y un peso ya suavizados.
- El rayo de la niebla tiene 6 pasos exponenciales sobre todo su alcance: en los 64 bloques de la local caen 2 o 3.

## Visto (2026-11-12, aislamiento a 0, forzando el perfil del día sin commitear)

Sabana con lluvia: despejado (nada), polvo naranja y tormenta de arena rojo anaranjado que tapa todo a pocas decenas de
bloques. Llanura nevada: nevada ligera (velo azul claro), tormenta y ventisca blancas y luminosas (la escena se aclara).
Jungla: velo verde azulado ligero. Pantano: bruma amarilla verdosa. **Sin ver:** cruzar andando la frontera de un bioma
(salto brusco esperado, ver límites) y el jardín pálido (sin mod).
