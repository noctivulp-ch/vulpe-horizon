# Lluvia y nieve (subsistema 16)

Especificación: `../vulpe-horizon-spec/subsistemas/16-lluvia-y-nieve.md`. Capturas: `pruebas/capturas/clima-*.png` y
`hoja-clima.png` (escena `pruebas/escenas/clima.ctl`).

## Por qué del código

`etapas/clima.wgsl` + `adaptadores/clima.wgsl` (etapa `weather`; el juego instalado sí la admite):

- **Luz de la gota:** cielo medio de la tabla del 01 (gris con la lluvia, como en 03) × la curva de luz de cielo,
  más el astro tras la atmósfera × sombra × fase × luz de cielo, más la antorcha con la curva de luz de bloque y el
  color por defecto de 03; × 1,3 para que la gota quede algo más clara que lo que tapa. Fase de Henyey-Greenstein
  g = 0,75 para la lluvia (brilla a contraluz) y 0,1 para la nieve.
- **Sombra:** el comprobador compilado (`trabajo/horizon-shader-build`) y el juego instalado son anteriores a
  `shadow_position` en la etapa `weather` (entró el 2026-11-02 a las 00:53, dato del gestor): «unknown identifier».
  Mientras tanto, sombra aproximada por la luz de cielo de Minecraft, como más allá del mapa en el 04. Con una
  versión más nueva, usar `shadow_position` + el mapa.
- **Alfa:** el de la textura × opción × 0,28 (lluvia) o 0,75 (nieve).
- **Niebla:** la de post no ve las cortinas (no escriben profundidad, dato del gestor): el alfa se atenúa aquí con
  `e^(−σ·distancia)`, σ de la niebla uniforme del momento (horario del 05 + lluvia) más 0,004.
- La salida va **codificada** (ADR 0004): el clima se mezcla en el «picture» como el cielo y el material.

## Opciones

Opacidad de la lluvia y la nieve (imprescindible), página «Luz». Van 49.

## Visto y no visto

- **Visto:** lluvia de día como cortinas finas casi transparentes sobre el cielo cubierto; de noche, vetas tenues;
  nieve en el bioma nevado como copos blancos opacos.
- **No visto:** el brillo a contraluz del sol (el cielo cubierto apaga el sol al 10 %, 03), junto a antorchas.
