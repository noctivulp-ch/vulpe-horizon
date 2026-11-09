# Registro de cambios (CHANGELOG) — Vulpe para Horizon

Todos los cambios notables de Vulpe para Horizon se documentan en este archivo.
El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y este proyecto sigue [SemVer](https://semver.org/lang/es/).

---

## [0.2.0-beta.1] — 2026-11-08

Primera versión beta pública empaquetada en formato `.hshader` para Horizon (Minecraft Java reescrito en Rust), implementada en sala limpia sobre la API de shaders en WGSL (API 0.1).

Esta versión beta reúne los subsistemas base e introduce el relieve geométrico por teselación, soporte de iluminación dinámica en la mano, sombras completamente configurables y una reestructuración integral del menú mediante presets de calidad y de estilo bajo el límite estricto de 64 opciones del motor.

### Subsistemas (fase 1 consolidada y mejoras de fase 2/3)

Están implementados los 18 subsistemas del pack (el relieve, el 18, se describe más abajo):
- **Cielo físico y atmósfera:** dispersión física Rayleigh y Mie resuelta en vivo con tabla precalculada de transmitancia, tabla de colores atmosféricos, astros (sol, luna con seguimiento de fases, estrellas) y cinturón de Venus suavizado en el horizonte.
- **Cielo fractal procedural (identidad Vulpe):** renderizado nocturno de conjuntos de Julia y Mandelbrot con sorteo diario igual al del original en las GPU cuyo seno coincide (comprobado en una RTX 3050 Ti; en otras, modo de hash estable), paletas armónicas y modulación de ganancia.
- **Aurora boreal del fractal:** emisión de cortinas de luz en el volumen de niebla proyectadas desde los conos del fractal, con vetas, velo superior y ventana nítida hacia el cielo.
- **Niebla y nubes volumétricas:** trazado de rayos (*raymarching*) unificado para atmósfera, niebla y tres capas de nubes con perfiles dinámicos según el tiempo diario y horario (niebla baja matutina, noches densas y tormentas).
- **Luz de superficie (PBR):** iluminación física con soporte completo de LabPBR (albedo, normales detalladas, rugosidad lineal, reflectancia metálica F0 y dispersión bajo la superficie / SSS en hojas y nieve), atenuación medida de antorchas y ajuste de interiores.
- **Agua física:** oleaje procedural con dos octavas, refracción calculada a partir de la profundidad real de la escena (`opaque_depth`), absorción espectral RGB, cáusticas submarinas, reflejo del cielo del pack y niebla subacuática con ventana de Snell.
- **Sombras PCSS:** cálculo de sombras de porcentaje más cercano (PCSS) con búsqueda de ocluyentes, penumbra variable según distancia, filtrado con disco de Vogel girado por píxel, sombras coloreadas a través de agua y cristales teñidos, y sombras arrojadas de nubes.
- **Oclusión ambiental (AO):** oclusión en espacio de pantalla con filtrado por disco de Vogel, atenuación según aristas y distancia para evitar halo oscuro en lejanía.
- **Post-procesado e imagen:** anti-aliasing temporal (TAA) con jitter de ruido azul R2, recorte de varianza por caja y FXAA integrado; bloom con halo compacto sin artefactos lineales; exposición automática adaptativa con rango dinámico; mapeo de tonos fílmico de Hejl 2015 / Reinhard; gradación de color y efecto Purkinje nocturno.
- **Efectos identitarios:** menas minerales con emisión selectiva en la gema, aislamiento de color para desaturación cinematográfica selectiva del mundo, y rayos crepusculares proyectados desde las figuras del fractal.
- **Vegetación ondulante:** movimiento de follaje y plantas sincronizado con el viento en la etapa `vertex` de Horizon.
- **Dimensiones alternativas:** soporte específico para la atmósfera densa y rojiza del Nether (bruma sofocante) y la niebla estocástica del End con rotación en el vacío.
- **Clima:** lluvia y nieve con partículas densas, atenuación de luz ambiental, formación de charcos reflectantes y oscurecimiento de superficies mojadas.

### Presets de calidad y de estilo

Para ajustarse al límite estricto de **64 opciones** del manifiesto de Horizon (`horizon-shaders.toml`) sin perder la riqueza de ajuste del original (que disponía de más de 400 parámetros):
- **Presets de calidad (7 opciones):**
  - `calidad_general`: selector maestro de cuatro niveles (Baja, Media, Alta, Ultra) que gobierna globalmente la fidelidad visual.
  - Seis presets por subsistema: `calidad_sombras` (muestras de búsqueda, filtro y penumbra), `calidad_niebla` (pasos de raymarch y alcance), `calidad_nubes` (número de pasos y capas de cúmulos), `calidad_ao` (muestras en pantalla), `calidad_reflejos` (pasos de trazado en pantalla y umbral de rugosidad) y `calidad_fractal` (pasos y resolución del raymarch fractal).
  - Absorción de parámetros dispersos del menú hacia los presets manteniendo su equivalencia técnica.
- **Presets de estilo (17 opciones):**
  - Selectores `choice` que agrupan parámetros artísticos coherentes: `estilo_cielo` (color de aire y bruma Mie), `estilo_niebla_horaria` (densidades horarias y niebla con lluvia), `estilo_tiempo` (cobertura y densidad de nubes), `estilo_color` (balance de blancos, diafonía y contraste), `estilo_agua` (claridad, turbidez y absorción RGB), `estilo_luz_bloque` (temperatura de color de fuentes de luz), `estilo_noches` (brillo lunar y seguimiento de fase), `estilo_fractal` (dibujo continuo vs entero), `estilo_aurora` (amplitud y cortina), `estilo_rayos` (enfoque y dramatismo), `atmosfera_nether` y `estilo_cuevas` (curva de oscuridad en cavernas).
  - Estructuración del menú en pantallas temáticas organizadas ocupando exactamente **64 de las 64 opciones disponibles**.
  - Migración de las opciones individuales restantes a constantes con nombre en `opciones/*.wgsl` preservando intactos sus valores por defecto.

### Relieve geométrico (`[displacement]`)

Implementación del relieve LabPBR mediante la etapa de teselación geométrica en GPU de Horizon (`[displacement]`), reemplazando el clásico *Parallax Occlusion Mapping* (POM) por trazado de rayos en fragmentos:
- **Geometría real:** subdivisión de caras de terreno sólido en una cuadrícula de 16×16 celdas, desplazando los vértices a lo largo de la normal según el mapa de altura LabPBR (`_n.png` alfa).
- **Autosombra real:** la geometría desplazada interactúa de forma nativa con el mapa de sombras (`[shadow]`), generando autosombras y sombras arrojadas físicamente correctas sobre bloques adyacentes sin coste de raymarching por píxel.
- **Normalización de altura (`OPC_RELIEVE_PISO_ALTURA = 0.85`):** reescalado de las alturas LabPBR para maximizar la definición en paquetes de recursos (como VibrantPBR) que concentran la profundidad en el rango superior [0,85..1,0].
- **Atenuación suave:** transición cuadrática con la distancia (hasta 12 bloques por defecto, 6 en calidad Baja) para evitar saltos o desconexiones en la geometría distante.
- **Control en menú:** opción directa `relieve` (0,00 a 0,50 bloques) para graduar o desactivar el efecto.
- **Vista de depuración:** modo `OPC_VISTA_RELIEVE = 7u` para verificar factores de desplazamiento (`MaterialInput.displaced`), alturas LabPBR leídas y presencia de mapas PBR.

### Luz en la mano

Soporte de iluminación dinámica en primera persona y entidades sostenidas:
- Integración de `MaterialInput.colored_light` en `adaptadores/material.wgsl`.
- Las fuentes de luz sostenidas en la mano o arrojadas proyectan su color e intensidad sobre las superficies cercanas.
- La luz de la mano se suma aditivamente a la iluminación de bloques del material, compartiendo la escala de colorimetría física y los multiplicadores de intensidad del pack.
- Controlable desde el menú mediante la opción `luz_mano` (Apagada, Normal, Linterna).

### Sombras configurables

El mapa de sombras de Horizon ahora se puede configurar dinámicamente desde el menú:
- `sombras_resolucion`: elección de resolución del mapa de sombras (1024, 2048 o 4096 texels) mediante `[shadow] resolution_option`.
- `sombras_distancia`: alcance del mapa de sombras desde la cámara (64, 128, 192 o 256 bloques) mediante `[shadow] distance_option`.
- Adaptación en tiempo real en los shaders: `adp_texeles_por_bloque`, el sesgo geométrico y el radio del disco de Vogel se recalculan instantáneamente a partir de `frame.shadow_resolution` y `frame.shadow_distance`.

### Lo que se sabe que falta

#### Niveles de presets de estilo pendientes (`docs/efectos/estilo.md`)
Algunos niveles de presets de estilo están declarados en el menú pero permanecen en espera de soporte de motor o desarrollo de pasadas específicas:
- `estilo_biomas` (Sutil, Marcado): requiere datos de biomas por vértice o fragmento que Horizon aún no expone en la API `frame` estándar (se completará con el mod nativo de Horizon).
- `efectos_camara` (Sutiles, Cine): efectos de grano de película, aberración cromática analógica y bandas negras de cine, pendientes de una pasada de post dedicada.
- `profundidad_campo` (Suave, Fuerte): desenfoque de lente (*Depth of Field* / bokeh) basado en círculo de confusión (*CoC*), pendiente de pasada de post dedicada.
- `efectos_juego` (Sutiles, Intensos): efectos visuales de daño, salud baja/crítica y pantalla en llamas, a la espera de que Horizon exponga el estado del jugador en `frame`.
- `estilo_fractal` (Bandas, Salpicadura): modos de coloreado y relleno de conjuntos de escape alternativos en el núcleo matemático fractal.
- `tormenta_end` (Tormenta): generación estocástica de relámpagos procedurales en el vacío de la dimensión del End.

#### Límites conocidos de Horizon (API 0.1)
- **Tope de 64 opciones:** el manifiesto de Horizon no admite más de 64 opciones en total, requiriendo unificar controles en presets y delegar parámetros finos a constantes en código o al futuro mod nativo.
- **Límite de 4 render targets:** las pasadas de post-procesado están limitadas a un máximo de 4 destinos de color propios.
- **Sin sombras en clima:** la etapa `weather` no dispone de acceso al `shadow_map`, por lo que las partículas de lluvia y nieve no pueden recibir sombras directas arrojadas del sol/luna.
- **Variables de juego en `frame`:** ausencia de variables de vida, efectos de estado y día acumulado del mundo en la estructura `Frame` (las estaciones actualmente son fijas sin el mod nativo).
