# Presets de calidad (subsistema de flexibilidad)

Especificación: `../vulpe-horizon-spec/flexibilidad/mapa-de-ajustes.md` §2.1 («Calidad (7)»).

## Por qué presets de calidad

Horizon impone un límite estricto de **64 opciones** en el manifiesto (`horizon-shaders.toml`). Para ofrecer una
flexibilidad equivalente a la del shader original sin agotar el presupuesto, los parámetros técnicos que se
mueven juntos se unifican en **presets**:
1. `calidad_general`: define el nivel global para todo el pack (Baja, Media, Alta, Ultra; por defecto Media).
2. Seis presets por subsistema: `calidad_sombras`, `calidad_niebla`, `calidad_nubes`, `calidad_ao`,
   `calidad_reflejos` y `calidad_fractal`. Cada uno cuenta con el valor por defecto **«Según la general»** (0), lo
   que permite al jugador alterar el comportamiento global con un solo ajuste o ajustar un subsistema concreto.

## Resolución de niveles (`opciones/calidad.wgsl`)

La función pura `opc_nivel_calidad(especifico, general)` devuelve el nivel efectivo:
- Si el ajuste específico es `0u` («Según la general»), hereda `calidad_general` (`0u..3u`).
- Si es `1u..4u`, selecciona explícitamente Baja (`0u`), Media (`1u`), Alta (`2u`) o Ultra (`3u`).

Cada subsistema traduce el nivel efectivo a sus variables internas (pasos, muestras, radios y límites).

### Resumen de parámetros por nivel (§2.1)

| Preset | Qué mueve | Baja (0) | Media (1, defecto) | Alta (2) | Ultra (3) |
|---|---|---|---|---|---|
| `calidad_general` | nivel global de los seis presets | Baja | Media | Alta | Ultra |
| `calidad_sombras` | penumbra variable, muestras de búsqueda y de filtro, radio de penumbra, sombras de contacto | penumbra fija (`variable = false`), filtro 4, búsqueda 0 | variable, búsqueda 4, filtro 8, radio 5 – 30 | búsqueda 8, filtro 16, sombras de contacto cal. 2 (pendiente) | búsqueda 16, filtro 32, sombras de contacto cal. 4 (pendiente) |
| `calidad_niebla` | pasos de raymarch de niebla, alcance sin LODs | 4 pasos, 256 bloques | 6 pasos, 512 bloques | 12 pasos, 1024 bloques | 24 pasos, 2048 bloques |
| `calidad_nubes` | pasos del raymarch y capas activas | 7 pasos (×0,5), sin cúmulos pequeños (`capas.x = 0`) | 14 pasos (×1), 3 capas | 28 pasos (×2), 3 capas | 42 pasos (×3), 3 capas |
| `calidad_ao` | tipo de oclusión ambiental, muestras | la de vanilla (0 muestras en pantalla) | pantalla filtrada (7 muestras) | pantalla de alta calidad (20 muestras) | trazado con rebote (pendiente; usa pantalla de alta calidad, 20 muestras) |
| `calidad_reflejos` | pasos de trazado en pantalla y umbral de rugosidad | 8 pasos, umbral rugosidad 0,2 (suavidad 0,8) | 15 pasos, umbral rugosidad 0,3 (suavidad 0,7) | 30 pasos, umbral rugosidad 0,4 (suavidad 0,6) | 50 pasos, umbral rugosidad 0,5 (suavidad 0,5) |
| `calidad_fractal` | iteraciones dibujo fractal, iteraciones/muestras aurora, muestras rayos | 60 dibujo; 12 y 2 aurora; 16 rayos | 100 dibujo; 24 y 4 aurora; 32 rayos | 200 dibujo; 48 y 8 aurora; 48 rayos | 300 dibujo; 96 y 12 aurora; 64 rayos |

## Balance de opciones del menú (Tope: 64)

Al inicio de la tarea el pack contaba con 59 opciones. Se retiraron 5 opciones individuales absorbidas por los presets y se agregaron los 7 presets de calidad y las 2 opciones de tamaño y alcance del mapa de sombras (`sombras_resolucion` y `sombras_distancia`), situando el total final en **63 opciones** (bajo el tope de 64):

| Opción que salió | Tipo anterior | Preset que la absorbe / reemplaza | Justificación / Resolución |
|---|---|---|---|
| `sombras_penumbra` | choice (Básica, Variable) | `calidad_sombras` | Baja aplica penumbra fija (básica, 4 muestras); Media, Alta y Ultra aplican penumbra variable (PCSS) con 8, 16 y 32 muestras. |
| `niebla_pasos` | int (4..16) | `calidad_niebla` | Pasa a resolverse en 4, 6, 12 y 24 pasos junto con el alcance de la niebla (256, 512, 1024 y 2048 bloques). |
| `nubes_calidad` | choice (Baja, Media, Alta) | `calidad_nubes` | Pasa a resolverse en 7, 14, 28 y 42 pasos (×0,5, ×1, ×2, ×3) y desactiva la capa baja de cúmulos en Baja. |
| `ao` | choice (Apagada, Normal, Alta) | `calidad_ao` | Pasa a resolverse en 0 (vanilla), 7 (filtrada) y 20 (alta calidad) muestras de disco de Vogel. |
| `reflejos_pantalla` | choice (Apagados, Bajos, Altos) | `calidad_reflejos` | Pasa a resolverse en 8, 15, 30 y 50 pasos, controlando dinámicamente el umbral de rugosidad (0,2, 0,3, 0,4 y 0,5). |

### Nuevas opciones introducidas (9)
1. `calidad_general` (choice: Baja, Media, Alta, Ultra; defecto Media).
2. `calidad_sombras` (choice: Según la general, Baja, Media, Alta, Ultra; defecto Según la general).
3. `sombras_resolucion` (choice de números: 1024, 2048, 4096; defecto 2048), conectada a `[shadow] resolution_option`.
4. `sombras_distancia` (choice de números: 64, 128, 192, 256; defecto 128), conectada a `[shadow] distance_option`.
5. `calidad_niebla` (choice: Según la general, Baja, Media, Alta, Ultra; defecto Según la general).
6. `calidad_nubes` (choice: Según la general, Baja, Media, Alta, Ultra; defecto Según la general).
7. `calidad_ao` (choice: Según la general, Baja, Media, Alta, Ultra; defecto Según la general).
8. `calidad_reflejos` (choice: Según la general, Baja, Media, Alta, Ultra; defecto Según la general).
9. `calidad_fractal` (choice: Según la general, Baja, Media, Alta, Ultra; defecto Según la general).

### Por qué `sombras_resolucion` y `sombras_distancia` van aparte del preset

En Horizon (API 0.1, desde el 2026-11-03), `[shadow] resolution_option` y `distance_option` apuntan a una opción de tipo `int` o `choice` cuyos valores son cadenas numéricas dentro de `256..=8192` y `32.0..=512.0` (`OptionKind::number` en `horizon-shader-api`). Como el motor lee directamente el número de la opción al construir el mapa de sombras y no puede evaluar la herencia de `calidad_general` ni traducir etiquetas simbólicas («Según la general», «Baja», etc.), el tamaño (`sombras_resolucion`: `"1024"`, `"2048"`, `"4096"`, por defecto `"2048"`) y el alcance (`sombras_distancia`: `"64"`, `"128"`, `"192"`, `"256"`, por defecto `"128"`) se exponen como dos opciones `choice` numéricas propias en la página de Calidad. Estas dos opciones no necesitan `override` en WGSL porque el shader lee el valor efectivo a través de `frame.shadow_resolution` y `frame.shadow_distance`. Tampoco se añade `[shadow] option` porque apaga el mapa cuando el índice o valor de la opción es 0 (`0u` en `calidad_sombras` es «Según la general» y en `calidad_general` es «Baja»), y dedicar una opción `bool` adicional no es necesario.

## Efectos no presentes en el pack (anotados como pendientes)

Conforme a la regla 4 del encargo:
1. **Sombras de contacto en espacio de pantalla** (`calidad_sombras` en Alta y Ultra): el pack actual no implementa trazado de sombras de contacto en espacio de pantalla (requeriría pasada de post o acceso a la profundidad de escena antes de `material`). Alta y Ultra emplean PCSS con mayor muestreo (16 y 32 muestras de filtro, 8 y 16 de búsqueda de ocluyentes).
2. **Oclusión ambiental por trazado de rayos con rebote** (`calidad_ao` en Ultra): el pack no implementa trazado de rayos por voxeles ni rebote difuso. Ultra utiliza la versión de pantalla de alta calidad (20 muestras).
3. **Reflejos de pantalla en translúcidos** (`calidad_reflejos`): actualmente el agua y materiales translúcidos resuelven el reflejo mediante la etapa plana de `[reflection]`, mientras que el SSR en `material.wgsl` está condicionado a `!p.translucido`. Se anota para cuando se admita SSR sobre superficies translúcidas en post.
