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
