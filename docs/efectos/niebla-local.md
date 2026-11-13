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
Jungla: velo verde azulado ligero. Pantano: bruma amarilla verdosa. **Desierto** (−9872, −2200, encontrado con `locate` desde −6000, 0): polvo y tormenta de arena iguales que en la sabana; la
captura del perfil «despejado» salió antes de cargar la zona (mar y lluvia). **Sin ver:** cruzar andando la frontera de un bioma
(salto brusco esperado, ver límites) y el jardín pálido (sin mod).

## Fundido del clima (F-43, 2026-11-12)

Observaciones del dueño 1.1 y 1.2: la tormenta de arena o de nieve a veces no salía al poner la lluvia estando dentro
del bioma, y faltaban transiciones.

- **Lo que se vio:** en `pruebas/escenas/tormenta-desierto.ctl` (lluvia puesta dentro del desierto, tres días) la
  tormenta sí sale cuando la cámara está de verdad en el desierto (el primer día la zona aún no estaba cargada y la
  cámara estaba sobre el océano: sin efecto, como debe). Pero el tipo de clima (calor o frío) se decidía con la
  temperatura del bioma **en ese instante** y la fuerza con `frame.rain` y una rampa de 0,3: entrar con lluvia era un
  salto, y empezar a llover dentro, una rampa corta. El orden importaba. Además, uno de cada tres días el perfil es
  «nada» (`21`): eso no es un fallo, pero puede parecerlo.
- **Arreglo:** el tipo de clima y su peso se guardan entre fotogramas en el téxel (6,0) de bloom2 como `tipo·2 + peso`
  (`adp_clima_local_estado`, `adaptadores/marco.wgsl`; lo escribe la pasada de bajada del bloom). Objetivo: tipo por
  temperatura y precipitación, peso = `frame.rain`. El peso va hacia el objetivo a 1/4 por segundo
  (`OPC_LOCAL_FUNDIDO` = 4 s, lo mismo que el mod para el bioma); si el tipo cambia, primero baja el anterior a 0. Da
  igual qué cambie antes, la lluvia o el bioma: el resultado tras el fundido es el mismo.
- **El mod:** no necesitaba cambio. Manda el bioma desde el primer fotograma en que lo lee (su bandera se enciende en
  cuanto `native_biome` responde), y su peso sube en 4 s.
- **Comprobado** (`pruebas/escenas/tormenta-fundido.ctl`): lluvia puesta dentro del desierto, tormenta creciendo de 1 a
  6 s; entrar con lluvia desde fuera, paisaje aún visible a 0,5 s y tormenta a los 2 s. La tormenta de arena es tan densa
  que con poco peso ya tapa: el fundido se nota más en el polvo.

## Color de las tormentas en la imagen (F-52, 2026-11-13)

`subsistemas/28` §5: la ventisca tiene que salir gris neutro y la tormenta de arena dorada con saturación ~0,5 (matiz
~40°); de noche, las dos casi negras.

- **Por qué salían mal:** la luz que dispersa la niebla local se tiñe con el color propio de `21` y se apaga con una
  extinción gris (el raymarch lleva una sola transmitancia). Con (2,0; 0,6; 0,2) la arena salía naranja rojiza (98,42,13
  de fondo, matiz ~20°) y con (2; 3; 5) la ventisca, azul (77,99,127). En el original esos colores acaban más neutros en
  la imagen (si la extinción es por canal, a mucha profundidad la luz dispersada vuelve al color de la luz), pero el
  pack no tiene transmitancia por canal.
- **Arreglo:** el tono de la niebla local en la imagen sale de la carta medida (`OPC_LOCAL_CALOR_TINTE`: 197,168,97 en
  lineal normalizado a luminancia 1; `OPC_LOCAL_FRIO_TINTE`: gris neutro) y el color de `21` aporta su luminancia (el
  brillo), por `OPC_LOCAL_BRILLO_CALOR` = 11 y `OPC_LOCAL_BRILLO_FRIO` = 2,3, ajustados a la carta. Las densidades de
  `21` no cambian.
- **Medido** (`pruebas/escenas/carta-tormentas.ctl`, cubo blanco a Y 100, elevación del sol 0°, perfil de tormenta del día):

  | Escena | Zona | Antes | Ahora | Original |
  |---|---|---|---|---|
  | Arena | fondo | 98,42,13 | 154,136,73 | 197,168,97 |
  | Arena | cara del cubo | 75,32,17 | 138,116,52 | 179,147,78 |
  | Arena | cielo a través | 151,77,30 | 208,190,117 | 194,164,95 |
  | Ventisca | fondo | 77,99,127 | 126,126,126 | 142,142,143 |
  | Ventisca | cara del cubo | 50,69,97 | 97,98,99 | 120,122,123 |
  | Ventisca | cielo a través | 123,149,180 | 180,180,180 | 137,138,141 |
  | Arena y ventisca, medianoche | toda la imagen | casi negro | casi negro | casi negro |

  El tono cuadra (gris con diferencia entre canales ≤ 3; arena con matiz ~45°). Los niveles quedan dentro de ±60: la
  densidad cerca del cubo y la del fondo no se reparten igual que en el original. El polvo (perfil 1) toma el mismo
  tono dorado.
