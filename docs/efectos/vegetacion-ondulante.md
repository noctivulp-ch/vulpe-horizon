# Vegetación ondulante (subsistema 15)

Especificación: `../vulpe-horizon-spec/subsistemas/15-vegetacion-ondulante.md`.

## Estado: escrito y validado, desactivado

`horizon-shader check` acepta la etapa `[vertex]`, pero **el juego instalado (nightly-2026-11-01-c9d474d, de las 17:07)
es anterior a ella** (entró a las 17:17, PR #5928; dato del gestor): no es un fallo de Horizon, es la versión. El juego
rechaza el pack entero con «TOML parse error … `[vertex]`». La sección está comentada en el manifiesto (con su porqué)
y las dos opciones van como `override` sin entrada de menú. **Sin ver en el juego.** No hay una versión más nueva
instalada (la otra es la del 29 de octubre); instalar otra la decide el dueño.

Para activarla: quitar los `#` de `[vertex]` en el manifiesto y volver a declarar las opciones:

```toml
[[options]]
id = "ondulacion"
name = "Vegetación ondulante"
type = "bool"
default = true

[[options]]
id = "ondulacion_fuerza"
name = "Fuerza del viento"
type = "float"
default = 1.0
min = 0.0
max = 2.0
step = 0.05
```
y añadirlas a la página «Luz».

## Por qué del código

- `nucleo/superficie/viento.wgsl`: suma de senos con fase espacial (Sousa, GPU Gems 3 cap. 16). Plantas: periodos
  distintos en x (~4,5 s) y z (~6 s), fase anclada al mundo, sesgo en la dirección del viento, amplitud que respira
  con una onda lenta (×0,5–1,2), amplitud base 0,07 bloques, y la y baja lo que se inclina. Hojas: 3D, amplitud
  vertical 1/5, base 0,035.
- `adaptadores/vertice.wgsl`: familias por id de `[[materials]]`: plantas de suelo (ids 2 y 4) solo con la parte de
  arriba del sprite (`uv.y` < 0,5); **mitad superior de las plantas de dos bloques** (id 8, nuevo, con el SSS fuerte y
  como planta cruzada) entera; hojas (id 1) en 3D. La fase de las plantas se toma en la esquina entera del bloque
  (`floor`), así la base de la mitad superior y la punta de la inferior, que coinciden, se mueven igual.
  × fuerza × (1 + lluvia) × luz de cielo del vértice (mínimo 0,5 en plantas). Nada en fluidos.
- **Simplificación:** las enredaderas y lianas están en la familia de las plantas de suelo (id 4, por el SSS medio):
  solo se mueve su mitad de arriba en vez de balancearse enteras. Sin ráfagas (constante apagada en la especificación).

## Montaje del pack

Para poder dejar archivos `.wgsl` sin usar en el repo (el comprobador rechaza un `.wgsl` que ninguna etapa usa),
`tools/montar.sh` enlaza **por archivo** solo lo que nombra el manifiesto (ADR 0003, actualizado).

## Activada (fase 2b, punto 7)

Con la nightly f42ef42 el juego admite `[vertex]`: la etapa está en el manifiesto y las opciones «Vegetación ondulante» y
«Fuerza del viento» vuelven al menú (página «Luz»; 58 opciones). Ritmo y amplitud pasan a lo **medido** en
`paridad/15` (constantes en `opciones/viento.wgsl`):

- **Plantas:** periodo de 1,64 s (antes ~4,5 s: `sin(t · 1,4)`), amplitud 0,0965 → 4,5 cm de media y 11,7 de máximo
  (medido: 4,5 y 12,3), y **bajan tanto como se desplazan** (`y = −|h|`; antes `−4|h|²`, que casi no bajaba).
- **Hojas:** periodo de 4,44 s, amplitud 0,0558 → 4,5 cm de media, vertical ×0,24 → ±1,3 cm (medido ±1,6).
- La lluvia duplica la amplitud sin cambiar el ritmo (`1 + rain`), como en el original.

Las amplitudes se calcularon con las mismas fórmulas sobre 64 fases y 120 s (media del módulo horizontal). **Visto:** de
pie en la pradera de (170, 78, 166), cuatro capturas seguidas difieren en 82 000–237 000 píxeles de la mitad de abajo
con la ondulación y en 1 900–8 900 sin ella (`vegetacion-a.png`, `vegetacion-b.png`). **Sin ver:** el ritmo a ojo con
el juego en marcha y la sombra de las plantas moviéndose.

## Enredaderas y lianas enteras (15.1, 2026-11-09)

En la implementación inicial las enredaderas y lianas compartían el id de material 4 con las plantas de suelo
por su SSS medio. Al aplicar la condición `uv_y > 0.5`, la base de cada bloque de enredadera quedaba estática
mientras que la mitad superior oscilaba, provocando un efecto visual en dientes de sierra a lo largo de columnas
de varios bloques verticales.

**Solución:**
- Separación en `horizon-shaders.toml`: nuevo material `id = 9` (`OPC_MAT_COLGANTES` en `opciones/viento.wgsl`)
  para sprites de lianas y colgantes (`block/vine`, `block/*_vines*`, `block/hanging_roots*`, `block/cave_vines*`).
- En `adaptadores/material.wgsl`: conserva el SSS medio (`0.6`) en `adp_sss_lista` y la condición de planta cruzada
  en `adp_es_cruzada`.
- En `adaptadores/vertice.wgsl`: `colgantes` no aplica la restricción de base `uv_y > 0.5` y se balancea íntegramente
  en 3D con `sup_viento_hoja(mundo, v)` junto a la familia de hojas, garantizando continuidad vertical perfecta entre
  bloques contiguos sin roturas ni dientes de sierra.

