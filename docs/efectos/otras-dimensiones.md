# Nether y End (subsistema 17)

Especificación: `../vulpe-horizon-spec/subsistemas/17-otras-dimensiones.md` (fase 2, falta 17.1 de la revisión de A).
Capturas: `pruebas/capturas/nether-*.png`, `end-*.png` y `hoja-dimensiones.png` (las cinco primeras con el aislamiento
de color apagado para ver los colores; la última, el End con el aislamiento encendido, como sale por defecto).

## Por qué del código

- **Qué se apaga fuera del Overworld** (`adp_es_superficie`, `frame.dimension == 0`): el factor de noche (y con él
  el fractal del cielo, la aurora y los rayos), el raymarch del 05 entero (nubes, horario, aire, sombras de nubes),
  la sombra del mapa y la difusa del sol en el material, la humedad, la niebla de borde y el **efecto Purkinje**
  (con la escena oscura teñía todo el Nether de azul grisáceo).
- **Exposición previa fija por dimensión** (`adp_codificacion`): 2^6 en el Nether y 2^6,5 en el End; la automática
  corrige encima.
- **Luz de superficie** (`adp_luces`): sin sol ni cielo, un ambiente propio que no depende de la luz de cielo de
  Minecraft (que allí vale 0): en el Nether el color de `frame.fog_color` (la niebla de vanilla del bioma)
  normalizado, ×0,0035, hemisférico con más luz desde abajo (×1,4 abajo, ×0,6 arriba, la lava); en el End, azul
  pálido ×0,002. En la escala de la luz de bloque del 03 (0,012 junto a una antorcha).
- **Niebla del Nether** (`nucleo/volumen/dimensiones.wgsl`, `vol_nether`): 12 pasos exponenciales hasta 192 bloques,
  con la integración del 05. Columnas de humo: un fondo que crece hacia el techo menos columnas de ruido 2D de 900
  bloques torcido con la altura, erosionado por ruido 3D que sube con el tiempo; una capa densa a ras del mar de lava
  (Y 31) abierta a menos de ~24 bloques de la cámara; humo de techo por encima de Y 40, saturado en Y 90; aire limpio
  a menos de 6–24 bloques del jugador. Luz del humo anaranjada desde abajo, que se apaga dentro de lo denso; bruma del
  color del bioma que añade luz sin restar transmitancia.
- **Niebla del End** (`vol_end`): ruido 3D que gira alrededor del eje del origen (más rápido cerca del centro),
  recortado a un toro de radio 150 bloques a Y 60 y hueco en una esfera de ~75 bloques sobre la isla central; la
  niebla del vacío por debajo de Y −20. Luz de un vórtice frío sobre el centro (Y 200) y de destellos magenta
  sorteados cada 4 s con un hash del tiempo (subida rápida, caída exponencial). Sin sombra propia hacia las fuentes
  (la especificación pide 2–3 muestras; simplificación).

## Opciones

Niebla del Nether y del End (0–2, 1), en la página «Niebla y nubes». Van 51.

## Visto y no visto

- **Visto (Nether):** en el bosque carmesí, un ambiente rojo que deja ver el terreno lejos de la luz y una bruma
  roja; sobre el mar de lava, humo anaranjado iluminado desde abajo; en el valle de almas, ambiente verde azulado
  (el `fog_color` del bioma).
- **Visto (End):** la isla con su ambiente y una niebla gris violácea entre las torres de obsidiana.
- **No visto:** las columnas de humo como formas verticales claras (el humo sale más como bruma), los destellos
  magenta del End (no coincidió ninguno con la captura), la niebla del vacío, los deltas de basalto.

## Niebla del Nether (F-47, 2026-11-12)

Observación del dueño 6.1: la niebla estaba demasiado baja, pegada a los lagos de lava.

- **Antes:** el humo crecía desde la lava hacia arriba (fondo de 0,15 a 0,6 entre Y 31 y 110), la capa sobre la lava
  caía a una décima en ~18 bloques y su luz era tan baja (0,004 de la lava) que, con la exposición puesta por la lava
  emisiva, solo se veía el brillo pegado a los lagos.
- **Ahora** (`vol_nether_densidad`, `nucleo/volumen/dimensiones.wgsl`): densidad máxima de las columnas por altura con la
  tabla de la observación (0 en Y 31, 0,07 en 35, … 0,27 en 70, … 0 en 95), recortada por el ruido de columnas
  (inclinado por el viento con la altura) y la erosión 3D; capa sobre la lava `exp(−(y − 31)/1,74)` (una décima en 4
  bloques), despejada en ~24 bloques alrededor de la cámara; humo del techo de Y 40 a 90 como antes. Relación capa :
  pico de la banda = 1 : 0,27, escalada por `VOL_NETHER_ESCALA` = 2,5.
- **Luz:** naranja cálido fijo de la lava (sin caída con la altura) más la bruma del color de la niebla del bioma
  (`frame.fog_color` normalizado, ya estaba), todo × `VOL_NETHER_LUZ` = 10, la misma subida que el ambiente del Nether en
  F-45: sin ella la niebla no se ve contra la lava.
- **Comprobado** (`pruebas/escenas/nether-niebla.ctl`; `pruebas/capturas/nether-niebla-70-antes.png` → `-70.png`): una
  bruma rojiza a media altura vela las paredes lejanas; la capa sobre la lava es fina.

## Tormenta del End (F-49, 2026-11-12)

Observación del dueño 6.2: la espiral no parecía bien hecha. Rehecha según `formas/otras-dimensiones.md` §End
(`vol_end_densidad` y `vol_end`, `nucleo/volumen/dimensiones.wgsl`).

- **Antes:** un toro de niebla de radio 150 como campo de densidad, con giro diferencial por radio y un hueco cilíndrico;
  12 pasos hasta 320 bloques.
- **Ahora:**
  - Bancos del canal A del ruido 3D (mosaico de 1 200 × 4 000 bloques: grano de ~300 en horizontal y lento en vertical)
    donde el ruido es bajo; fuera de la zona del vórtice (250–350 bloques del eje) la curva es más abrupta y los bancos
    el doble de densos. Erosión fina (canal G, grano ~30) que resta hasta un 30 % y se desliza despacio.
  - La espiral: la coordenada del ruido gira alrededor del eje vertical una vuelta cada 450 bloques de altura y una cada
    5 minutos, apagándose de 200 a 400 bloques de (0, 100, 0).
  - Huecos restados: esfera algo achatada de 75 bloques en (0, 100, 0) y anillo horizontal a 150 bloques del eje (limpio
    en 12, cerrado a 85).
  - Niebla del vacío: total bajo Y −60, ~11 % a −50, ~1 % a −20. Claro alrededor de la cámara: 0 a 0 bloques, total a
    100, al cuadrado.
  - Luces: vórtice azul frío (0,3; 0,5; 1) fijo en (0, 200, 0) para lo que está a menos de ~300 bloques del origen;
    relámpago magenta (1; 0; 0,5) en una celda de 200 bloques alrededor de la cámara para lo de más lejos (salta cada
    1,5 s, el 40 % de los ciclos encendido, sube en 0,5 s y baja en 1). Caída `exp(−d/25,4)` (14 % a 50, 2 % a 100).
    Sombra de la niebla hacia el vórtice con una toma más, que apaga y tiñe (luz más saturada dentro de lo denso);
    ambiente azul muy tenue solo en los bordes; bruma azulada que solo suma, más clara mirando arriba.
  - 16 pasos hasta 384 bloques.
- **Diferencias con la descripción:** la sombra hacia el foco usa dos tomas, no tres; el relámpago salta por ciclos fijos
  de 1,5 s (el original sortea cada fotograma, sin memoria en el pack); el punto no «avanza a tirones».
- **Vistas aisladas:** `OPC_DEPURACION_VISTA_DEFECTO` 15 (densidad a Y 60, 800 × 800 bloques alrededor del origen) y
  16 (corte por z = 0, Y de −80 a 300). Capturas `pruebas/capturas/forma-end-planta.png` y `forma-end-corte.png`
  (escena `forma-end.ctl`): brazos de espiral alrededor de la isla y bancos grandes fuera; en el corte, la niebla del
  vacío y el hueco de la isla.

## Luz de la tormenta (F-56, 2026-11-13)

Comparado con `vulpe-horizon-spec/referencias/original-dimensiones/` (mismo mundo, mismas cámaras;
`pruebas/escenas/dimensiones-referencias.ctl`). En el original, la tormenta del End es un vórtice luminoso: núcleo
blanco azulado sobre la isla y bancos azules iluminados en todo el encuadre. En el pack casi no se veía (media de la
imagen 5,7,9 contra 66,93,120): el foco del vórtice valía 0,03 con la caída de la spec (14 % a 50 bloques, 2 % a 100),
así que solo llegaba luz a lo que estaba a pocas decenas de bloques de (0, 200, 0), y casi todo eso es el hueco.

Probado:

| luz del vórtice | media vórtice / arriba / suelo | qué se ve |
|---|---|---|
| antes: 0,03 · caída 25,4 | 5,7,9 / 0,1,4 / 5,6,5 | negro, un punto azul |
| 1,0 · caída 25,4 | 15,24,42 / 9,16,34 / 4,6,8 | una mancha alrededor del vórtice; los bancos, a oscuras |
| 0,3 · caída 100 | 43,68,116 / 43,64,113 / 23,34,53 | bancos iluminados, sin núcleo |
| **3,0 · caída 25,4 + 0,25 · caída 100** | **48,73,118 / 42,67,113 / 22,33,52** | núcleo blanco y bancos iluminados |
| original | 66,93,120 / 68,96,125 / 43,64,89 | |

Se queda con dos términos (`VOL_END_LUZ_NUCLEO`, `VOL_END_LUZ_ANCHA`, `VOL_END_CAIDA_ANCHA` en
`nucleo/volumen/dimensiones.wgsl`): el foco de la spec, con su caída, para el núcleo, y uno ancho para los bancos. La
caída de la spec sola no puede dar a la vez el núcleo y los bancos lejanos que se ven en la referencia. La duda va a
`docs/preguntas-para-A.md`: puede que la caída esté medida en el espacio aplastado, como el giro (una vuelta cada
9 bloques ahí, 450 en el mundo).

**Lo que queda, que es de forma** (se compara con la vista aislada, no con medias): los bancos del original tienen
bordes blancos y grietas oscuras, con mucho contraste; los del pack salen como una bruma lisa. Es la sombra de la
propia niebla (la spec pide 3 muestras hacia el foco; el pack toma una) y el tamaño de los bancos. La isla del original
sale clara, de color piedra; la del pack, azulada y más oscura (22,33,52 contra 43,64,89 en `end-suelo`).

## Humo del Nether (F-57, 2026-11-13)

Comparado con `referencias/original-dimensiones/` (mismas cámaras, `pruebas/escenas/dimensiones-referencias.ctl`) y
con una vista aislada nueva, `OPC_VISTA_FORMA_DIMENSION` = 17 (`opciones/depuracion.wgsl`): la opacidad de la niebla
del volumen (1 − transmitancia) en gris, sin la escena, la misma que las `*-forma` del original.

- **Opacidad:** parecida en cantidad a la del original (`nether-yermo-forma`, `nether-carmesi-forma`), pero lisa donde
  el original tiene grumos. El ruido de columnas tenía un grano de ~140 bloques (canal r de `ruido2d`, semiancho de
  autocorrelación de 20 texeles de 256, con mosaico de 900 bloques); la spec (`formas/otras-dimensiones.md` §«La forma
  del humo») pide columnas de ~20 bloques separadas ~40. `VOL_NETHER_MOSAICO_COLUMNAS` = 128 da un semiancho de ~10.
  Antes/después a Y 70 mirando horizontal, en la vista 17: `pruebas/capturas/nether-columnas-900.png` → `-128.png`.
- **Apagado de la luz dentro del humo:** la spec da el 22 % con densidad 0,1 y el 1 % con 0,3, es decir exp(−15·d). El
  código hacía exp(−1,5 · 2,5·d) = exp(−3,75·d), cuatro veces más suave (interior encendido, sin «borde naranja,
  interior oscuro»). `VOL_NETHER_APAGADO` = 6 sobre la densidad escalada = exp(−15·d).
- **Luz del humo ×3:** probada, sin cambio medible en las cuatro vistas. Se queda en 0,004.

Medias de la imagen (original / pack, sin cambio apreciable con F-57 en estas vistas): yermo 94,42,31 / 80,25,11;
suelo 114,48,27 / 95,34,10; valle de almas 70,57,51 / 37,38,32; deltas 91,60,46 / 72,38,31; carmesí 94,12,13 /
83,5,2; distorsionado 107,50,49 / 83,29,28.

**Lo que queda:**

- **Grumos de humo sobre el lago de lava.** En el original hay masas densas de humo pardo anaranjado de 10–30 bloques
  de alto pegadas a la lava, que tapan buena parte del lago. En el pack la lava se ve limpia: la tabla de alturas de
  F-47 (observación del dueño 6.1) deja casi nada entre Y 31 y 50, y la capa sobre la lava solo tiene ~4 bloques. Las
  cámaras de las referencias miran ahí, por eso F-57 no cambia sus medias. Pregunta para A en `docs/preguntas-para-A.md`.
- **Todo el Nether, más saturado y algo más oscuro** que el original (el verde y el azul, a la mitad): el humo y la
  bruma del original lo agrisan. Va con lo anterior.
