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
