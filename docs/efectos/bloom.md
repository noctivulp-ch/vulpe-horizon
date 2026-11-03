# Bloom (subsistema 10)

Especificación: `../vulpe-horizon-spec/subsistemas/10-bloom.md` y `paridad/10-bloom.md`. Capturas: `imagen-atardecer.png`
(halo del sol); recorridos `bloom-fuente` (piedra luminosa en una caja oscura a 16, 8, 4, 2 y 1 bloques: `bloom-NN.png`)
y `bloom-niebla` (al aire libre de noche, la luna saliendo y una vista de día: `bloom-niebla-NN.png`, `bloom-luna.png`,
`bloom-dia.png`).

## Por qué del código

- **Sin umbral** (Jimenez 2014): se suma el desenfoque de toda la imagen con peso `0,3 × fuerza × viñeta`, la viñeta
  propia del bloom de ×1,5 en el centro a ×0,5 en las esquinas (0,45 y 0,15: `paridad/10`, medido por extracción).
  Antes era 0,08 fijo. De día aclara el centro de la imagen unos 12/255 (170 → 183 en `bloom-dia.png`, medido
  con el bloom a 0).
- **Pasada 4** (¼, `bloom`): la caja 4×4 compuesta de 13 lecturas desde `history` con el promedio de Karis
  `1/(1 + luma)` en los cinco grupos (`img_bloom_bajada`).
- **Pasada 5** (¼, `bloom2`): **anillos** concéntricos (12) con tantas lecturas bilineales por anillo que no quedan a
  más de ~2 téxeles entre sí, girados por píxel con el ruido IGN; radio 0,06 del alto y gaussiana `exp(−2,5 r²)·(1 − r²)²`,
  que llega a 0 en el borde. **Por qué (observación del dueño, 2026-11-03: al acercarse a una fuente en lo oscuro «se ve
  la dispersión como palitos en vez de crecer como una nube difusa»):** las 32 lecturas de Vogel en un radio de 1/8 del
  alto quedaban a ~10 téxeles unas de otras, y una fuente pequeña y brillante salía repetida en copias. Con 8 anillos
  aún se veían anillos tenues; con 16 era igual de liso que con 12 y costaba ~1 ms más. Cortada en `r = 1` la gaussiana
  valía aún un 8 % y dejaba un disco de borde duro. **Radio 0,06 (antes 0,125):** `paridad/10` mide un halo compacto
  (46 % de la energía en 4 px, 93 % en 32 px, 97,6 % en 0,06 del alto); el radio de 1/8 daba un halo enorme.
- **El alfa de `bloom2`** guarda la opacidad de la niebla **en las fuentes de alrededor**
  (`img_opacidad_fuentes`: media de `1 − T` del volumen pesada por la luminancia, 6 anillos). **Por qué:** el bloom de
  niebla mezclaba hacia el desenfoque según la niebla del propio píxel; de noche el fondo lejano tiene la niebla espesa y
  las hojas cercanas no, así que el halo de una fuente solo aparecía sobre el fondo y quedaba recortado por las hojas:
  un disco desplazado arriba a la derecha de la piedra luminosa (`bloom-niebla-08.png` antes del cambio). La niebla que
  dispersa la luz de una fuente es la que hay delante de ella; ahora se usa la mayor de las dos opacidades.
- **Final:** `mix(ancho, núcleo bicúbico, 0,75) · peso` sumado (el núcleo da la parte compacta del halo,
  el ancho la cola), y el bloom de niebla
  `mix(color, ancho, opacidad²)`, con la opacidad `(1 − T_volumen) · (1 + 0,5·lluvia + agua)` y apagado en el 5 %
  del borde. **Al cuadrado (desviación):** con la opacidad lineal de la especificación, la bruma de día
  (0,2–0,4) mezclaba media imagen con el desenfoque ancho y la lavaba de verde azulado; al cuadrado solo actúa la
  niebla espesa.
- Las esquinas (0,0) y (1,0) del alfa guardan la exposición (11); el rgb no se toca.

## Opciones

Fuerza del bloom (0–4, 1). Bloom de niebla y bajo el agua, constantes.
