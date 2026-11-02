# Metodología

Cómo se ha hecho este pack y cómo se sigue trabajando en él. Estado al cierre del 2026-11-02.

## Por qué sala limpia

La versión de Vulpe para Iris/Oculus es una rama sobre Bliss. Desde el 2026-01-21 la licencia de Bliss es
«© 2020 Chocapic13. All rights reserved.», y renombrar o reorganizar su código seguiría siendo una obra
derivada. Para poder publicar la versión de Horizon con licencia GPL, se escribió en **sala limpia**
(*clean-room design*), el mismo método que usa el propio roadmap de Horizon para sus reescrituras de packs
conocidos ([ADR 0001](decisiones/0001-sala-limpia.md)).

## Los papeles

| Papel | Lee | Escribe |
|---|---|---|
| **Especificador (A)** | Bliss, Vulpe y sus capturas, la documentación de Horizon | solo la especificación (repo aparte, privado) |
| **Implementador (B)** | solo la especificación, la documentación de Horizon y bibliografía pública | solo este repo |
| **Gestor** | todo | revisa lo que cruza, prueba en el juego, pasa observaciones |

Los tres son agentes de IA (Claude) en sesiones separadas. El gestor reparte el trabajo, contesta las
dudas de la API leyendo el código de Horizon y nunca le pasa código a B: solo datos del motor y
**observaciones de lo que se ve** (capturas y medidas), que B anota en
[observaciones-del-gestor.md](observaciones-del-gestor.md).

## Reglas de la muralla

Lo que entra en la especificación:

1. Nada de código de Bliss: ni trozos, ni pseudocódigo calcado, ni identificadores, ni comentarios o textos
   del menú.
2. Cada técnica se cita con su referencia pública (Rayleigh/Mie, Henyey-Greenstein, PCSS, GTAO, TAA,
   GGX, LabPBR…) para que B la implemente desde ahí.
3. Las constantes afinadas no se copian: se describe el objetivo visual con capturas de referencia o, desde
   la fase 3, con **tablas de entrada → salida medidas** (vectores de prueba).
4. El código propio de Vulpe (cielo fractal, aurora, menas, aislamiento de color, rayos) sí puede entrar
   como referencia, marcado `PROPIO`.

Antes de que B use un lote, el gestor:

- pasa un comprobador de contaminación, que vigila unos 1 500 identificadores compuestos de Bliss en la
  especificación y en este repo (resultado en todas las rondas: 0 coincidencias);
- y lee el lote buscando código o texto copiado.

Cuando el gestor revisa el código de B frente a la especificación, solo le dice que falta algo y le cita
las líneas de la especificación que cree que se saltó. No le dice cómo arreglarlo.

## Fases

1. **Base (2026-11-01 → 11-02).** A escribió los 16 subsistemas en cinco tandas, y B los implementó en
   orden: cielo, fractal, luz, sombras, niebla y nubes, aurora, agua, oclusión ambiental, TAA, bloom,
   exposición, menas, aislamiento de color, rayos, vegetación y lluvia. Hubo una ronda de revisión por
   tanda.
2. **Faltas (desde el 2026-11-02).** A leyó el código de B y lo comparó con el original subsistema por
   subsistema. Dejó una guía de lo que falta (10 faltas, más una especificación nueva para el Nether y el
   End) sin decirle a B qué escribir. Leer el código de B no lo contamina: la contaminación iría de Bliss
   hacia B, no al revés.
3. **Paridad (en curso).** Son los requisitos del dueño:
   - **flexibilidad** igual o mayor que la del original;
   - **mismas salidas**, en lo matemático y en lo visual.

   A mide el original y entrega un inventario de todo lo ajustable, tablas de entrada → salida y escenas
   fijas con su captura. B reproduce las tablas y compara sus capturas con las del original (diferencia
   media y percentil 99).
4. **Flexibilidad bajo el tope de Horizon (por empezar).** Horizon admite como mucho 64 opciones por pack
   y el original tiene unos 400 ajustes. Decisión del dueño (2026-11-02):
   - **presets** que mueven varios parámetros a la vez;
   - un **mod nativo para Horizon** que pase el resto por `frame.mods` y que sirva también para otras cosas;
   - lo que limite al pack se anota para proponerlo a Horizon más adelante.

## Cómo se prueba

- `tools/validar.sh` arma el pack en `build/vulpe/` y pasa `horizon-shader check`, que comprueba los
  límites de Horizon: 64 lecturas de textura y 20 000 expresiones por etapa.
- `tools/probar.sh <escena>` abre Horizon con el pack, recorre una escena de `pruebas/escenas/` con
  `horizon-ctl` y guarda las capturas en `pruebas/capturas/`. Cada subsistema tiene su hoja de
  capturas.
- El coste se mide con el tiempo de GPU de `horizon-ctl`: 7–8 ms con todo encendido en una RTX 3050 Ti
  portátil.
- Trucos del motor que hay que tener en cuenta:
  - el `tp` de `horizon-ctl` lo deshace el servidor, así que hay que usar `command tp @s`;
  - las cuevas de prueba se construyen con `fill`;
  - Horizon aplica su viñeta después del pack, así que los valores de pantalla se miden en el centro.

## Criterios de código

- **Carpetas por función y SOLID** ([ADR 0002](decisiones/0002-estructura-por-funcion.md)).
- **El porqué de cada decisión va en `docs/efectos/<efecto>.md`**, no en comentarios: el código solo lleva
  una línea que remite allí.
- Un commit por subsistema o por falta, para que un corte no deje trabajo sin guardar.
- Cada parámetro que no va al menú es una constante con nombre, agrupada en `opciones/`, para que
  convertirla en opción sea cambiar una línea del manifiesto.

## Dónde se quedó (2026-11-02)

- **Fase 2:** hechas 17.1 (Nether y End), 03.1 (color de la luz de bloque), 05.1 (lava y nieve en polvo),
  05.2 (niebla nocturna azul), 07.1 (absorción por canal bajo el agua) y 03.2 (estaciones). La 01.1
  (cinturón de Venus) quedó a medias en la rama `wip/fase2-a-medias`, sin validar. Quedan las tres bajas.
- **Fase 3:** A tiene el inventario y las tablas de 01, 02, 03, 05, 06 y 11, y la lista de capturas nuevas del
  original que hacen falta. B aún no ha escrito la herramienta de comparación.
- **Horizon:** la vegetación (15) y la sombra de la lluvia esperan una nightly posterior a
  `nightly-2026-11-01-c9d474d`.
