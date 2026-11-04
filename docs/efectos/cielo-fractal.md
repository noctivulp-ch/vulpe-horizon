# Cielo fractal (subsistema 02, PROPIO)

Especificación: `../vulpe-horizon-spec/subsistemas/02-cielo-fractal.md`. El modo automático, la proyección,
las paletas y el montaje son código propio de Vulpe y entran con sus valores; el dibujo y el relleno
«Original» se escriben aquí desde la descripción de comportamiento y el algoritmo público de tiempo de
escape. Capturas: `pruebas/capturas/fractal-*.png` y `hoja-fractal.png` (escena `pruebas/escenas/fractal.ctl`,
con campo de visión 110 para ver más cúpula).

## Por qué del código

### Dónde va cada parte

- `nucleo/cielo/fractal_colocacion.wgsl` va en **`shared`**: el sorteo de la noche (cuántas, dónde, qué
  forma, qué tamaño) y «dónde cae y cuánto alcanza la instancia i en esta dirección», que también usarán la
  aurora (06) y los rayos (14) desde `post`.
- `fractal_conjunto.wgsl`, `fractal_paleta.wgsl` y `fractal.wgsl` solo en la etapa `sky` (en su `files`): el
  dibujo cuesta y solo lo hace el cielo.
- `adaptadores/fractal.wgsl` (compartido) arma el sorteo desde `frame.mods` y las opciones;
  `adp_fractal_ajustes`, que necesita los tipos de la paleta, va en `adaptadores/cielo.wgsl`.

### Colocación (modo automático)

Tal cual la especificación §3: semilla de la opción (+ semilla del mundo plegada y + día si «cambios por
noche»), número de conjuntos `1 + ⌊azar · máx · 0,999⌋`, áreas con pesos `0,35 + azar` sobre la cobertura
±5 puntos, radio angular del casquete por área (`acos(1 − área/2π)`, tope 80°), sitio en espiral de
Fibonacci de área igual del cenit hacia el horizonte (`acos(1 − (i+½)/n · 0,82)` y ángulo áureo), forma
en el borde del cardioide (pares) o del bulbo de periodo 2 (impares) un 0–6 % por fuera, una de cada tres
ampliación del Mandelbrot, y el tamaño que pone el borde de la figura en el del casquete.

**Hash propio (cambio intencionado):** en vez del `fract(sin(·)·43758…)` de la referencia, PCG sobre los bits
de la semilla y el índice (`cie_fractal_azar`). Motivos:
1. `sin` de argumentos grandes no está especificado con precisión en WGSL ni en las GPU: el mismo hash da
   números distintos según el fabricante y el controlador (la propia referencia tuvo que plegar la semilla
   del mundo a un rango pequeño por eso). PCG es aritmética entera exacta: el mismo cielo en toda máquina,
   que es lo que hace que «una vez por mundo» signifique algo.
2. Es el hash que ya usa el resto del núcleo (`nucleo/ruido/hash.wgsl`, Jarzynski y Olano 2020).

**Consecuencia aceptada:** la misma semilla **no da el mismo cielo que en Vulpe** (los números al azar son
otros); el reparto sigue las mismas reglas y la variedad es la misma.

**Día del mundo:** `frame.mods[0].z` (número de día, con el mod nativo) + `frame.day_time`. Sin mod el
número de día es 0 y el cielo no cambia entre noches; el salto de la fracción a 0 ocurre al amanecer, de
día, cuando el fractal no se ve.

### Proyección

Cada instancia lleva su matriz de colocación (`Ry(azimut)·Rx(cenital)`); la dirección se pasa al marco de
la instancia con la traspuesta y se proyecta estereográficamente desde el cenit, `q = xz / (1 + y)`. Cerca
de la antípoda la proyección va a infinito: se **desvanece** con `smoothstep(0,02; 0,45; 1 + y)` en vez de
recortar (un recorte dejaba una raya).

### Conjunto

`cie_tiempo_de_escape`: `z ← z² + c`. Julia con `z₀ = p`; ampliación con `c = m + p·k` y `z₀ = c`, con la
prueba del cardioide y del bulbo de periodo 2 antes de iterar (dentro nunca escapa). **Original:** radio 2,
cuenta entera `n/N` con N = 100 (×3 en las ampliaciones); sin escape, 0. Sus escalones son las «líneas»: no
se suavizan (es el dibujo que eligió el usuario). **Suave:** `n + 1 − log2(log2|z|)` con radio 16.

**Mutación:** el parámetro da una vuelta de radio `mutación · s` con `a = día · 2π · 0,35`, `s` 0,01 en las
Julia y `0,02 · k` en las ampliaciones.

### Alcance, relleno y color

- Corte temprano por instancia si `|q|²·4/alcance > 12`: con seis conjuntos un píxel suele caer en uno o en
  ninguno.
- **Relleno Original:** `tono · t² · 2^(−|q|²/alcance) · lejos_del_polo · 4` (la caída cuatro veces más
  ancha que la de corte, y la ganancia 4 que compensa lo tenue de t²). El brillo junto al borde sale del t².
- **Paletas** cosenoidales de Quílez con los valores de Vulpe (aurora, brasa, hielo), monocromo, «del cielo»
  y **«cielo invertido» (por defecto)**: el complementario del tono del color medio del cielo de la tabla de
  la atmósfera (`adp_cielo_medio`). Con la noche azul sale dorado. El contraste es un exponente sobre t
  (0,6) y el color es solo el **tono** normalizado al canal máximo, mezclado con blanco por la saturación
  (70 %).
- **Techo:** Reinhard sobre el canal máximo, conserva el tono.
- **Montaje:** `techo(Σ) · smoothstep(−0,04; 0,12; dir.y) · (1 − |cos(vista, sol)|^(8000/hueco)) · noche ·
  (1 − clamp(estrellas·3, 0, 1))`. Se suma al fondo del cielo (01) antes de la transmitancia de la
  atmósfera, detrás de estrellas, sol y luna. De día no se calcula (`noche` uniforme en pantalla).

### Escala de brillo

`OPC_FRACTAL_ESCALA = 0,8·10⁻⁵` por unidad de la opción Brillo (40 por defecto) y el techo en la misma escala
×4. Primero 1·10⁻⁵ (apenas se separaban del cielo con pocas figuras), luego 2,5·10⁻⁵; el gestor vio esas
figuras más brillantes y opacas que la referencia, que las quiere del orden de las estrellas tenues
(observación del 2026-11-01), y se bajó a 0,8·10⁻⁵.

## Opciones

Presupuesto de `convenciones.md` (2026-11-02), página «Cielo fractal» (8): activado, cambios por noche,
cobertura 5–80 (45), máximo de conjuntos 1–8 (6), semilla 0–15 (8), paleta, brillo 0–200 (40), saturación
0–100 (70). Techo (150), contraste (60), mutación (25), hueco (40) y dibujo (original) pasan a constantes
(`opciones/fractal.wgsl`).

**Omitidas en esta versión** (la especificación lo permite): el modo manual y su figura colocada a mano, y
el relleno «salpicadura» (la especificación no describe su comportamiento: duda pasada al gestor). El dibujo
Suave va **sin el filtro de banda** de la paleta: necesitaría la derivada de t en pantalla, y `fwidth` no es
válido dentro del bucle de instancias con cortes por píxel.

## Coste medido

Mirando al cenit de noche a pantalla completa (1830×1040, RTX 3050 Ti portátil): 3,82 ms de GPU frente a
1,68 sin fractal, **≈2,1 ms** en el peor caso (figura grande llenando la pantalla). Sin lecturas de textura.
naga: el cielo sube a 2368 expresiones.

Posibles recortes si hace falta: calcular solo el eje y el casquete de cada instancia antes de cortar
(ahora se sortea la instancia entera por píxel, unas 36 llamadas al hash con seis conjuntos), o menos
iteraciones en las ampliaciones.

## Comprobado

Semillas 1, 3, 5, 11 y 8: entre una y varias figuras, separadas, de las tres familias (dendritas y
espirales de Julia, ampliación del Mandelbrot con sus bulbos); aparecen con la noche y se apartan de la luna.
Cambiar el `override` en el WGSL no cambia nada: manda el `default` del manifiesto.

## Sorteo frente a paridad 02 (fase 3, 2026-11-04): no se puede reproducir todavía

`paridad/02` da el resultado del sorteo del original por semilla y día (cuántos conjuntos, sitio, forma, desfase de paleta,
giro). Con el requisito de «mismas salidas», la misma semilla debería dar el mismo cielo. El procedimiento está en la
especificación 02 §3 y el nuestro lo sigue; lo que cambia es el hash: el original usa un `fract(sin(·)·43758,5…)` de la
semilla y un índice, y nosotros PCG (decidido en la fase 1 por estabilidad entre GPU: el `sin` de argumentos grandes
redondea distinto en cada una).

**Comprobado** con `tools/paridad/sorteo_fractal.py`: siete combinaciones públicas habituales de semilla e índice dentro del
`fract(sin(·))` no reproducen la tabla (como mucho 4 de 12 en el número de conjuntos y 1 de 39 en el desfase de paleta). La
especificación no da la combinación exacta, y por la regla de la sala limpia no se busca: **duda para A**, que anote en
02 §3 la expresión del argumento del seno y la constante completa. Con ella, la herramienta dirá si se reproduce; si sí, el
sorteo usaría ese hash (con los argumentos pequeños que ya pliega el original, que es lo que lo hace estable) y el PCG
quedaría para lo demás.

### Resuelto (2026-11-04): «Como el original» coincide en esta GPU

A añadió en la especificación 02 §3 el hash exacto, `fract(sin(12,9898·s + 78,233·k) · 43758,5453)`, y en `paridad/02` sus
valores crudos para 6 casos (semilla, día) × 10 índices, medidos en la GPU del dueño (RTX 3050 Ti, OpenGL). Su hallazgo:
el resultado depende del seno de cada GPU (×43 758 convierte una millonésima de error en la tercera cifra), por eso
ninguna combinación evaluada en la CPU podía acertar.

**Comprobado en Horizon, en la misma máquina (Vulkan):** una pasada final temporal pintó cada valor del hash como 16 bits en
blanco y negro (robusto a la viñeta y al tramado), con el argumento calculado como dos productos y luego la suma; leída de
la captura, **coinciden los 60 valores** (p. ej., semilla 8, día 0: k = 1 → 0,353516, 3 conjuntos, como el original).

- **Opción «Sorteo»** (`fractal_sorteo`, página del fractal, 59 opciones): «Como el original» (por defecto, requisito de
  mismas salidas) usa ese hash; «Estable» el PCG de antes, igual en toda GPU pero con otro cielo.
- **Dependencia de la GPU:** «Como el original» da el mismo cielo que Vulpe solo donde el seno de la GPU coincide; en otra
  GPU, o con otro controlador, el sorteo puede cambiar (otra cantidad de conjuntos y otro reparto), igual que le pasa al
  propio original. Si hiciera falta el mismo cielo en todas partes, la salida es que el mod nativo calcule la secuencia en
  la CPU y la pase (decisión del dueño).
- `tools/paridad/sorteo_fractal.py` incluye el hash de la especificación: en la CPU no coincide, como predice A.

**Visto:** `hoja-fractal-sorteo.png` (cenit de noche con campo de 110°, semilla 8, día 0, sin mod): repartos distintos con
«Como el original» y con «Estable».
