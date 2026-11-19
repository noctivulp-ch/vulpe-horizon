# Suelo con el clima según el bioma (N-02)

En los biomas donde llueve, el suelo se moja y forma charcos (`nucleo/superficie/humedad.wgsl`). Antes de F-69 esa rama
no comprobaba la precipitación del bioma, así que los biomas nevados y desérticos también se oscurecían y sacaban
charcos cuando `frame.wetness > 0`.

Desde F-69 (observaciones del dueño 2026-11-13 §5.3), el comportamiento del suelo con el clima depende del bioma:

| Bioma (`adp_clima_local_objetivo`) | Condición | Efecto en el suelo |
|---|---|---|
| Lluvioso (`tipo == 0`, `precipitation == 1`) | `frame.wetness > 0` | Mojado y charcos (`sup_humedad`) |
| Nevado (`tipo == 2`: `temperature < 0,4` y `precipitation == 2`) | `frame.rain > 0` | Escarcha sutil con motas cristalinas (`sup_escarcha`), sin charcos ni oscurecimiento |
| Desértico (`tipo == 1`: `temperature > 1,0` y `precipitation == 0`) | `frame.rain > 0` y material arena (`OPC_MAT_ARENA`) | Granos movidos por el viento (`sup_arena_viento`), sin charcos |
| Seco no cálido (`precipitation == 0`, `tipo == 0`) | — | Sin efecto (ni charcos ni mojado) |

## Escarcha

Archivo puro: [`nucleo/superficie/escarcha.wgsl`](../../nucleo/superficie/escarcha.wgsl).

- **Dónde:** caras superiores (`normal_cara.y > 0,9`) expuestas al cielo (`smoothstep(0,82; 0,92; cielo + borde)`), igual
  que el mojado, para que no aparezca bajo techos ni en cuevas.
- **Velo claro y frío:** un aclarado sutil hacia `OPC_ESCARCHA_COLOR` (azul pálido en lineal) modulado con ruido suave de
  baja frecuencia, para evitar una capa uniforme.
- **Motas cristalinas en la rejilla de 32:** se cuantizan las coordenadas horizontales del mundo a `OPC_SUELO_REJILLA = 32`
  texeles por bloque (`27` §«Detalle: 32 texeles por bloque»). Un hash 3D (`rui_hash33`) decide qué ~13 % de celdas
  tienen mota cristalina y asigna a cada una una microfaceta inclinada (`OPC_ESCARCHA_INCLINACION`).
- **Destellos especulares en movimiento:** cada microfaceta evalúa el vector medio tanto con la dirección del astro como
  con el cenit del cielo (para que brillen también en nevadas cubiertas donde la luz directa es baja). Al girar o mover
  la cámara, las motas que alinean su microfaceta con la vista centellean con la luz real recibida en ese punto
  (directa + cielo + luz de bloque), por lo que nunca brillan en la oscuridad.
- **Atenuación por distancia:** las motas y destellos se atenúan suavemente entre `OPC_ESCARCHA_DIST_INICIO` (20 bloques)
  y `OPC_ESCARCHA_DIST_FIN` (52 bloques) para evitar aliasing subpíxel en el terreno lejano.

## Arena

Archivo puro: [`nucleo/superficie/arena_viento.wgsl`](../../nucleo/superficie/arena_viento.wgsl).

- **Dónde:** solo en las caras superiores (`normal_cara.y > 0,9`) de bloques de arena (`OPC_MAT_ARENA`: `block/sand`,
  `block/red_sand`, `block/suspicious_sand*`, id 10 en `horizon-shaders.toml`), expuestas al cielo.
- **Rejilla de 32 y dirección del viento:** las coordenadas del mundo se cuantizan a 32 texeles por bloque y se proyectan
  sobre la dirección unitaria del viento del pack (`normalize(OPC_VIENTO)`) y su perpendicular (`u`, `v` en texeles de 32).
- **Ondulaciones finas de 3 a 6 texeles:** una onda sinusoidal a lo largo del viento (`u_mov / OPC_ARENA_ANCHO`,
  espaciado medio de `4,5` texeles) modulada por un meandro suave (`OPC_ARENA_MEANDRO_AMP`) que varía localmente la
  separación entre ~3 y ~6 texeles, y envuelta por bancos de granos alargados en la dirección del viento
  (`OPC_ARENA_LARGO = 14` texeles). La fase usa `fract(...) * MAT_TAU` para mantener precisión exacta lejos del origen
  (p. ej. `x = -9872`).
- **Desplazamiento y nivel de tormenta:** las vetas y el meandro se desplazan despacio a favor del viento
  (`u_mov = u - tiempo * vel`). Tanto la velocidad (`OPC_ARENA_VELOCIDAD_MIN..MAX`) como la fuerza
  (`OPC_ARENA_NIVEL_MIN..MAX`) crecen con el nivel de tormenta del día (`adp_tormenta_nivel`, compartido en
  `adaptadores/marco.wgsl` desde F-64b: niveles 1–5 con lluvia, 6–10 con tormenta eléctrica).
- **Color y relieve:** modula el albedo de forma multiplicativa (conserva tanto la arena amarilla como la roja de las
  mesas) e inclina suavemente la normal (`OPC_ARENA_RELIEVE`) para que las crestas recojan la luz, sin añadir brillo
  especular ni charcos.

## Fundido y constantes

- **Fundido:** ambos efectos usan `adp_clima_local_objetivo().peso` (`frame.rain`), que sube y baja de forma continua en
  unos segundos al empezar o parar el clima, igual que el resto de efectos climáticos. En `material` no existe textura
  de historial de post (`bloom2`), por lo que el cruce de frontera de bioma sigue la temperatura y precipitación de
  `frame`.
- **Constantes:** todas están agrupadas con nombre en [`opciones/suelo_clima.wgsl`](../../opciones/suelo_clima.wgsl).
  Sin opciones nuevas en el menú (el pack sigue en 64/64). Respeta la opción existente `charcos` (con «Apagado» se
  desactivan también escarcha y arena).

## Coste

Cero lecturas de textura nuevas (`material` sigue en 17/64). Con cielo despejado (`frame.rain == 0` y
`frame.wetness == 0`) el coste es nulo por salida temprana; en nieve o desierto con tormenta, solo corre en caras
superiores expuestas con 1–2 evaluaciones de ruido procedural.
