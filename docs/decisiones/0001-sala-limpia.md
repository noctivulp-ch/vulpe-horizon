# 0001 — Se escribe en sala limpia

**Fecha:** 2026-11-01 · **Estado:** aceptada

## Contexto

El usuario quiere su shader en Horizon y poder compartirlo públicamente. Vulpe actual se apoya en Bliss,
cuya licencia es desde el 2026-01-21 «© 2020 Chocapic13. All rights reserved.»: renombrar o reorganizar
su código seguiría siendo una obra derivada (`../vulpe-forged/docs/analisis/reescritura-propia-y-base-neutra.md`).
El propio roadmap de Horizon usa el mismo método para sus reescrituras de packs conocidos («desde la
documentación del formato y el aspecto en pantalla, no desde el código de nadie»).

## Decisión

Diseño de sala limpia con dos agentes y un gestor:

- **Especificador (A):** lee Bliss y Vulpe, escribe `../vulpe-horizon-spec/` con las reglas de su
  `README.md` (sin código, sin identificadores, técnicas con referencia pública, objetivos visuales en vez
  de constantes copiadas).
- **Implementador (B):** trabaja **solo** en este repo; lee **solo** `../vulpe-horizon-spec/`,
  `../docs/horizon/` y bibliografía pública. **Nunca** abre `../Bliss-Shader`, `../vulpe-forged`,
  `../Vulpe`, `../Eclipse-Shader`, `../rethinking-voxels`, `../mellow-shader` ni `../trabajo` (salvo el
  binario `../trabajo/horizon-shader-build/target/release/horizon-shader`, una herramienta).
- **Gestor:** revisa la especificación antes de que B la use, prueba el pack en el juego con
  `horizon-ctl`, y devuelve a B **observaciones de lo que se ve** (capturas, mediciones), nunca código.
  Pasa periódicamente un comprobador de contaminación (identificadores y frases distintivas de Bliss) sobre
  este repo.

## Registro

Cada lote que cruza la muralla queda en el historial git del repo de la especificación; lo que B recibe del
gestor fuera de él (observaciones) se anota en `docs/observaciones-del-gestor.md`. Así se puede demostrar
de dónde sale cada parte.
