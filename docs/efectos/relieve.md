# Relieve con [displacement] (subsistema 18)

Especificación: `../vulpe-horizon-spec/subsistemas/18-relieve.md` (commit `9a845f1`).
Documentación de Horizon: `docs/horizon/horizon/docs/api/shaders.md` y `docs/horizon/horizon/docs/api/shaders-reference.md`.

## Por qué [displacement] frente a POM clásico

En el shader original (GLSL sobre OptiFine/Iris), el relieve se simulaba enteramente en el shader de fragmentos mediante *Parallax Occlusion Mapping* (POM):
- Cada fragmento ejecutaba un bucle de trazado de rayos iterativo en espacio tangente (hasta 35 pasos de muestreo por píxel).
- La silueta exterior del bloque seguía siendo un cubo plano y rígido.
- Tenía un coste elevado de tasa de relleno (*fillrate*) y lecturas redundantes de textura por píxel.
- No proyectaba sombras sobre el mapa de sombras ni tenía autosombra geométrica entre crestas y valles.

En Horizon (API 0.1), el relieve pasa a ser **geometría real teselada en la GPU** mediante la etapa `[displacement]`:
- Horizon subdivide las caras de terreno sólido en una cuadrícula regular de celdas (`cells = 16` celdas por arista).
- Cada esquina de la cuadrícula invoca `displacement(input: DisplacementInput) -> f32`.
- El vértice se desplaza hacia el interior a lo largo de la normal de la cara en una magnitud igual a la profundidad devuelta en ese punto menos la profundidad en la altura media de la textura, anclando los bordes perimetrales para evitar grietas entre bloques contiguos.
- Al coexistir con `[shadow]`, la malla desplazada se proyecta directamente en el mapa de sombras (`shadow_map`), logrando **autosombra real y sombras arrojadas** sobre el terreno circundante de forma físicamente correcta sin coste de raymarching en fragmentos.

## Estructura por función (ADR 0002)

1. **Etapa (`etapas/material.wgsl`):**
   - Declara el punto de entrada exigido por Horizon: `fn displacement(input: DisplacementInput) -> f32`.
   - Solo compone delegando directamente en el adaptador (`adp_desplazamiento(input)`).
2. **Núcleo puro (`nucleo/superficie/relieve.wgsl`):**
   - `sup_relieve_profundidad(altura, distancia, material, params) -> f32`: calcula la profundidad física hacia adentro en bloques.
   - `sup_relieve_admite_material(material)`: excluye hojas (`1u`) y plantas cruzadas (`2u`, `4u`, `8u`) para evitar deformaciones no deseadas en follaje.
   - `sup_relieve_atenuacion_distancia(distancia, distancia_max)`: replica la curva del original —pleno relieve hasta la mitad de la distancia y caída cuadrática `clamp((1,0 − d/d_max) × 2,0, 0,0, 1,0)²` en la segunda mitad— asegurando una transición imperceptible hacia la cara plana lejana.
   - Modo escalonado opcional (`escalonado`): cuantifica la altura en peldaños planos según la resolución de celdas.
3. **Adaptador (`adaptadores/relieve.wgsl`):**
   - Traduce `DisplacementInput` de la API de Horizon a los parámetros del núcleo.
   - Lee las opciones activas (`opc_relieve()`), extrae la distancia euclídea de la posición cámara `length(input.position)` y llama a `sup_relieve_profundidad`.
4. **Constantes y opciones (`opciones/relieve.wgsl`):**
   - Menú en 63 de 64 opciones: se añade una única opción directa al menú:
     - `relieve`: `float` de 0.00 a 0.50 bloques (por defecto 0.25 bloques, paso 0.05). Un valor de 0.0 apaga el efecto completamente.
   - Los demás ajustes de la especificación se resuelven como constantes con nombre o ligados a calidad:
     - `OPC_RELIEVE_DISTANCIA = 12.0`: distancia máxima de relieve. En preset de calidad general `Baja` (`calidad_general == 0u`), se reduce a 6.0 bloques para economizar vértices en GPUs de gama baja.
     - `OPC_RELIEVE_CELDAS = 16u`: resolución de teselación (16×16 celdas por cara).
     - `OPC_RELIEVE_ESCALONADO = false`: relieve suave continuo.

## Integración con LabPBR y compatibilidad vanilla

- **Canal alfa de normales (altura LabPBR):** Horizon entrega automáticamente la altura en `DisplacementInput.height` (1.0 = cumbre, 0.0 = fondo).
- **Canal azul de normales (AO de material):** en `adaptadores/material.wgsl`, al estar presentes los mapas PBR (`block_pbr_maps()`), el canal B modula el albedo como `albedo *= 0.5 + 0.5 * normal_map.b`, acentuando visualmente la profundidad en hendiduras y juntas.
- **Sin paquete LabPBR:** si se usa el paquete por defecto de Minecraft o texturas sin mapas LabPBR, `input.height` permanece en 1.0 / altura media constante, `displacement` devuelve 0.0 y la superficie continúa viéndose completamente plana e inalterada, cumpliendo el requisito estricto de compatibilidad.
