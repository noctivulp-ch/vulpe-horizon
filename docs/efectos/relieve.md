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
   - `sup_relieve_normalizar_altura(altura, piso_altura) -> f32`: reescala linealmente la altura LabPBR desde `[piso_altura, 1,0]` a `[0,0, 1,0]`.
   - `sup_relieve_admite_material(material)`: excluye hojas (`1u`) y plantas cruzadas (`2u`, `4u`, `8u`) para evitar deformaciones no deseadas en follaje.
   - `sup_relieve_atenuacion_distancia(distancia, distancia_max)`: replica la curva del original —pleno relieve hasta la mitad de la distancia y caída cuadrática `clamp((1,0 − d/d_max) × 2,0, 0,0, 1,0)²` en la segunda mitad— asegurando una transición imperceptible hacia la cara plana lejana.
   - Modo escalonado opcional (`escalonado`): cuantifica la altura en peldaños planos según la resolución de celdas.
3. **Adaptador (`adaptadores/relieve.wgsl`):**
   - Traduce `DisplacementInput` de la API de Horizon a los parámetros del núcleo.
   - Lee las opciones activas (`opc_relieve()`), extrae la distancia euclídea de la posición cámara `length(input.position)` y llama a `sup_relieve_profundidad`.
4. **Constantes y opciones (`opciones/relieve.wgsl`):**
   - Menú en 64 de 64 opciones: se añade una única opción directa al menú:
     - `relieve`: `float` de 0.00 a 0.50 bloques (por defecto 0.25 bloques, paso 0.05). Un valor de 0.0 apaga el efecto completamente.
   - Los demás ajustes se resuelven como constantes con nombre o ligados a calidad:
     - `OPC_RELIEVE_DISTANCIA = 12.0`: distancia máxima de relieve. En preset de calidad general `Baja` (`calidad_general == 0u`), se reduce a 6.0 bloques para economizar vértices en GPUs de gama baja.
     - `OPC_RELIEVE_PISO_ALTURA = 0.85`: umbral inferior de normalización del rango de alturas LabPBR (ver §Normalización del rango de altura).
     - `OPC_RELIEVE_CELDAS = 16u`: resolución de teselación (16×16 celdas por cara).
     - `OPC_RELIEVE_ESCALONADO = false`: relieve suave continuo.

## Normalización del rango de altura LabPBR (18.1)

La especificación 18 §2 parte de una altura LabPBR ideal entre `0,0` (fondo) y `1,0` (cumbre), con profundidad `(1,0 − height) × profundidad_max`. Sin embargo, la mayoría de los paquetes de recursos LabPBR (como VibrantPBR R1.15, donde `stone_bricks_n.png` codifica el canal alfa entre `222/255 ≈ 0,871` y `255/255 = 1,0`) concentran todo el relieve en el tramo superior `[0,85..1,0]` para no atravesar el bloque en motores POM tradicionales.

Con la conversión directa `(1,0 − height) × 0,25`:
1. La diferencia máxima entre ladrillo y junta era de solo `(1,0 − 0,871) × 0,25 ≈ 0,032` bloques.
2. Como Horizon desplaza cada vértice respecto a la altura media de la textura (`d(h) − d(h_media)`), el desplazamiento neto era aún menor (~0,02 bloques).
3. Además, con `cells = 16` (un vértice cada `1/16` de bloque = 1 téxel de 16×), en un paquete de 128× (8 téxeles por celda) las juntas estrechas de 2–4 téxeles quedan entre esquinas de la cuadrícula o promediadas, resultando en una diferencia visual prácticamente nula frente a `relieve = 0`.

**Decisión (18.1):**
- Se introduce `OPC_RELIEVE_PISO_ALTURA = 0.85` en `opciones/relieve.wgsl` y `sup_relieve_normalizar_altura` en `nucleo/superficie/relieve.wgsl`, que reescala `clamp((altura − piso) / (1,0 − piso), 0,0, 1,0)`.
- En paquetes con rango corto (`222..255`), el fondo de la junta pasa de `1 − 0,871 = 0,129` a `1 − (0,871 − 0,85)/0,15 = 0,863` del rango (~6,7× más profundo, alcanzando ~0,21 bloques con `relieve = 0,25`).
- En paquetes sin mapa PBR o con caras planas (`altura = 1,0`), la altura normalizada sigue siendo `1,0` y el desplazamiento devuelve exactamente `0,0`. En paquetes con hendiduras más profundas (`altura <= 0,85`), estas saturan limpiamente al tope `profundidad_max`.
- En `adaptadores/material.wgsl` y `nucleo/superficie/labpbr.wgsl` se conectó además la opción `normales_intensidad` a `sup_normal_mapa` (que antes no se aplicaba), permitiendo acentuar el microdetalle dentro de cada celda de 1/16.

## Vista de depuración (`OPC_VISTA_RELIEVE`)

En `opciones/depuracion.wgsl` se añade `OPC_VISTA_RELIEVE = 7u` sobre la estructura `opc_depuracion()` existente (sin gastar opciones del manifiesto; se activa cambiando `OPC_DEPURACION_VISTA_DEFECTO = 7u`). Cuando está activa, `adp_material_salida` escribe directamente sin tonemap ni TAA:
- **Canal Rojo (`R`):** `MaterialInput.displaced` (`0..1`), que vale `1,0` cerca de la cámara en las caras que Horizon ha subdividido y desplazado con `[displacement]`, cayendo a `0,0` en el cuarto final de `distance = 12.0` (o `0,0` en caras sin mapa de altura LabPBR).
- **Canal Verde (`G`):** la altura LabPBR leída de `block_normal_map(input.uv).a` y normalizada con `OPC_RELIEVE_PISO_ALTURA` (`1,0` en las cumbres de los ladrillos, `~0,14` oscuro en las juntas de `stone_bricks_n.png`).
- **Canal Azul (`B`):** `block_pbr_maps()` (`1,0` si Horizon ha cargado los mapas `_n`/`_s` del paquete de recursos, `0,0` si no).

## Integración con LabPBR y observación sobre texturas de 16× vs 128×

- **Canal alfa de normales (altura LabPBR):** Horizon entrega la altura en `DisplacementInput.height` (en las esquinas de la cuadrícula de `16×16`) y en `block_normal_map(uv).a` (por fragmento).
- **Canal azul de normales (AO de material):** en `adaptadores/material.wgsl`, al estar presentes los mapas PBR (`block_pbr_maps()`), el canal B modula el albedo como `albedo *= 0.5 + 0.5 * normal_map.b`, acentuando visualmente la profundidad en hendiduras y juntas.
- **Sobre los píxeles de 16× con paquetes de 128×:** en la documentación de Horizon (`docs/api/shaders.md` l. 317–320 y `docs/api/shaders-reference.md` l. 139–145), el motor expone `block_texture_size()` y `block_pbr_size()` por separado («where a map is smaller/larger»), y los paquetes solo PBR como VibrantPBR suelen incluir únicamente los mapas `_n.png` y `_s.png` a 128× apoyándose en el albedo base de 16× de Minecraft (o bien el empaquetador de atlas de Horizon limita el sprite base). Además, la malla de `[displacement]` tiene `cells = 16` (1 celda por cada téxel de 16×), por lo que la geometría se desplaza a resolución de 16×16 por cara mientras que `block_normal_map(uv)` aporta la resolución de 128× por píxel.
