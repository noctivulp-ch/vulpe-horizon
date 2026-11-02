# Documentación de Vulpe para Horizon

- `decisiones/`: ADR numerados. 0001 sala limpia · 0002 carpetas por función y SOLID · 0003 pack montado en
  `build/` · 0004 el «picture» guarda la escena codificada con el mapeo de tonos.
- `efectos/<efecto>.md`: qué hace cada efecto y el **porqué del código** (el código solo remite aquí).
  Empezar por `efectos/nucleo.md` (base matemática, ruido, color, adaptadores y herramientas). Luego
  `efectos/cielo-y-atmosfera.md` (01), `efectos/cielo-fractal.md` (02) `efectos/luz-de-superficie.md` (03), `efectos/sombras.md` (04), `efectos/niebla-y-nubes.md` (05) `efectos/aurora.md` (06), `efectos/taa.md` (09), `efectos/bloom.md` (10),
  `efectos/exposicion-tonemap-gradacion.md` (11), `efectos/agua.md` (07) ,
  `efectos/oclusion-ambiental.md` (08), `efectos/menas-brillantes.md` (12),
  `efectos/aislamiento-de-color.md` (13), `efectos/rayos-del-fractal.md` (14),
  `efectos/vegetacion-ondulante.md` (15, desactivado) , `efectos/lluvia-y-nieve.md` (16) y
  `efectos/otras-dimensiones.md` (17).
- `observaciones-del-gestor.md`: lo que llega del gestor fuera de la especificación.

- [Metodología](metodologia.md): cómo se trabaja (sala limpia, pruebas, criterios) y dónde se quedó.

## Carpetas añadidas a las del ADR 0002

- `texturas/`: PNG del `[[textures]]` del manifiesto. Son **generadas**: cada una dice en su documento de
  efecto qué herramienta de `tools/` la reescribe (p. ej. `tools/atmosfera/generar_tabla.py`). Van a git
  porque el pack las necesita tal cual.
