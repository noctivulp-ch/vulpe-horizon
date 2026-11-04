# Lluvia y nieve (subsistema 16)

Especificación: `../vulpe-horizon-spec/subsistemas/16-lluvia-y-nieve.md`. Capturas: `pruebas/capturas/clima-*.png` y
`hoja-clima.png` (escena `pruebas/escenas/clima.ctl`).

## Por qué del código

`etapas/clima.wgsl` + `adaptadores/clima.wgsl` (etapa `weather`; el juego instalado sí la admite):

- **Luz de la gota:** cielo medio de la tabla del 01 (gris con la lluvia, como en 03) × la curva de luz de cielo,
  más el astro tras la atmósfera × sombra × fase × luz de cielo, más la antorcha con la curva de luz de bloque y el
  color por defecto de 03; × 1,3 para que la gota quede algo más clara que lo que tapa. Fase de Henyey-Greenstein
  g = 0,75 para la lluvia (brilla a contraluz) y 0,1 para la nieve.
- **Sombra:** aproximada por la luz de cielo de Minecraft, como más allá del mapa en el 04. La etapa `weather` tiene el
  ayudante `shadow_position` pero solo recibe `frame`, sin `shadow_map` ni comparador (referencia de Horizon del
  2026-11-04): es un límite de Horizon, no de versión (ver §«Sombra con el mapa»).
- **Alfa:** el de la textura × opción × 0,28 (lluvia) o 0,75 (nieve).
- **Niebla:** la de post no ve las cortinas (no escriben profundidad, dato del gestor): el alfa se atenúa aquí con
  `e^(−σ·distancia)`, σ de la niebla uniforme del momento (horario del 05 + lluvia) más 0,004.
- La salida va **codificada** (ADR 0004): el clima se mezcla en el «picture» como el cielo y el material.

## Opciones

Opacidad de la lluvia y la nieve (imprescindible), página «Luz». Van 49.

## Visto y no visto

- **Visto:** lluvia de día como cortinas finas casi transparentes sobre el cielo cubierto; de noche, vetas tenues;
  nieve en el bioma nevado como copos blancos opacos.
- **Junto a antorchas** (`clima-lluvia-antorchas.png` frente a `clima-sin-lluvia-antorchas.png`): de noche, las
  cortinas se iluminan en un halo claro alrededor de cada antorcha y se ven como vetas; lejos de ellas, casi nada.
- **A contraluz del sol** (`clima-lluvia-contraluz.png`, atardecer mirando al oeste): no se distingue brillo hacia
  delante, porque con lluvia el sol queda al 10 % (cielo cubierto, 03) y no hay contraluz que recoger. Es lo
  esperable con el cielo cerrado; solo se vería con lluvia y sol a la vez (paso de una tormenta).

## Sombra con el mapa (fase 2b, punto 7): no se puede todavía

Comprobado el 2026-11-03: la referencia de Horizon da a la etapa `weather` solo `frame` en su grupo de recursos (ni
`shadow_map` ni su comparador), así que `shadow_position` sola no sirve; además el comprobador compilado de
`trabajo/horizon-shader-build` responde «unknown identifier: `shadow_position`» en esa etapa. Sigue la sombra aproximada
por la luz de cielo. Confirmado por el gestor con la referencia del 2026-11-04 (`9abb7dc50`): límite de Horizon, en la lista de
peticiones del dueño.
