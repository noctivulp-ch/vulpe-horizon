# Niebla volumétrica y nubes (subsistema 05)

Especificación: `../vulpe-horizon-spec/subsistemas/05-niebla-y-nubes.md`. Capturas: `pruebas/capturas/niebla-*.png`
y `hoja-niebla.png` (escena `pruebas/escenas/niebla.ctl`).

## Qué hay y qué falta

Pasada 1 a media resolución con destino propio `volumen` (rgb luz ya expuesta, a transmitancia): aire
(perspectiva aérea, solo delante del terreno), niebla global uniforme y en manchas con su horario, caída con
la altura desde Y = 320, y tres capas de nubes (cúmulos pequeños y grandes, altoestratos) con perfiles de
tiempo sorteados por día y de lluvia, en un solo raymarch con una sola transmitancia. Sombra del mapa en
cada paso de la niebla y sombras de nubes. Pasada 2 de composición: decodifica la escena (ADR 0004),
reescalado bilateral por profundidad, niebla de borde. `[material] fog = false`: la niebla de Horizon ya no
se aplica. También cierra dos pendientes: las **sombras de nubes** del 04 en el material, y la **lluvia
sobre el cielo, que se desvanece por encima de la capa de nubes** (01).

**Ganchos:** el de la aurora (06) está en `vol_tramo_niebla` (ver `docs/efectos/aurora.md`); los rayos del
fractal (14) ya no van en este bucle (son un desenfoque radial de la pasada final). **Fuera por ahora:** el primer paso se desplaza con
ruido azul desplazado con R2 (09, `adp_ruido_azul`). Con IGN se veían **estrías paralelas** dentro de las nubes
(observación del gestor): su estructura diagonal se alineaba entre píxeles vecinos.

## Por qué del código

### Pasadas

`etapas/post/02-volumen.wgsl` (`output = "volumen"`, `scale = 0.5`), `03-composicion.wgsl`, `04-final.wgsl`
(la 01 es el mapa de la aurora, 06).
La composición lee la escena de `scene_color`, no de `input.color`: tras una pasada con destino propio no
está claro qué le llega en `previous`, y así no depende de ello. Sale **luz lineal en coma flotante**; la
final ya no decodifica, solo expone, grada y mapea.

### Ruido

`tools/ruido/generar_ruido.py` escribe `texturas/ruido2d.png` (256², repite: fBm de gradiente a tres escalas y
Worley) y `texturas/ruido3d.png` (atlas de 32 cortes de 32×32 de un volumen que repite en los tres ejes:
Perlin-Worley, dos Worley y un fBm). Con ruido por hash puro (`nucleo/ruido`) cada muestra de nube costaba
decenas de hashes; leído de textura, una lectura. El 3D se lee con trilineal a mano (`textureLoad`, 8
lecturas) para que repita exacto sin sangrar entre cortes del atlas. Las lecturas cuentan por sitio en el
código (medido): el presupuesto de 64 por etapa no aprieta.

### Raymarch (`nucleo/volumen/raymarch.wgsl`)

- **Niebla y aire:** de la cámara a la escena o al **alcance** (512 bloques por defecto, no la distancia de
  renderizado), y nunca por encima del plano de nubes si la cámara está debajo. 8 pasos con reparto
  exponencial `(f^u − 1)/(f − 1)` con f = 10, el primero desplazado por ruido. Integración analítica por
  tramo (Hillaire 2015) con extinción gris.
- **El aire solo delante del terreno:** el cielo (01) ya lleva su atmósfera; integrarlo también en los
  píxeles de cielo lo tapaba con una bruma (visto en el juego).
- **Sombra** del mapa (una comparación por paso) con la posición del mapa calculada en el núcleo con la
  fórmula documentada de la distorsión (`luz_posicion_mapa`); **sombra de nubes** evaluada en los dos
  extremos del tramo e interpolada (varía despacio y evaluarla en cada paso costaba).
- **Tramos ordenados:** la niebla solo existe por debajo del plano de nubes bajas; cada capa de nubes, en su
  losa. Los cuatro tramos (niebla y tres capas) no se solapan: se calculan sus entradas y se integran en el
  orden en que el rayo los cruza, esté la cámara por debajo, dentro o por encima de cada capa
  (`vol_integrar`). Visto en el juego desde Y = 420 (cúmulos grandes encima) y Y = 900 (cúmulos grandes
  debajo, con la cima iluminada, por delante del suelo).
- **Píxeles de cielo mirando hacia abajo** (más allá de la distancia de renderizado): el rayo acaba en el plano
  del mar. Antes seguía 512 bloques bajo el mundo, donde las manchas ya no caen con la altura, y desde encima
  de las nubes daba un velo opaco ruidoso (lo vio el gestor; la causa la encontró una sonda: `manchas` > 0
  por el término de bioma húmedo, `downfall` 0,8 del bosque).
- **Nubes:** 14 pasos por capa baja (8/14/20 por calidad), 3 en los altoestratos. Luz: Beer con
  dos muestras hacia el astro a 8 y 28 bloques **sin erosión** (solo cobertura y forma, como prevé la
  especificación para el presupuesto), fase con «powder», ambiente más oscuro en la base. Hasta 6000
  bloques, fundidas desde la mitad: cerca del horizonte cada paso abarcaba miles de bloques y dejaba vetas.

### Medios (`nucleo/volumen/medios.wgsl`)

- **Aire:** Rayleigh (0,5; 1,2; 2,9)·10⁻⁴ y Mie 1·10⁻⁴ por bloque al nivel del mar, altura de escala 600
  bloques. Afinado a ojo: azula y aclara lo lejano sin velar lo cercano.
- **Niebla nocturna (respuesta de A, 2026-11-02):** tapa el cielo casi entero a propósito (la aurora, 06,
  existe por eso). Uniforme hasta Y = 320 (sin pegarla al suelo: se probó y se deshizo), densidad relativa
  0,38 de noche: σ = 0,0076 por bloque, que da τ ≈ 2,2 al cenit desde Y = 70 (≈11 % de transmitancia; A pide
  10–15 %) y τ ≈ 3,9 hacia el horizonte en los 512 bloques del alcance (≈2 %; A pide < 3 %). **Brillo:** la
  niebla tiene una fase propia (`vol_fase_niebla`: 96 % de Henyey-Greenstein con g = 0,9, el resto difuso y
  hacia atrás) y ambiente ×0,015–0,05 del cielo: fuera del halo de la luna queda más oscura que el cielo
  despejado. Medido en el juego: 16–34/255 lejos del halo frente a 3–17 de `aurora_off_noche.png`; aún algo
  más clara y gris que la referencia.
- **Niebla:** extinción 0,02 por bloque con densidad relativa 1; manchas de ruido 3D (celdas de 96×40×96
  bloques) umbralizadas, que caen por encima del mar + 24; caída global `exp(−0,025·(y − 320))`.
  Luz: sol × sombra × fase + ambiente ×0,1–0,25 (más mirando arriba). El ambiente es bajo a propósito:
  la referencia de noche (`nch_base.png`) es casi negra, con el resplandor de la luna; con más ambiente la
  niebla nocturna salía gris azulada clara.
- **Nubes:** cobertura 2D de dos escalas (zonas de 6000 bloques, forma de 3200 con celdas de ~200) recortada
  por un **gradiente de altura** (base redondeada en los primeros 25 bloques, techo en cúpula):
  `(cobertura − (1 − gradiente))/gradiente` (Schneider y Vos 2015). Sin eso, con densidad casi constante
  en altura, salían columnas de paredes rectas que, vistas desde abajo, convergían en el cenit como rayas.
  Erosión 3D de dos frecuencias en los bordes. Techo que se estrecha desde el 55 % del espesor (desde el 25 %
  salían conos). **Inclinación con el viento:** un 20 % del espesor en la *dirección* del viento; antes usaba el
  desplazamiento acumulado, que crece con el tiempo, y salían lágrimas tumbadas (observación del gestor). Extinción 0,25 por bloque (0,03 los altoestratos): con 0,06
  se veía la columna entera a través de la base.
- **Capas:** base 175 / 450 / 2000 bloques sobre el mar (Y = 63), espesor 100 / 200 / 12.

### Tiempo (`nucleo/volumen/tiempo.wgsl`)

Once perfiles (despejado, cúmulos pequeños, grandes, ambos, altoestratos, mixtos, nublado…) con la
cobertura de cada capa; uno por cuarto de día sorteado con PCG del número de día (`frame.mods[0].z`; 0 sin
mod: se repite cada día), fundido con el siguiente en el último 20 % del cuarto. Con lluvia se mezcla hacia
perfiles de lluvia (cobertura 0,65–0,95, densidad ×1,3–1,8). **Horario de la niebla** (relativo): amanecer
uniforme 0,06 y manchas 0,5; mediodía 0; atardecer uniforme 0,1; noche uniforme 0,38 y manchas 0,15;
transiciones de 0,08 de día. Lluvia: +0,5 uniforme y +0,4 manchas (× opción). Biomas húmedos: más manchas
con `downfall` por encima de 0,85 (pantanos, junglas, manglares; el bosque normal, 0,8, ya no: sus manchas a
mediodía salían como grano en el halo del sol) y temperatura templada. **Tormenta de nieve** (`precipitation == 2` y lluvia): +1,2
uniforme, +0,5 manchas y luz ambiente ×8 (niebla blanca). Vista en un bioma nevado (escena). En cuevas (luz de cielo en la cámara baja) la niebla queda al 5 %.

### Composición y borde

**Cielo bajo el horizonte y borde:** la niebla de borde y el cielo bajo el horizonte (01) usan el mismo peso
por ángulo (`cie_peso_bruma_horizonte`: bruma hasta ~9° bajo el horizonte, suelo más allá de ~30°), así el
terreno que acaba antes del horizonte casa con lo que el cielo pinta detrás, a cualquier altura de cámara.

Reescalado bilateral: los 4 texels vecinos de media resolución pesados por bilineal × `1/(ε + |Δd|/d)` con
la distancia de cada texel reconstruida con `depth_at` y `view_position`. Niebla de borde: el último tercio de
la distancia de renderizado (cilíndrica), solo cerca del horizonte (no mirando arriba ni abajo), nunca en
cuevas, hacia el color del cielo aproximado de la tabla. `color = escena · T + L`.

## Opciones

Presupuesto de `convenciones.md` (2026-11-02): niebla sí/no, calidad (pasos 4–16), cantidad, con lluvia,
**nubes por capas** (apagadas, todas, solo cúmulos, solo altoestratos) y calidad de nubes. Las sombras de
nubes van en la página de sombras (04). Bruma, caída, alcance, viento y tiempo aleatorio pasan a constantes
(`opciones/volumen.wgsl`, en mayúsculas) con su valor por defecto.

## Coste medido

RTX 3050 Ti portátil, 1830×1040, sin límite de FPS. Vista de mañana mirando las nubes con algo de terreno:
4,5–4,8 ms de GPU con todo; volumen ~0,9 ms y composición ~0,2 sobre la misma vista con las pasadas
vacías. Plano de terreno de día: 7,1 ms (6,0 sin el 05). Noche con niebla: +0,9 ms.
