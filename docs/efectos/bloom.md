# Bloom (subsistema 10)

Especificación: `../vulpe-horizon-spec/subsistemas/10-bloom.md`. Capturas: `imagen-atardecer.png` (halo del sol).

## Por qué del código

- **Sin umbral, conservando la energía** (Jimenez 2014): se mezcla una fracción pequeña (0,08 × la opción) de la
  imagen desenfocada sobre toda la imagen.
- **Pasada 4** (¼, `bloom`): la caja 4×4 compuesta de 13 lecturas desde `history` con el promedio de Karis
  `1/(1 + luma)` en los cinco grupos (`img_bloom_bajada`).
- **Pasada 5** (¼, `bloom2`): 32 lecturas en un disco de Vogel fijo de radio 1/8 del alto, pesos gaussianos.
- **Final:** `(núcleo bicúbico de bloom + ancho · 0,5)/1,5 · fuerza` sumado, y el bloom de niebla
  `mix(color, ancho, opacidad²)`, con la opacidad `(1 − T_volumen) · (1 + 0,5·lluvia + agua)` y apagado en el 5 %
  del borde. **Al cuadrado (desviación):** con la opacidad lineal de la especificación, la bruma de día
  (0,2–0,4) mezclaba media imagen con el desenfoque ancho y la lavaba de verde azulado; al cuadrado solo actúa la
  niebla espesa.
- Las esquinas (0,0) y (1,0) del alfa guardan la exposición (11); el rgb no se toca.

## Opciones

Fuerza del bloom (0–4, 1). Bloom de niebla y bajo el agua, constantes.
