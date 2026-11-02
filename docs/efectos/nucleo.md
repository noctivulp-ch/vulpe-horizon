# Núcleo, adaptadores y herramientas

Lo que no es un efecto sino la base que usan todos. Escrito sin especificación (paso 1 del encargo); todo
sale de bibliografía pública, citada en cada apartado.

## Por qué del código

### Matemática

- `nucleo/matematica/constantes.wgsl`: π, τ, 1/π y un épsilon para divisiones. `MAT_` por la carpeta.
- `nucleo/matematica/utilidades.wgsl`: saturar, remapear y el **escalón quíntico** `6t⁵−15t⁴+10t³`
  (Perlin, «Improving Noise», SIGGRAPH 2002): a diferencia de `smoothstep`, también anula la segunda
  derivada en los extremos, y el ruido interpolado con él no muestra la rejilla al iluminarlo.

### Proyección

`nucleo/matematica/proyeccion.wgsl`. Horizon da las uv de pantalla con el origen **arriba a la izquierda**
y wgpu usa NDC con y hacia arriba y z en 0..1, con profundidad **invertida** (1 cerca, 0 lejos y cielo).
`mat_uv_a_ndc`/`mat_ndc_a_uv` hacen el volteo de y en un solo sitio; `mat_proyectar` aplica una matriz y
divide por w. La reconstrucción de posiciones en post la hace el adaptador con el ayudante del motor
(`view_position`), porque sabe exactamente qué matriz usa Horizon.

### Ruido

- **Hash: PCG** (`rui_pcg`) y **PCG3D** (`rui_pcg3`), de Jarzynski y Olano, «Hash Functions for GPU
  Rendering», JCGT 9(3), 2020. Elegidos porque el artículo los mide como el mejor compromiso calidad/coste
  en GPU y son enteros (sin los patrones de `fract(sin(x)·43758)` en tarjetas con `sin` de baja precisión).
  Las celdas negativas se reinterpretan con `bitcast`, así no hay simetría en el origen.
  A flotante se toman los 24 bits altos (mantisa exacta de `f32`).
- **Ruido de valor** 2D y 3D con escalón quíntico: el más barato de los suaves (4 y 8 hashes). Si un efecto
  necesita menos artefactos de rejilla (nubes), se añadirá un ruido de gradiente en archivo aparte con la
  misma firma (principio L del ADR 0002).
- **fBm** (`rui_fbm2/3`) con `RuiParametrosFbm` (octavas, lacunaridad, ganancia), normalizado a 0..1 por la
  suma de amplitudes. En 2D cada octava gira ~37° (matriz 0,8/0,6) y se desplaza, para que las rejillas de
  octavas sucesivas no se alineen (práctica habitual, p. ej. Íñigo Quílez, «fbm», iquilezles.org).
- **Tramado: interleaved gradient noise** (Jimenez, «Next Generation Post Processing in Call of Duty:
  Advanced Warfare», SIGGRAPH 2014). Una línea, sin texturas, con buena distribución espacial; se usa para
  romper bandas al pasar a 8 bits (±½ LSB).

### Color

- `col_srgb_a_lineal` / `col_lineal_a_srgb`: la curva exacta por tramos de IEC 61966-2-1, no la potencia
  2,2: la diferencia se ve en las sombras, que es justo donde un shader nocturno vive.
- `col_luminancia`: pesos de Rec. 709 (los primarios de sRGB).
- **Mapeo de tonos intercambiable** (`col_tonemap`, principio L): **Reinhard extendido por canal** (el de
  la codificación del «picture», ADR 0004, y por eso el de por defecto, con su inversa exacta), **Reinhard
  extendido sobre la luminancia** (Reinhard et al., «Photographic Tone Reproduction for Digital Images», SIGGRAPH
  2002, ec. 4; aplicado a la luminancia y reescalando el color para no desaturar) y la **aproximación ACES de
  Narkowicz** («ACES Filmic Tone Mapping Curve», 2015). Todos con la misma firma.
- `col_gradar` con `ColParametrosGradacion`: exposición en EV (`exp2`), saturación respecto a la luminancia
  y contraste como potencia alrededor del gris medio 0,18 (equivale a escalar en log2, que es como lo hacen
  las herramientas de gradación).

**Medido (ADR 0004):** el «picture» del mundo es de 8 bits lineal y guarda valores de pantalla. La escena se
guarda codificada (`nucleo/color/codificacion.wgsl`: sRGB del mapeo por canal de la luz expuesta) y la
última pasada decodifica, grada y vuelve a codificar; con los ajustes por defecto la ida y vuelta es la
identidad salvo el tramado.

### Vistas de depuración

Opción `depuracion_vista` (página Depuración): **Distancia** (`1 − e^(−d/64)` con `d` de
`adp_post_distancia`: comprueba la reconstrucción de posiciones), **Ruido fBm** (5 octavas a 64 px por
unidad, desplazándose con el tiempo: comprueba hash, ruido y fBm) y **Tramado** (el IGN crudo).
Mientras Horizon no aplique valores de opciones distintos del defecto (ver «Not there yet» en su
`docs/api/shaders.md`), se prueban cambiando el `default` del manifiesto con el juego abierto.

### Adaptadores

Uno común (`adaptadores/marco.wgsl`, en `shared`: tiempo, dimensión, factor de día) y uno por etapa, cargado
con el `files` de esa etapa, porque solo esa etapa tiene sus recursos (p. ej. `view_position` solo existe en
post: un adaptador de post en `shared` haría fallar la compilación del cielo). Cada uno entrega un struct
propio (`AdpRayoCielo`, `AdpSuperficie`, `AdpPixel`) y una función `…_salida` que vuelve al tipo del motor;
las etapas no tocan `SkyInput`/`MaterialInput`/`PostInput` más que para pasarlos al adaptador.

### Opciones

`opciones/<efecto>.wgsl` declara los `override` (el nombre es el `id` del manifiesto, prefijado por efecto:
`imagen_…`, `depuracion_…`) y una función `opc_<efecto>()` que los agrupa en un struct. El resto del pack lee
el struct, nunca el `override` suelto: así una opción se renombra en un solo sitio.

## Herramientas

- `tools/montar.sh`: arma `build/vulpe/` (ADR 0003).
- `tools/validar.sh`: `horizon-shader check` sobre el pack montado.
- `tools/probar.sh ESCENA [--dejar-abierto]`: valida, abre Horizon con el pack (o reutiliza uno que abrió el
  propio script), ejecuta `pruebas/escenas/ESCENA.ctl` línea a línea con `horizon-ctl` y deja las capturas en
  `pruebas/capturas/`. Las escenas empiezan con `close` (el mundo creativo abre con el inventario) y
  `key f1 tap` (oculta el HUD).

## Coste medido

`horizon-shader check` (expresiones naga / lecturas de textura): cielo 550/0, material 844/1, final 823/4.
El tiempo de GPU queda por medir con `horizon-ctl bench` cuando haya efectos que cuesten algo.
