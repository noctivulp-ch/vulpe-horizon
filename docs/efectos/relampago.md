# Relámpago y luz en la mano (subsistema 20)

Especificación: `vulpe-horizon-spec/subsistemas/20-luces-dinamicas.md`. Código: `nucleo/luz/relampago.wgsl` (puro),
`adp_relampago()` en `adaptadores/mod.wgsl`, la suma en `etapas/material.wgsl` y en `nucleo/volumen/raymarch.wgsl`;
constantes `OPC_RELAMPAGO_*` en `opciones/luz.wgsl`.

## Relámpago

Entrada: el mod nativo (`mods[2]`: posición del último rayo relativa a la cámara y su edad en segundos; bandera bit 1).
Sin mod no hay posición y no hay luz de rayo: solo queda lo que Horizon haga con el cielo.

- **Destello**: sube en medio segundo (`smoothstep(0, 0,5, edad)`), parpadea cada tick con un número al azar por tick
  (0,35–1) y se corta a `OPC_RELAMPAGO_DURACION` = 1 s. La especificación dice «se corta al desaparecer el rayo», pero
  el mod no pasa cuándo desaparece: 1 s es una suposición (el rayo de vanilla dura unos pocos ticks más sus destellos).
- **Columna**: la luz sale de un segmento vertical de 150 bloques desde donde cae; la distancia es al punto más cercano
  del segmento.
- **Caída**: `(1 − d/500)² / (1 + (d/30)²)`: 1 de cerca, la mitad a 30 bloques, cero a 500. La especificación solo da
  «fuerte en los primeros 30 y nula a 500»; la forma exacta es mía.
- **Superficies**: orientación media hacia la base y hacia lo alto de la columna (ilumina también caras que miran
  arriba), × luz de cielo⁴ (en cuevas no llega), × `OPC_RELAMPAGO_BRILLO` = 6 en la escala de la luz de bloque
  (la antorcha a nivel 15 da 1,47), color blanco algo azulado. Se suma a la luz indirecta, como la de bloque.
- **Nubes y niebla**: la misma caída, × `OPC_RELAMPAGO_NUBES` = 3 × 1/(4π) (fase isótropa: sin ella la niebla se
  saturaba a blanco, más que el sol de mediodía). En las nubes, más en lo denso (forma local) y cerca de la base de la
  capa (½ arriba, 1 abajo).
- **El trazo del rayo**: lo dibuja Horizon (es una entidad: no pasa por el pack).

Comprobado en Horizon (2026-11-12, cliente nativo con el mod, escena `pruebas/escenas/relampago.ctl`): de noche con
tormenta, un rayo a 25 bloques enciende el suelo y la niebla en gris claro; antes del rayo, la escena negra.

## Luz en la mano

`MaterialInput.colored_light` (B-09) se suma a la luz de bloque. No se pudo medir la caída: en el cliente nativo de
2026-11-09 (Horizon `fdc87ae`) el menú «Extras» no tiene el interruptor de luces dinámicas, y con
`dynamicLights:true` en `horizon-extras.txt` y una antorcha en la mano `colored_light` sigue a 0 (escena
`mano-luz.ctl`, todo negro). Queda para el gestor. Lo que sí se sabe sin medir: `colored_light` no da la dirección de
la luz, así que la orientación de la cara (coseno con la dirección a la mano) no se puede aplicar desde el pack.
