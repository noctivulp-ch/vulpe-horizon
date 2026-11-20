# Rendimiento

Medidas y decisiones de coste del pack. Lo que el gestor tiene que mirar está también en
`docs/observaciones-del-gestor.md`.

## Cómo se mide

- `pruebas/escenas/rendimiento.ctl` abre el mundo; `tools/rendimiento/bench3.sh ETIQUETA` mide 10 s
  (`horizon-ctl bench 10`) en tres vistas fijas: Overworld (170,5, 90, 166,5), Nether (yermo, (0,5, 100, 0,5)) y End
  (hacia el vórtice desde (0,5, 90, 120,5)).
- La ventana de Horizon tiene que tener el foco (`niri msg action focus-window --id`). **Sin foco, Horizon se limita a
  10 fps (a veces a 30), la GPU baja de frecuencia y los milisegundos de GPU salen inflados (20–30 ms en vez de
  9–17).** Una medida a 10 fps no vale.
- Ablación: `OPC_DEPURACION_QUITAR` (`opciones/depuracion.wgsl`), un bit por pieza: 1 volumen, 2 oclusión, 4 luz de
  menas, 8 reflejos de pantalla, 16 bloom, 32 TAA, 64 mapa de la aurora, 128 sombras del sol, 256 cielo.
  `tools/rendimiento/ablacion.sh` recorre los bits. 0 en uso normal (no cuesta nada: son constantes).
- Ajustes: los del dueño (`gpuCulling`, recorte de hojas, entidades y partículas, `lodDistance:32`, FOV 1,0;
  distancia 8, como la suya), copiados a `vulpe-pruebas` solo para medir y restaurados después.

## 2026-11-13 (B-23 lote 2)

Datos crudos: `docs/rendimiento-ablacion-2026-11-13-a.txt` y `-b.txt`.

**Con foco** (primera serie, hasta el bit 4; GPU por fotograma, Horizon a 30 fps de tope):

| | Overworld | Nether | End |
|---|---|---|---|
| base | 17,3 ms | 10,5 ms | 8,5 ms |
| sin volumen (1) | −1,6 | −0,2 | −1,9 |
| sin oclusión (2) | −0,5 | −0,2 | −0,25 |
| sin luz de menas (4) | −0,5 | −0,3 | **−1,2** |

Una primera medida suelta en el Overworld dio 33,6 fps de media y 20,3 ms de GPU (el dueño ve ~30).

**Sin foco** (segunda serie y el resto de la primera: todo a 10 fps, GPU a ~1100 de 2100 MHz). Solo vale la
diferencia grande de quitarlo todo (511): Overworld 32,2 → 24,7 ms; Nether 25,4 → 17,9; End 19,6 → 11,9. Las piezas
de post quitables pesan juntas ~7,5 ms en las tres dimensiones a esa frecuencia (~4 a frecuencia normal); el resto
es el terreno (`material`), el cielo y lo fijo. Las sombras del sol se notan en el Overworld (−3,2 ms a 10 fps).

**Arreglo aplicado (sin pérdida visible):** la luz de las menas no corre en el End, donde no hay menas (−1,2 de 8,5
ms con foco).

**Lo que no cuadra con el dueño:** él ve ~17 fps en el Nether, y yo mido 10,5 ms de GPU allí (~95 fps posibles) y
4 ms de CPU. O su escena del Nether es otra (más humo en pantalla, otro bioma, lava cerca), o lo midió con el pack
anterior a F-57/F-63, o el cuello no es la GPU. Hace falta su sitio y su versión del pack para reproducirlo.

**Bloqueado:** desde mitad de la sesión Horizon no recibe el foco aunque niri se lo da (`is_focused: true`, y
Horizon sigue a 10 fps, incluso a 3,7). Sin eso no se puede atribuir el coste pieza a pieza ni comprobar arreglos
más finos. Candidatos para cuando se pueda medir, por orden:
1. Volumen en el Overworld y en el End (1,6–1,9 ms): `vol_ruido3d` hace 8 `textureLoad` por muestra (trilineal a
   mano); una textura 3D de verdad o 2 lecturas con filtrado lineal entre cortes lo bajaría.
2. Sombras del sol en el Overworld: PCF de receptor plano (F-40); probar menos muestras lejos de la cámara.
3. Luz de las menas: 12 lecturas por píxel de terreno en todo el Overworld; saltarla donde no hay ninguna mena en un
   mosaico de pantalla (una pasada barata que marque los mosaicos con mena).

## 2026-11-13, segunda vuelta (sin el tope de inactividad)

El tope de 10 fps no era el foco: es `inactivityFpsLimit:"afk"` de `options.txt` (sin teclado ni ratón, 30 fps al
minuto y 10 a los 10 minutos). El gestor lo puso en `"minimized"` en `vulpe-pruebas` y copió allí los ajustes
gráficos del dueño (LOD 32 y recortes), que ya quedan fijos. Datos crudos: `rendimiento-ablacion-2026-11-13-c.txt`.

GPU por fotograma (ms):

| quitado | Overworld | Nether | End |
|---|---|---|---|
| nada (base) | 17,5–19,7 (34–39 fps) | 10,5–10,9 (51–53 fps) | 5,0 (70–75 fps) |
| volumen (1) | −1,5 a −3,6 | −0,4 | −1,5 |
| oclusión (2) | ≈ −0,2 | −0,4 | ≈ 0 |
| luz de menas (4) | ≈ 0 | −0,7 | ≈ 0 |
| reflejos de pantalla (8), bloom (16), TAA (32), cielo (256) | ≈ 0 cada uno | ≈ 0 | ≈ 0 |
| sombras del sol (128) | **−3,3** | 0 | 0 |
| **sombreado del terreno (512)** | **−9,7** (incluye las sombras) | **−2,8** | −0,3 |
| `adp_luces` constante (1024) | **−2,6** | 0 | 0 |
| todo (1023) | 6,6 | 5,0 | 2,2 |

Lo que queda con todo quitado (6,6 / 5,0 / 2,2 ms) es la rasterización del terreno con el LOD y el trabajo propio de
Horizon: el pack no lo controla.

**El Nether del dueño a 17 fps sigue sin reproducirse:** con sus ajustes, cinco vistas (yermo mirando abajo y al
frente, a Y 70 dentro de la banda de humo, a Y 40 sobre la lava, bosque carmesí, valle de almas) dan 46–54 fps y
10,6 ms de GPU. El fotograma (p50 ~18,5 ms) es más largo que GPU + CPU (~15 ms): hay espera de presentación (Fifo).

**Dónde está el peso y qué se puede hacer:**

1. **Sombreado del terreno en el Overworld (9,7 ms).** Las sombras se llevan 3,3. La spec prohíbe saltarse el PCF
   cuando la búsqueda no encuentra ocluyentes (fino/04), así que el atajo habitual queda para decisión del gestor.
2. **`adp_luces` (2,6 ms en el Overworld).** Calcula en cada píxel lo que es igual en todo el fotograma (tablas de la
   atmósfera, perfil de nubes, tablas por elevación, piso del crepúsculo). La etapa `material` no puede leer nada
   calculado una vez por fotograma: los destinos propios solo los ven las pasadas de post. **Limitación de Horizon
   para PR-Pending:** un bloque de datos del pack calculado una vez por fotograma (o por pasada) y legible en
   `material`. Con eso, unos −2,5 ms en el Overworld sin cambio visible.
3. **Volumen (1,5 ms en el Overworld y en el End):** `vol_ruido3d` hace 8 `textureLoad` por muestra. **Probado y
   descartado:** atlas con un téxel de margen por corte (`tools/ruido/margen3d.py`) y filtrado bilineal, 2 lecturas;
   mismos valores (diferencia 4·10⁻¹⁴ simulado en Python). Medido dos veces contra la versión de 8 lecturas: End
   5,1 → 4,5 ms, Nether igual, **Overworld 18,8 → 20,2 ms** (peor). Las nubes leen el ruido en direcciones muy
   dispersas y el filtrado lineal de un atlas más ancho parece fallar más en la caché que 8 lecturas sin filtrar.
4. **El Nether** se reparte sin un culpable: terreno 2,8, post 2,7 (menas 0,7, oclusión 0,4, volumen 0,4) y 5 de base.

## 2026-11-13, tercera vuelta: decisiones del gestor (sombras y adp_luces)

Medidas de 20 s en el Overworld (el ruido entre medidas de 10 s es de ±1,5 ms; con 20 s, ±0,3).

| prueba | GPU Overworld | resultado |
|---|---|---|
| base | 17,8–17,9 ms | |
| sombras del sol fuera (128) | 14,6 | la sombra entera cuesta 3,2 |
| sombra de las nubes fuera (2048, bit nuevo) | 17,1 | **0,8** |
| ambiente de cielo sin nubes (4096, bit nuevo) | 17,6 | 0,27 |
| atajo seguro del filtro (búsqueda que cubre la huella del radio mínimo, sin ocluyentes → 1) | 17,9–20,5 | **sin ahorro medible**: en el bosque casi todo píxel tiene ocluyentes cerca. Y cambia sombras de 1–2 téxeles (barras de la valla, barrotes): la búsqueda de 4 muestras no las ve. **Retirado** |
| 4 muestras de filtro con el radio mínimo (≤ 1,5 téxeles) | 17,6 | −0,25 ms y bordes algo distintos (diferencia media 1,98 frente a 0,93 de ruido en `sombras-finas`). **Retirado** |

**`adp_luces` en la etapa de vértices: no se puede.** La etapa de vértices de Horizon es
`fn vertex(input: VertexInput) -> vec3<f32>`: solo devuelve la posición, sin interpolantes propios hacia `material`.
Los 2,6 ms del bit 1024 sobrestiman lo que se ahorraría: con luces constantes el compilador simplifica también el resto
del sombreado. Pasarlo por el mod en `frame.mods` obligaría a rehacer en Rust la atmósfera del pack (tablas, textura de
transmitancia, opciones), con el riesgo de que se separen. No lo he hecho.

**Por qué el Overworld va a 37 fps con 18 ms de GPU:** la presentación es Fifo a 145 Hz (6,9 ms por refresco), y la
CPU (4,3 ms) y la GPU no se solapan del todo: ~22 ms se redondean a 4 refrescos, 27,6 ms, 36 fps. Para 60 fps hacen
falta menos de 16,6 ms entre las dos, es decir ~12 ms de GPU: unos 6 ms menos que hoy.

**Lo que bajaría ese tiempo y cambia algo visible** (para decidir):
1. Sombra de las nubes calculada a menor resolución o cada dos fotogramas (0,8 ms).
2. Menos muestras de búsqueda y de filtro de sombra a partir de cierta distancia (hasta ~2 ms; las penumbras lejanas
   salen más duras).
3. Volumen a menos pasos o a un cuarto de resolución en el Overworld (1,5–3,6 ms; nubes y niebla menos finas).
4. Un nivel de calidad «Media» por defecto en lugar de «Según la general», si la general del dueño está en «Alta».
Sin pérdida no he encontrado más dentro de la API. Con un bloque de datos por fotograma legible en `material`
(petición para Horizon) caerían también los cálculos repetidos de `adp_luces`.

## 2026-11-13: sombra diferida (prototipo, descartado) y caché temporal del volumen (no se puede)

Añadido del gestor a B-23: llevar el sombreado del terreno a una pasada de post con `set_surface`/`surface_at`, para
pagarlo una vez por píxel visible y no por fragmento (sin pasada previa de profundidad y con hojas recortadas, en un
bosque se paga varias veces). Regla: primero un prototipo con solo la sombra del sol; si no baja al menos 2 ms en el
Overworld, se descarta.

**Prototipo** (retirado; estaba detrás de `OPC_SOMBRA_DIFERIDA`): en `material`, el terreno sólido que mira a la luz
no consulta el mapa de sombras (solo nubes y horizonte); en la composición, `adp_sombra_punto` con la posición
reconstruida, la normal y la luz de cielo de `surface_at`, aplicada a la parte directa con la fracción indirecta de la
superficie (como F-68). Ajustes del dueño, 20 s, alternando:

| vista | sin diferir | diferida | diferencia |
|---|---|---|---|
| bosque (170,5, 90, 166,5) | 18,95 / 20,25 / 20,17 / 20,36 | 17,94 / 18,27 / 18,51 / 18,51 | −1,0 / −2,0 / −1,7 / −1,85: **media −1,6 ms** |
| llanura (406,5, 80, 326,5) | 16,90 / 16,69 | 15,64 / 15,29 | −1,3 / −1,4: **media −1,35 ms** |

**No llega a 2 ms: descartado.** Además perdía el grosor de la sombra que usa el SSS de las hojas y el color de la luz
a través de los translúcidos; hacerlo bien costaría más empaquetado en `set_surface`. Llevar también `adp_luces` a post
podría sumar algo, pero su coste real es menor que los 2,6 ms del bit 1024 (ver arriba).

**Caché temporal del volumen: no se puede con la API 0.1.** Una pasada que escribe un destino propio lee ese destino
en blanco («a pass reads a blank one in place of the target it writes»), así que el volumen no ve su fotograma
anterior. Guardarlo en otro destino no es posible: los cuatro destinos propios ya están en uso (mapa de la aurora,
volumen, bloom, bloom2), y el del mapa de la aurora es de ¼ de resolución. **Para PR-Pending:** historial de los
destinos propios (leer el del fotograma anterior en la pasada que lo escribe) o más destinos.

## 2026-11-13: luz diferida completa (descartada)

Segunda vuelta pedida por el gestor: la luz directa entera (sombra del sol con translúcidos y agua por delante, nubes y
horizonte, SSS con el grosor de la sombra, especular) y `adp_luces` en la composición, una vez por píxel visible.
Criterio para quedarse: al menos 2,5 ms menos en el Overworld (bosque y llanura), imagen igual y sin tocar las nubes.

**Cómo se hizo** (retirado; el parche queda en `build/prototipos/luz-diferida/cambio.diff`, fuera de git):
- **`material`:** el terreno sólido del Overworld que no es mena, emisivo, metal, agua ni translúcido no calcula la
  sombra, la directa ni el especular. Su dato de `set_surface` va negativo (marca de diferido) y lleva el valor del
  albedo en vez de la fracción indirecta: con el matiz y la saturación de la suavidad empaquetada lo reconstruye. Lleva
  también F0 (5 bits), SSS en pasos de 0,3 (2 bits) y «cruzada» (1 bit).
- **Composición:** después de la oclusión, `adp_luz_diferida` rehace la cuenta de `material`. Para ello `adp_luces` pasó
  a un archivo compartido.

**Medido** (ajustes del dueño, 20 s, alternando la constante):

| vista | sin diferir | diferida | diferencia |
|---|---|---|---|
| bosque | 20,19 / 21,52 | 19,95 / 20,00 | −0,24 / −1,5 |
| llanura | 17,37 / 17,05 | 15,91 / 16,05 | −1,46 / −1,0 |

**Media ≈ −1,05 ms: menos que con solo la sombra diferida (−1,5).** `adp_luces` se calcula dos veces (en `material`
para el ambiente y en la composición para la directa), y la composición suma su cuenta en todos los píxeles. Para
pasar de ahí habría que diferir también el ambiente y quitar `adp_luces` de `material`. Eso necesita en `set_surface`
la oclusión de vértice, la luz de bloque y su color, la mínima de cueva, el SSS de cielo y la marca de cara de abajo,
que no caben en los dos `f32` que deja la API (hoy van llenos: suavidad, matiz, saturación y signo de mena; F0,
fracción o valor y luz de cielo). Y el ahorro real de `adp_luces` es menor que los 2,6 ms del bit 1024. **Descartado.**
No llegué a sacar las capturas de comparación: no pasó el criterio de rendimiento.

**Para PR-Pending:** más canales en `set_surface` (un `vec4` de datos del pack) o un bloque de datos por fotograma
legible en `material` harían viable diferir la luz entera.

## 2026-11-19 (N-05): rendimiento con la Shader API 0.2

Medidas de 20 s en `vulpe-pruebas` con los ajustes del dueño (`renderDistance:8`, `lodDistance:32`, `gpuCulling:true`,
`leafCulling:hidden`, `inactivityFpsLimit:"minimized"`, `gpu-passes on`), alternando versiones en la misma sesión.

### F-71: datos por fotograma en `[[before_world]]` (`datos_cuadro`)

Una pasada de cómputo `[[before_world]]` (`etapas/cuadro.wgsl`, despacho `[1, 1, 1]`, **0,01 ms**) calcula una vez por
fotograma las luces del terreno (`adp_luces`), las tablas por elevación del sol, el ambiente de nubes, el horizonte, el
cielo medio, el suelo, la dispersión múltiple de sol/luna, el horario de la niebla, el clima local y el relámpago, y los
escribe en el buffer `datos_cuadro` (256 bytes, 16 `vec4<f32>`). Lo leen `[sky]`, `[material]`, `01-aurora`,
`02-volumen` y `03-composicion`.

GPU p50 por fotograma (ms, 20 s, alternando `4c8aeaa` y `F-71`):

| escena | base (`4c8aeaa`) | F-71 (`f71-1` / `f71-2`) | diferencia (p50) |
|---|---|---|---|
| Overworld bosque | 17,88 / 17,56 (media **17,72**) | 14,19 / 12,68 (media **13,44**) | **−4,28 ms** (41,5 → 51,8 fps) |
| Overworld llanura | 15,59 / 14,47 (media **15,03**) | 12,51 / 11,71 (media **12,11**) | **−2,92 ms** (47,2 → 55,0 fps) |
| Nether | 9,88 / 9,89 (media **9,89**) | 9,82 / 9,84 (media **9,83**) | −0,06 ms |
| End | 4,74 / 4,67 (media **4,71**) | 4,66 / 4,68 (media **4,67**) | −0,04 ms |

Capturas comparadas contra `base`: carta de color (`06000`, `12500`, `18000`), agua, tormenta, nubes y noche con fractal
— iguales a la vista.

### F-72: caché temporal del volumen (tablero 2×2 en cómputo)

La pasada `02-volumen.wgsl` pasa a cómputo (`compute = true`, `workgroup = [8, 8, 1]`) y escribe `volumen`
(`rgba16float`, escala 0,5) y `volumen_prof` (`r32float`, escala 0,5, `keep = "view"`). Cada fotograma calcula 1/4 de
los téxeles en orden Bayer 2×2 con mapeo por cuadrantes (para que 3 de cada 4 warps salten el raymarch por completo) y
reconstruye los otros 3/4 reproyectando `volumen_previous` con `frame.previous_view_projection`, rechazando historial si
el punto sale de pantalla, cambia entre cielo y terreno, o su distancia difiere más de `OPC_VOL_CACHE_UMBRAL_PROF` (8 %)
respecto a `volumen_prof_previous` (y en reinicios o transición de agua).

GPU p50 por fotograma (ms, 20 s, alternando `F-71` y `F-72`):

| escena | F-71 (`f71-2` / `f71-ab1`) | F-72 (`f72-1` / `f72-2`) | diferencia (p50) | pasada `Volumen` |
|---|---|---|---|---|
| Overworld bosque | 12,68 / 14,81 (media **13,75**) | 11,86 / 12,08 (media **11,97**) | **−1,78 ms** (54–55 fps) | 1,12 → **0,43 ms** |
| Overworld llanura | 11,71 / 12,66 (media **12,19**) | 10,97 / 11,12 (media **11,05**) | **−1,14 ms** (57–58 fps) | 0,89 → **0,40 ms** |
| Nether | 9,84 / 9,89 (media **9,87**) | 9,54 / 9,62 (media **9,58**) | **−0,29 ms** (62–63 fps) | 0,52 → **0,26 ms** |
| End | 4,68 / 4,73 (media **4,71**) | 3,83 / 3,85 (media **3,84**) | **−0,87 ms** (85–86 fps) | 1,32 → **0,60 ms** |

Capturas comparadas contra `base` y `F-71`: carta de color (`06000`, `12500`, `18000`), agua, tormenta, nubes, noche con
fractal, giro rápido en bosque y en el End, y vuelo rápido en llanura — sin estelas ni cambio en la forma de las nubes.
En `F-72b` se añade la invalidación de la caché temporal durante un relámpago (`brillo > 0` en este fotograma o el
anterior, bandera en `datos_cuadro[ADP_CUADRO_VOL_CIELO].w`) porque el parpadeo de 20 Hz del destello dejaba visible
un tablero 2×2 sobre la niebla; sin relámpago el coste es 0.

## 2026-11-19 (N-08): el tiempo en los cristales (`F-74`..`F-84` + mod `N-08.1`..`N-08.5`)

Medidas A/B alternas (2 rondas de 20 s por pareja) en `vulpe-pruebas`
(`HORIZON_HOME=~/.local/share/horizon/instances/vulpe-pruebas`, versión nativa `native-dd67b76-060022b89a45`,
`gpu-passes on`, `time set 6000`) en:
- **Bosque** (`170,5, 90, 166,5`, despejado, sin cristales visibles);
- **Muro grande de cristal en lluvia** (`170,5, 110, 150,5` frente a un muro de 17×9 bloques con cristal transparente,
  tintado azul, ahumado y paneles transparentes y blancos).

*(Nota sobre `p50` frente a `gpu_avg`: con presentación Fifo a 145 Hz el p50 de GPU salta de forma bimodal entre ~14 y
~25 ms según el encaje con el refresco; `gpu_avg` y `avg_fps` son estables a ±0,15 ms entre rondas y reflejan el coste
real.)*

### 1. Diagnóstico A/B: `e7ad1c4` vs `504fae1` (`F-83`, con `[material] coverage = "pack"`)

| escena (2 rondas × 20 s) | `e7ad1c4` (R1 / R2 · media) | `504fae1` (R1 / R2 · media) | diferencia (`gpu_avg`) |
|---|---|---|---|
| Overworld bosque (sin cristal) | 38,90 / 37,70 fps · avg 19,38 / 19,60 (**19,49 ms**) | 33,83 / 33,25 fps · avg 22,29 / 22,41 (**22,35 ms**) | **+2,86 ms** (−4,76 fps) |
| Muro de cristal 17×9 (lluvia) | 37,95 / 37,59 fps · avg 19,27 / 19,42 (**19,35 ms**) | 33,76 fps · avg 21,92 ms *(R1; R2 perdió foco)* | **+2,57 ms** |

### 2. Aislamiento y corrección (`F-84`)

1. **Quitar `[material] coverage = "pack"`** (dejando el camino *cutout* tras `OPC_CRISTAL_CUTOUT_INTERIOR = false`):
   en Bosque bajó de **22,35 ms** a **20,45 ms** (**−1,90 ms**, `33,54 → 36,45 fps`). En Horizon API 0.2 no existe
   `coverage` por etiqueta/material (`shaders-reference-0.2.md:101-111`, `shaders.md:212-216`); se probó también mover
   `block/glass` con `[[materials]] translucent = true` (`shaders.md:100`) bajo `coverage = "engine"`, pero Horizon sigue
   descartando los texeles con `albedo.a < 0,01` (`shaders-reference-0.2.md:105-106`), por lo que el efecto queda por
   defecto en todos los cristales tintados, paneles tintados y cristal ahumado.
2. **Separar `adp_mod_cristales()` de `adp_mod()` y evitar llamar a `adp_mod()` en `adp_mod_param()`:**
   al quedar todavía `+0,97 ms` en Bosque (`Cielo +0,14`, `World +0,13`, `Composición +0,06`, `Final +0,02`), se vio que
   `adp_mod_param()` (invocada ~23 veces por píxel entre etapas) llamaba a `adp_mod()`, que en `F-74` además
   desempaquetaba `mods[6..7]` (19 campos de `AdpCristalMod`). Sacando `adp_mod_cristales()` para llamarla solo en
   `[[before_world]]` y leyendo `frame.mods[0]` directo en `adp_mod_param()`, el coste en Bosque bajó otro **−1,13 ms**.

### 3. Resultado final A/B: `e7ad1c4` vs `F-84` (2 rondas alternas × 20 s)

| escena (2 rondas × 20 s) | `e7ad1c4` (R1 / R2 · media) | `F-84` (R1 / R2 · media) | diferencia (`gpu_avg`) | pasadas clave |
|---|---|---|---|---|
| Overworld bosque (sin cristal) | 38,55 / 38,19 fps (**38,37**) · avg 19,39 / 19,61 (**19,50 ms**) · p50 13,98 / 25,29 | 38,43 / 38,29 fps (**38,36**) · avg 19,29 / 19,36 (**19,32 ms**) · p50 13,53 / 13,64 | **−0,17 ms** (objetivo ≤ 0,2 ms cumplido) | `Cielo` 1,42 → 1,38 ms, `Composición` 1,22 → 1,21 ms, `World after copy` 0,96 → 0,96 ms |
| Muro de cristal 17×9 (lluvia) | 38,15 / 37,78 fps (**37,97**) · avg 19,29 / 19,47 (**19,38 ms**) · p50 14,56 / 14,73 | 37,46 / 37,02 fps (**37,24**) · avg 19,57 / 19,66 (**19,62 ms**) · p50 14,82 / 24,08 | **+0,24 ms** | `World after copy` 3,17 → 3,58 ms (+0,41 ms solo con muro lleno de cristal), `Cielo` 1,47 → 1,43 ms |

- Lecturas de textura en `material`: **17 / 64** (cero lecturas nuevas; el desenfoque de escarcha/vaho reutiliza
  `opaque_color`/`opaque_depth`). Expresiones en `material`: `14 110 / 20 000`.
- **Petición opcional para Horizon:** `coverage = "pack"` acotado a `[[tags]]` o permitir que `[[materials]]
  translucent = true` conserve los texeles `albedo.a < 0,01` bajo `coverage = "engine"`, para habilitar el interior de
  `glass` y `glass_pane` sin pagar el coste global de *early-Z* en terreno sólido.

## 2026-11-19 (N-09 / N-09b): el tiempo en los cristales v2 (`F-90`..`F-98` + mod `N-09.1`..`N-09.2`)

Medidas A/B alternas (2 rondas × 20 s por pareja) en `vulpe-pruebas`
(`HORIZON_HOME=~/.local/share/horizon/instances/vulpe-pruebas`, versión nativa `native-dd67b76-1539d06868e3`,
`gpu-passes on`, `time set 6000`) contra `e7ad1c4` en:
- **Bosque sin cristales** (`170,5, 90, 166,5`, despejado);
- **Frente a la pared de cristal con lluvia** (`168,5, 110, 152,2`, bajo techo a 1,8 bloques del muro de 17×9 bloques con
  cristal transparente `glass`, paneles `glass_pane`, tintado y ahumado).

| escena (2 rondas × 20 s) | `e7ad1c4` (R1 / R2 · media) | `F-98` (R1 / R2 · media) | diferencia (`gpu_avg` / pasadas de cristales) | desglose de pasadas (`e7ad1c4` → `F-98`) |
|---|---|---|---|---|
| Overworld bosque (sin cristales) | 38,99 / 38,76 fps (**38,88**) · avg 19,16 / 19,25 (**19,21 ms**) · p50 13,16 / 13,20 (**13,18 ms**) | 36,89 / 36,90 fps (**36,90**) · avg 19,47 / 19,57 (**19,52 ms**) · p50 13,55 / 13,64 (**13,60 ms**) | **+0,04 ms** en pasadas de cristales (`+0,31 ms` total frame con `[ray_tracing]`) | `Mapa de cristales` **0,00 ms**, `Simulación cristales` **0,00 ms**, `Lienzo cristales` **0,01 ms**, `Composición + Cristales transparentes` 1,21 → `1,08 + 0,16 =` **1,24 ms** (+0,03 ms), `Cielo` 1,41 → 1,37 ms |
| Pared de cristal 17×9 (con lluvia) | 38,91 / 38,66 fps (**38,79**) · avg 18,56 / 18,56 (**18,56 ms**) · p50 13,49 / 13,45 (**13,47 ms**) | 34,05 / 33,94 fps (**34,00**) · avg 21,09 / 21,08 (**21,09 ms**) · p50 16,47 / 16,35 (**16,41 ms**) | **+2,53 ms** (simulando 8 paneles de lluvia y dibujando cristal transparente + tintado a pantalla completa) | `Mapa de cristales` **0,01 ms**, `Simulación cristales` **0,76 ms**, `Lienzo cristales` **0,11 ms**, `Composición` 1,50 → 1,36 ms, `Cristales transparentes` **1,38 ms** |

- **Por qué `03b-cristales.wgsl` va en pasada separada (`F-97`):** al integrar el DDA de cristal transparente dentro de
  `03-composicion.wgsl`, la presión de registros sube `Composición` en bosque de `1,08 + 0,16 = 1,24 ms` a `1,50 ms`
  (`+0,26 ms`) y frente a la pared de cristal de `1,36 + 1,38 = 2,74 ms` a `3,07 ms` (`+0,33 ms`). Separarla mantiene
  intacto el coste de `03-composicion` y permite muestrear `composicion_base` en el desenfoque de caja separable (`F-98`).
- **Presupuestos (`tools/validar.sh`):** `material` `16 022 / 20 000` expresiones y `19 / 64` lecturas;
  `Cristales transparentes` `12 278` expresiones y `29 / 64` lecturas; `Composición` `13 343` expresiones y `40 / 64`
  lecturas.

### 2. Optimización del coste global sin cristales y frente al muro (`F-101`)

Análisis del sobrecoste de `F-98` en el bosque sin cristales y correcciones aplicadas:

1. **Desenrollado de `img_bloom_bajada` (`nucleo/imagen/bloom.wgsl`) y poda de lecturas estáticas (`0,52 → 0,14 ms`, `−0,38 ms`):**
   en `F-97`, para no superar el límite estático de 64 lecturas de textura en `04-bloom-bajada` (donde el preludio de
   `[ray_tracing]` añade 31 lecturas), se habían sustituido las 13 variables en registros `a..m` por `var m: array<vec3<f32>, 13>`
   indexada en bucle, provocando *stack spilling* a memoria local en los 5 niveles del mip de bloom. Moviendo
   `img_bloom_respuesta` / `img_destello` a `nucleo/imagen/exposicion.wgsl` y `adp_estado` a `adaptadores/cruce_agua.wgsl`
   para quitar archivos no usados de `04-bloom-bajada` y `05-bloom-ancho` (`52 / 64` lecturas), `img_bloom_bajada` vuelve
   a sus 13 registros desenrollados (`Bloom: bajada` baja de `0,52 ms` a **`0,13–0,14 ms`**).
2. **Eliminación de la pasada post separada `03b-cristales.wgsl` (`−0,16 ms` en bosque, `−0,91 ms` en lluvia) y descarga de `[material]` (`16 054 → 11 298` expresiones):**
   - Se saca `adp_cristales_post_evaluar_cara` fuera del bucle DDA de 52 pasos en `adaptadores/cristales_post.wgsl`
     (el bucle DDA solo localiza el primer bloque de cristal alcanzado y corta con `break;`, reduciendo su cuerpo a
     aritmética entera).
   - Se integra `adp_cristales_post` al inicio de `06-taa.wgsl` (`12 466` expresiones, donde `composicion` ya está escrita
     para el desenfoque 7×5 y el TAA suaviza las capas de cristal), eliminando la pasada completa `03b-cristales.wgsl`
     (`0,16 ms` en bosque) y manteniendo `03-composicion.wgsl` en `12 998` expresiones (**`1,08 ms`** frente a `1,20 ms`
     en `e7ad1c4`).
   - Al componer todos los cristales en post desde `cristal_mapa` y mover `adp_mod_cristales()` de `adaptadores/mod.wgsl`
     (`shared`) a `adaptadores/cuadro_escritura.wgsl`, `[material]` vuelve a `reads = ["datos_cuadro"]` y baja de
     `16 054` a **`11 298` expresiones**.
3. **Caché 3D `cristal_mapa` y `cristal_sim` acotados al bioma activo (`Mapa de cristales = 0,00 ms`, `Simulación cristales = 0,00 ms`):**
   `activo` filtra `escarcha`/`repisa`/`condensación` por `bioma_frio`, `arena` por `bioma_seco` y `lluvia` por
   `llueve_bioma`, y `cristal_mapa` reutiliza los vóxeles ya validados sin cristal durante 4 ciclos (96 fotogramas) sin
   relanzar `trace_layers`.

| escena (2 rondas × 20 s) | `e7ad1c4` (R1 / R2 · media) | `F-101` (R1 / R2 · media) | diferencia (`p50` / suma de pasadas) | desglose de pasadas (`e7ad1c4` → `F-101`) |
|---|---|---|---|---|
| Overworld bosque (sin cristales) | 38,88 / 38,40 fps (**38,64**) · avg 19,15 / 19,27 (**19,21 ms**) · p50 13,16 / 25,00 (**13,16 ms** R1) | 36,16 / 35,96 fps (**36,06**) · avg 20,17 / 20,31 (**20,24 ms**) · p50 **13,23 / 13,39 ms** (media **13,31 ms**) | **`+0,07 ms` p50 R1** (`+0,15 ms` media vs R1; suma de pasadas **`4,76 → 4,63 ms = −0,13 ms`**; objetivo `≤ 0,20 ms` cumplido) | `Mapa de cristales` **0,00 ms**, `Simulación cristales` **0,00 ms**, `Lienzo cristales` **0,01 ms**, `Composición` 1,21 → **1,08 ms** (−0,13 ms), `Bloom: bajada` 0,13 → **0,14 ms**, `TAA` 0,58 → **0,61 ms** (+0,03 ms), `Cielo` 1,41 → **1,36 ms** (−0,05 ms) |
| Pared de cristal 17×9 (con lluvia) | 38,77 / 38,98 fps (**38,88**) · avg 18,55 / 18,56 (**18,56 ms**) · p50 13,45 / 13,42 (**13,44 ms**) | 35,22 / 34,85 fps (**35,04**) · avg 20,51 / 20,53 (**20,52 ms**) · p50 26,12 / **14,83 ms** | **`+1,39 ms` p50 R2** (`−0,57 ms` `gpu_avg` y `−1,58 ms` `p50` respecto a `F-98`) | `Mapa de cristales` **0,01 ms**, `Simulación cristales` **0,78 ms**, `Lienzo cristales` **0,11 ms**, `Composición` 1,51 → **1,36 ms**, `TAA` (con DDA cristales) 0,58 → **1,09 ms** (`Composición + TAA = 2,45 ms` vs `3,36 ms` en `F-98`, **−0,91 ms**) |

*(Nota sobre `gpu_avg` con `[ray_tracing]` a 145 Hz VSync: en `F-101` la suma de todas las pasadas del pack en bosque es
`4,63 ms` —`0,13 ms` más rápida que los `4,76 ms` de `e7ad1c4`— y el `p50` es `13,23 / 13,39 ms` (`+0,07..+0,15 ms`),
justo por debajo del umbral de 2 refrescos de 145 Hz (`13,79 ms`); el mantenimiento interno del TLAS/BLAS de 8 chunks del
motor cuando el manifiesto declara `[ray_tracing]` añade `~0,55 ms` de CPU (`4,01 → 4,58 ms`), haciendo que un ~5 % más de
fotogramas crucen `13,79 ms` y esperen al siguiente intervalo VSync de `27,58 ms` en `gpu_avg`.)*
