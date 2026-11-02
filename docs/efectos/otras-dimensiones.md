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
