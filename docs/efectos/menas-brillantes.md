# Menas brillantes (subsistema 12, PROPIO)

Especificación: `../vulpe-horizon-spec/subsistemas/12-menas-brillantes.md`. Capturas: `pruebas/capturas/menas-*.png` y
`hoja-menas.png` (escena `pruebas/escenas/menas.ctl`: una pared con 16 menas en una caja de piedra sin luz).

## Por qué del código

- **Qué bloques:** `[[materials]]` id 7 con `block/*_ore` y `block/gilded_blackstone` (los restos ancestrales no
  casan con el patrón).
- **Qué téxeles** (`nucleo/superficie/menas.wgsl`, la regla de Vulpe tal cual la especificación): 16 muestras del
  mismo sprite en una rejilla de 4×4, la roca conocida con más muestras parecidas en croma (< 0,04; seis rocas:
  piedra, netherrack, piedra negra, del End, arenisca roja, arenisca), dos pasadas de media con pesos de Cauchy
  para quedarse con el color mayoritario, diferencia de croma + 0,1 de luminancia contra un umbral de 0,06, y la
  regla del carbón (mucho más oscuro que la roca gris) con el albedo aclarado a 0,3 donde actúa.
- **Las muestras** (`adp_mena`): `block_texture_level(uv, 0)` con `uv` en el espacio del sprite (0..1). Horizon guarda
  cada sprite en su propia capa (el ayudante lee una capa): a mip 0 no hay mezcla con los vecinos del atlas, la
  advertencia de la especificación no aplica. Comprobado en `crates/horizon-shader-api/src/stages.rs`.
- **Emisión:** `min(máscara · intensidad, 0,99)` por el camino de emisión de 03; manda la mayor entre la de las menas
  y la de los téxeles brillantes.

## Opciones

Menas brillantes sí/no e intensidad (60 %), en la página «Luz». Sensibilidad y carbón, constantes. Van 43.

## Coste

16 lecturas solo en los píxeles de menas (el `if` sobre el id es uniforme por bloque).

## Visto y no visto

- **Visto** en la oscuridad: carbón (gris), hierro (beige), oro, diamante, redstone, lapislázuli, esmeralda y cobre
  de piedra y de pizarra profunda, cuarzo y oro del Nether y piedra negra dorada; solo brilla el mineral, con su
  color, y la roca queda a cero; de lejos se siguen distinguiendo las vetas.
- **De día al aire libre** (`menas-dia.png`): el brillo apenas se nota, como pide la especificación (la emisión es
  moderada); con el aislamiento de color encendido las menas salen en gris como todo lo demás.
- **No visto:** menas de mods.

## Halo (F-46, 2026-11-12)

Observación del dueño 2.3: solo brillaban los píxeles del mineral; faltaba la luz tenue sobre la piedra de alrededor.

- En el original la mena no es fuente de luz: el halo lo pone el **bloom** de su emisión. En el pack la emisión de una
  mena era `albedo × OPC_EMISION × 4` = 0,2 × albedo en lineal: en una cueva oscura el píxel no pasaba de lo que el
  tonemap deja ver y el bloom (peso 0,3) apenas tenía qué derramar.
- **Arreglo:** la emisión de las menas lleva su propio multiplicador `OPC_MENAS_BRILLO` = 6 (`opciones/menas.wgsl`),
  aplicado como `brillo_emision` en la etapa material. El tonemap comprime el píxel (el mineral no se quema) y el exceso
  sale como halo en el bloom. No hay luz de bloque nueva.
- **Comprobado** (`pruebas/escenas/menas-halo.ctl`, caja de piedra a oscuras, menas a 5 bloques): cada veta tiene un
  halo de su color de algo menos de medio bloque; antes, ninguno. El objetivo del dueño era medio bloque a un bloque:
  si lo quiere más ancho, subir `OPC_MENAS_BRILLO` (a partir de ~10 el diamante empieza a blanquear).
