# Emisivos de vanilla, sombras de entidades y varios (subsistema 24)

Especificación: `vulpe-horizon-spec/subsistemas/24-emisivos-de-vanilla-y-varios.md`. Código: `nucleo/superficie/varios.wgsl`
(puro), `etapas/vertice.wgsl`, `adaptadores/material.wgsl`; constantes en `opciones/varios.wgsl`.

## Lo que no pasa por el pack (se deja como lo dibuja Horizon)

- **Haz del faro, trazo del rayo, haces del dragón, ojos de araña y enderman, capas luminosas de entidades y brillo de
  encantamiento**: son entidades o entidades de bloque. La API 0.1 dice que la etapa `material` cubre solo el terreno
  y que aún no hay etapas para entidades, entidades de bloque ni partículas (`api/shaders.md` §«Not there yet»).
  El ajuste «sin emisivos de vanilla» no tiene sobre qué actuar.
- **Sombras de entidades**: el mapa de sombras lo dibuja Horizon y **sí incluye entidades** (y el modelo propio del
  jugador en primera persona) desde 2026-11-01. No hay control de distancia: el ajuste del original (20 % de la
  distancia de sombras) no se puede aplicar. Tampoco quitarles el SSS: no pasan por `material`.
- **Escala de renderizado**: los destinos de `[[post]]` admiten `scale` 1, ½ o ¼, pero la escena la dibuja Horizon a
  resolución entera. Queda para la fase de rendimiento (`rendimiento.md`).

## Lo hecho, todo apagado por defecto

- **Oclusión del material** (`OPC_OCLUSION_MATERIAL`): el albedo × (½ + ½ · oclusión del mapa de normales LabPBR).
  **Cambio de comportamiento**: hasta ahora se aplicaba siempre con paquetes LabPBR; el original la tiene apagada.
- **Curvatura del mundo** (`OPC_CURVATURA`, −100..100): el vértice baja `ajuste · 0,1 · d²/128²` (d horizontal a la
  cámara). En la etapa `vertex`, que Horizon aplica también al mapa de sombras: las sombras no se separan.
- **Olas grandes en los vértices del agua** (`OPC_OLAS_VERTICE`, 0..1): solo la cara de arriba del fluido
  (`face == 1`); dos senos largos, amplitud de 0 a 0,4 bloques entre la cámara y 64 bloques. La forma es mía: la
  especificación solo dice «ondas largas cuya amplitud crece con la distancia».
- **Infrarrojo** (`OPC_INFRARROJO`, cuánto rosa): la vegetación (materiales de hojas, plantas y colgantes, y los
  bloques con color de bioma) pasa a rosa con su misma luminancia, antes de iluminar. La lana no tiene material propio
  en el manifiesto: `OPC_INFRARROJO_LANA` queda sin efecto hasta etiquetarla.

Comprobado en Horizon (2026-11-12) con curvatura 60, olas 1 e infrarrojo 0,8 a mano (`pruebas/escenas/varios.ctl`):
árboles rosas, mar curvado hacia el horizonte. Devueltos a 0 antes del commit.
