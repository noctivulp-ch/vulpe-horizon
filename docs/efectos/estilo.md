# Presets de estilo y menú definitivo (subsistema de flexibilidad)

Especificación: `../vulpe-horizon-spec/flexibilidad/mapa-de-ajustes.md` §1 («Menú directo (37 opciones)») y §2.2 («Estilo (17)»).

## Por qué presets de estilo y reorganización del menú

Horizon impone un límite estricto de **64 opciones** en el manifiesto (`horizon-shaders.toml`). El shader original cuenta con más de 400 parámetros ajustables repartidos en 238 filas de inventario. Siguiendo la decisión de arquitectura de `mapa-de-ajustes.md`:
1. **Menú directo:** 37 opciones para los parámetros que el jugador ajusta con mayor frecuencia o que definen la identidad de Vulpe.
2. **Presets de calidad:** 7 opciones (1 general + 6 por subsistema, implementados en B-07).
3. **Presets de estilo:** 17 opciones (`choice`) que unifican grupos de parámetros estéticos que solo tiene sentido mover juntos (atmósfera, niebla horaria, tiempo, color, iluminación de bloques, noches, cuevas, etc.).
4. **Total del menú:** **61 opciones de 64**, dejando 3 opciones de margen de reserva según el reparto de la especificación.

## Resolución de los 17 presets de estilo (`opciones/estilo.wgsl`)

Cada preset de estilo es un `choice` en el manifiesto, evaluado en tiempo de compilación/ejecución mediante funciones puras en `opciones/estilo.wgsl`. El nivel por defecto reproduce con exactitud el comportamiento original del pack.

| Preset | Qué mueve | Niveles (en negrita el por defecto) | Resolución en el pack |
|---|---|---|---|
| `estilo_cielo` | Color del aire (Rayleigh), bruma de aerosoles (Mie), asimetría del halo solar, brillo del cielo | **Natural** (0), Limpio (1), Brumoso (2), Atardeceres intensos (3) | Modifica `rayleigh_dispersion`, `mie_dispersion`, `mie_asimetria` (0,85 en Limpio, 0,72 en Brumoso) y multiplica el brillo en `adp_dispersion()`. |
| `estilo_niebla_horaria` | Densidad uniforme y en manchas a cada hora (8), niebla con lluvia | Despejada (0), **Por defecto** (1), Brumosa (2), Noches cerradas (3) | Escala los vectores de horario en `opc_niebla_horario_uniforme()` y `manchas()` (Despejada: ×0,4; Brumosa: ×2 día / ×1,3 noche; Noches cerradas: noche ×1,8 uniforme y ×3 manchas). |
| `estilo_tiempo` | Cobertura y densidad por capa en tiempo diario y lluvia | **Los del pack** (0), Despejado (1), Variable (2), Encapotado (3), Tormentoso (4) | Multiplica la cobertura y densidad de los perfiles de nubes en `adp_nubes()` (Despejado: cob ×0,5; Encapotado: cob ×1,5; Tormentoso: cob ×1,5 y den ×1,5 con lluvia). |
| `estilo_biomas` | Perfiles de bioma caliente, frío, pantano, selva y jardín pálido (45 parámetros) | **Apagado** (0), Sutil (1), Marcado (2) | Declarado en manifiesto; niveles 1 y 2 quedan pendientes del paso de biomas por mod nativo. |
| `estilo_color` | Gradación por sombras/luces, balance de blancos, diafonía, contraste | **Neutro** (0), Cálido (1), Frío (2), Cine (3), Vivo (4) | Aplica temperatura de color (5500 K en Cálido, 7500 K en Frío), diafonía, tintes en sombras/luces y contraste en `opc_imagen()` y `07-final.wgsl`. Suma la saturación del control directo. |
| `efectos_camara` | Viñeta, grano, aberración cromática, bandas de cine | **Apagados** (0), Sutiles (1), Cine (2) | Declarado en manifiesto; pendiente de implementación en pasada de post. |
| `profundidad_campo` | Calidad, apertura, velocidad de enfoque | **Apagada** (0), Suave (1), Fuerte (2) | Declarado en manifiesto; pendiente de pasada de DoF en post. |
| `estilo_agua` | Absorción por canal, claridad, turbidez, cáusticas | **Normal** (0), Clara (1), Turbia (2), Pantano (3) | Aplica coeficientes de extinción RGB, claridad, dispersión y agudeza de cáusticas en `opc_agua()` y `opc_agua_medio()`. |
| `estilo_luz_bloque` | Color de luz de bloque e intensidad | **Cálida** (0), Neutra (1), Fría (2), Vela (3) | Modifica el tono RGB base de la antorcha/fuego y su intensidad (Vela: más roja, ×0,8) en `opc_luz()`. |
| `estilo_noches` | Intensidad lunar, seguimiento de fase, visión nocturna, luz mínima exterior | **Natural** (0), Claras (1), Oscuras (2), Sin fases (3) | Multiplica luz de luna (Claras ×2, Oscuras ×0,5), visión nocturna (×0,6 en Claras), luz mínima exterior (0,002 en Claras) y modula por la fase lunar del mod nativo `abs(4 - fase)/4` (desactivada en Sin fases). |
| `estilo_fractal` | Dibujo, relleno, ciclos de paleta, ganancia, saturación | **Original** (0), Suave (1), Bandas (2), Salpicadura (3) | Conmuta entre dibujo entero (`CIE_DIBUJO_ORIGINAL`) y continuo (`CIE_DIBUJO_SUAVE`), ajustando saturación y ganancia. Bandas y salpicadura quedan anotados como pendientes. |
| `estilo_aurora` | Intensidad, radio, fin del velo, largo de cortina, ventana al cielo | Discreta (0), **Por defecto** (1), Amplia (2) | Modifica en `adp_aurora()` la intensidad (Discreta ×0,5), radio (Amplia ×2), largo de cortina (Amplia ×1,7, Discreta ×0,7) y altura de velo. |
| `estilo_rayos` | Foco, longitud, caída, umbral y limitador | Sutiles (0), **Normales** (1), Dramáticos (2) | Modifica en `adp_rayos()` los parámetros de frente y espaldas (Sutiles: foco ×1,3, longitud ×0,7, umbral ×1,5; Dramáticos: foco ×0,7, longitud ×1,5, caída ×0,7). |
| `efectos_juego` | Daño leve/fuerte, salud baja/crítica, en llamas, agua en cámara | Apagados (0), Sutiles (1), **Por defecto** (2), Intensos (3) | Declarado en manifiesto; pendiente de datos de salud/fuego del motor. |
| `atmosfera_nether` | Humo de lava, humo del techo, bruma del Nether | Despejada (0), **Estándar** (1), Sofocante (2) | Escala la densidad de la niebla en el Nether (Despejada ×0,5, Estándar ×1,0, Sofocante ×1,5) en `opc_volumen()`. |
| `tormenta_end` | Densidad de tormenta, bruma de fondo, relámpagos | Calma (0), **Estándar** (1), Tormenta (2) | Escala la densidad de partículas/niebla en el End (Calma ×0,5 sin relámpagos, Tormenta ×1,5 con bruma ×1,2) en `opc_volumen()`. |
| `estilo_cuevas` | Niebla de cueva, oscurecer cielo, caída, luz mínima interior | Abiertas (0), **Por defecto** (1), Oscuras (2), Muy oscuras (3) | Controla la niebla subterránea (Abiertas: apagada), caída exponencial (Oscuras ×2) y luz mínima en interiores (Abiertas ×1,3, Oscuras ×0,33, Muy oscuras 0,0). |

## Opciones que salieron del menú hacia constantes o presets

Conforme a la regla 3 del encargo y `mapa-de-ajustes.md` §1 y §3, las opciones individuales que fueron absorbidas por un preset, integradas en controles unificados o delegadas al mod nativo salieron del manifiesto y pasaron a **constantes con nombre en `opciones/`** manteniendo su valor por defecto:

| Opción anterior | Tipo anterior | Destino / Justificación | Constante con nombre en `opciones/` |
|---|---|---|---|
| `cielo_brillo` | float | Absorbido por `estilo_cielo` (brillo) y mod nativo | `OPC_CIELO_BRILLO_DEFECTO = 0.0` en `opciones/cielo.wgsl` |
| `luna_brillo` | float | Absorbido por `estilo_noches` (luna) y mod nativo | `OPC_LUNA_BRILLO_DEFECTO = 0.0` en `opciones/cielo.wgsl` |
| `estrellas` | bool | Fijo en código sin ajuste en Horizon (§4) | `OPC_ESTRELLAS_DEFECTO = true` en `opciones/cielo.wgsl` |
| `fractal` | bool | Absorbido por `fractal_brillo` (0 = apagado, regla 87) | `fractal_brillo > 0` en `opciones/fractal.wgsl` |
| `fractal_conjuntos` | int | Pasa al mod nativo (§3) | `OPC_FRACTAL_CONJUNTOS_DEFECTO = 6` en `opciones/fractal.wgsl` |
| `fractal_sorteo` | choice | Pasa al mod nativo (§3) | `OPC_FRACTAL_SORTEO_DEFECTO = 0u` en `opciones/fractal.wgsl` |
| `fractal_semilla` | int | Pasa al mod nativo (§3) | `OPC_FRACTAL_SEMILLA_DEFECTO = 8` en `opciones/fractal.wgsl` |
| `fractal_saturacion` | float | Absorbido por `estilo_fractal` y mod nativo | `OPC_FRACTAL_SATURACION_DEFECTO = 70.0` en `opciones/fractal.wgsl` |
| `aurora` | bool | Absorbido por `aurora_brillo` (0 = apagada, regla 87) | `aurora_brillo > 0` en `opciones/aurora.wgsl` |
| `rayos` | bool | Absorbido por `rayos_intensidad` (0 = apagados, regla 87) | `rayos_intensidad > 0` en `opciones/rayos.wgsl` |
| `niebla` | bool | Absorbido por `niebla_cantidad` (0 = apagada, regla 87) | `niebla_cantidad > 0` en `opciones/volumen.wgsl` |
| `niebla_lluvia` | float | Absorbido por `estilo_niebla_horaria` | `OPC_NIEBLA_LLUVIA_DEFECTO = 1.0` en `opciones/volumen.wgsl` |
| `nubes` | choice | Absorbido por `calidad_nubes` (§2.1) | `OPC_NUBES_DEFECTO = 1u` en `opciones/volumen.wgsl` |
| `niebla_nether` | float | Absorbido por `atmosfera_nether` | `OPC_NIEBLA_NETHER_DEFECTO = 1.0` en `opciones/volumen.wgsl` |
| `niebla_end` | float | Absorbido por `tormenta_end` | `OPC_NIEBLA_END_DEFECTO = 1.0` en `opciones/volumen.wgsl` |
| `agua_claridad` | float | Absorbido por `estilo_agua` (claridad) | `OPC_AGUA_CLARIDAD_DEFECTO = 1.0` en `opciones/agua.wgsl` |
| `luz_cielo` | float | Pasa al mod nativo (§3) | `OPC_LUZ_CIELO_DEFECTO = 1.0` en `opciones/luz.wgsl` |
| `luz_bloque` | float | Absorbido por `estilo_luz_bloque` (intensidad) | `OPC_LUZ_BLOQUE_DEFECTO = 1.0` en `opciones/luz.wgsl` |
| `luz_minima_cuevas` | float | Absorbido por `estilo_cuevas` | `OPC_LUZ_MINIMA_CUEVAS_DEFECTO = 0.5` en `opciones/luz.wgsl` |
| `luz_minima_exterior` | float | Absorbido por `estilo_noches` | `OPC_LUZ_MINIMA_EXTERIOR_DEFECTO = 0.0` en `opciones/luz.wgsl` |
| `menas_intensidad` | float | Absorbido por `menas` (0..99, 0 = apagadas, regla 87) | `menas > 0` en `opciones/menas.wgsl` |
| `clima_opacidad` | float | Fijo en código sin equivalente en original (§4) | `OPC_CLIMA_OPACIDAD_DEFECTO = 1.0` en `opciones/clima.wgsl` |
| `estaciones` | bool | Pasa al mod nativo (necesita día del mundo, §3) | `OPC_ESTACIONES_DEFECTO = true` en `opciones/estaciones.wgsl` |
| `estacion_inicial` | choice | Pasa al mod nativo (§3) | `OPC_ESTACION_INICIAL_DEFECTO = 0u` en `opciones/estaciones.wgsl` |
| `ondulacion_fuerza` | float | Absorbido por `ondulacion` (0 = quieta, regla 87) | `ondulacion > 0` en `opciones/viento.wgsl` |
| `aislamiento` | bool | Absorbido por `aislamiento_rango` (0 = apagado, regla 87) | `aislamiento_rango > 0` en `opciones/aislamiento.wgsl` |
| `taa_nitidez` | float | Pasa al mod nativo; `nitidez` cubre nitidez general | `OPC_TAA_NITIDEZ_DEFECTO = 0.75` en `opciones/taa.wgsl` |
| `exposicion_oscuro` | float | Pasa al mod nativo (§3) | `OPC_EXPOSICION_OSCURO_DEFECTO = 0.0` en `opciones/imagen.wgsl` |
| `exposicion_claro` | float | Pasa al mod nativo (§3) | `OPC_EXPOSICION_CLARO_DEFECTO = 0.0` en `opciones/imagen.wgsl` |
| `imagen_contraste` | float | Pasa al mod nativo (§3) | `OPC_IMAGEN_CONTRASTE_DEFECTO = 0.0` en `opciones/imagen.wgsl` |
| `imagen_tramado` | bool | Fijo en código (§4) | `OPC_IMAGEN_TRAMADO_DEFECTO = true` en `opciones/imagen.wgsl` |
| `depuracion_vista` | choice | Pasa al mod nativo (§3) | `OPC_DEPURACION_VISTA_DEFECTO = 0u` en `opciones/depuracion.wgsl` |

## Tabla de niveles pendientes y de qué efecto (§2.2, regla 2)

Conforme a la regla 2 del encargo, lo que un preset mueve pero aún no existe en el motor o en el pack no se implementa en esta tarea: el preset se declara con sus niveles, el nivel por defecto deja el pack como está, y los niveles no implementados se registran a continuación:

| Preset | Nivel(es) pendiente(s) | Efecto pendiente | Razón técnica / Estado en Horizon |
|---|---|---|---|
| `estilo_biomas` | Sutil (1), Marcado (2) | Perfiles atmosféricos y de vegetación por bioma (45 parámetros) | Requiere datos de bioma en tiempo real que Horizon no expone en `frame` (pendiente del mod nativo `frame.mods`). |
| `efectos_camara` | Sutiles (1), Cine (2) | Viñeta, grano de película, aberración cromática, bandas negras de cine | Las pasadas actuales de post no implementan distorsión cromática, simulación de grano analógico ni barras de relación de aspecto; Horizon además aplica su propia viñeta tras el shader. |
| `profundidad_campo` | Suave (1), Fuerte (2) | Desenfoque de lente (*Depth of Field*), apertura y enfoque dinámico | Requiere pasada de post dedicada con cociente de círculo de confusión (*CoC*) y desenfoque bilateral o bokeh, no implementada en el pack base. |
| `efectos_juego` | Sutiles (1), Intensos (3) | Efectos visuales de daño leve/fuerte, salud baja/crítica, pantalla en llamas | Horizon no expone en la API WGSL actual (`frame`) la vida del jugador ni si está en llamas. |
| `estilo_fractal` | Bandas (2), Salpicadura (3) | Modos de relleno de fractales por bandas de contorno y técnica de salpicadura | Actualmente `nucleo/cielo/fractal_conjunto.wgsl` solo soporta tiempo de escape entero (`CIE_DIBUJO_ORIGINAL`) y continuo (`CIE_DIBUJO_SUAVE`). |
| `tormenta_end` | Tormenta (2) | Relámpagos estocásticos en el End | El sistema volumétrico del End simula niebla y bruma giratoria; la generación de rayos relámpago en el vacío no está implementada. |

## Resumen del presupuesto de opciones del menú (Tope: 64)

- **Menú directo (§1):** 37 opciones.
- **Presets de calidad (§2.1):** 7 opciones.
- **Presets de estilo (§2.2):** 17 opciones.
- **Total:** **61 de 64 opciones** (margen de reserva: 3 opciones libres).
