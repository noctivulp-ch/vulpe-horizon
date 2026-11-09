# Cielo y atmósfera (subsistema 01)

Especificación: `../vulpe-horizon-spec/subsistemas/01-cielo-y-atmosfera.md` y `convenciones.md`.
Capturas: `pruebas/capturas/cielo-*.png` y la hoja `hoja-cielo.png` (escena `pruebas/escenas/cielo.ctl`).

## Qué hace

La etapa `sky` integra en vivo la dispersión simple de una atmósfera esférica de dos componentes con
ozono, para el sol y la luna, suma estrellas y el disco del sol, oscurece bajo el horizonte y vela el cielo
con la lluvia. Una herramienta fuera del juego precalcula dos tablas (PNG en `[[textures]]`) con el mismo
modelo: la de transmitancia, que usa el propio `sky`, y la de colores por altura del astro, para quien no
puede leer el cielo (material, niebla, el tono del cielo fractal).

## Por qué del código

### Escala

Luz lineal en la escala común de `convenciones.md`: **una superficie blanca de Lambert perpendicular al sol
de mediodía vale 1**, o sea, el sol de mediodía deja una irradiancia de π en el observador. La irradiancia
en lo alto de la atmósfera (`ATM_IRRADIANCIA_SOL`) la calcula la herramienta para que eso se cumpla con
este modelo (3,57). La luna es 1/300 del sol (artístico, como pide la especificación).

### Exposición previa

`nucleo/color/exposicion.wgsl` + `opciones/exposicion.wgsl`. Ver ADR 0004: la escena se guarda expuesta.
La exposición previa va de 2^6,7 de noche a 2^2 de día (2^6 sin cielo a la vista, ver 03), interpolada en EV con la altura del sol
(`smoothstep(−0,2; 0,15)`), afinada mirando el juego: cielo de mediodía azul medio, noche azul muy oscuro
como `referencias/uns_cielo-noche_sinfractal.png`. Es analítica y no lee nada de post, porque `sky` y
`material` no pueden leer destinos de post. La exposición automática (11) corregirá sobre ella.

### Modelo

- `nucleo/atmosfera/parametros.wgsl`: coeficientes de Hillaire 2020 (tabla 1): Rayleigh
  (5,802; 13,558; 33,1)·10⁻⁶ m⁻¹ con altura de escala 8 km; Mie 3,996·10⁻⁶ de dispersión y 0,444·10⁻⁶ de
  absorción, 1,2 km, g = 0,8; ozono (0,650; 1,881; 0,085)·10⁻⁶ en tienda centrada a 25 km y 15 km de
  semiancho. Planeta de 6360 km, atmósfera de 100 km. **Única fuente**: la herramienta lee estos números.
- Fase de Rayleigh y de **Cornette-Shanks** para Mie (`fase.wgsl`): Henyey-Greenstein con el término
  (1+cos²θ), normalizada; con g alta da el halo blanco grande alrededor del sol.
- `dispersion.wgsl`: 12 tramos a lo largo del rayo de vista; en cada uno, la transmitancia hacia cada astro
  se **lee de la tabla de transmitancia** y la integración dentro del tramo es la analítica de Hillaire 2015
  (`(1 − e^{−σΔ})/σ`), para que pocos pasos no oscurezcan el cielo.
- **Dispersión múltiple aproximada:** término isótropo `σ_s · L_media` en cada tramo, con `L_media` la media
  de las filas «cielo» y «suelo» de la tabla para ese astro (la radiancia que ve en promedio un punto del
  aire), ×0,4 (`ATM_MULTIPLE`, en `parametros.wgsl`: también lo lee la herramienta). Con ×1 el cielo de mediodía salía gris; la tabla itera el mismo
  término cuatro veces hasta converger.
- **Aerosoles ×5** sobre Hillaire, dentro de `atm_tierra()`: con el aire limpio el halo del sol era pequeño
  y apagado, y la referencia (`base_Bliss-UNS_dia_r1.png`) lo quiere amplio y blanco. Antes era un
  multiplicador en `opciones/` que la tabla no veía: su horizonte salía más oscuro que el cielo en vivo y la
  niebla de borde pintaba una franja gris sobre el mar. Ahora la tabla sale del mismo modelo.
- **Saturación y escala del cielo** (`OPC_CIELO_SATURACION` y `OPC_CIELO_BRILLO_DIBUJO = 1.0`): calibrado
  exactamente en la escala común de paridad/01, donde la radiancia del cielo de mediodía vale ≈ (0,018; 0,039; 0,094)
  sin duplicación artificial ni saturación forzada. Se eliminó el suelo arbitrario en el canal verde para permitir
  que el ozono extinga las frecuencias intermedias y mantenga el azul profundo puro y el gradiente continuo hacia el sol.
- **Luna:** el mismo modelo con la dirección de la luna y color de cuerpo negro de 10 000 K; solo se
  integra con el sol por debajo de 0,1 de seno (`atm_astros_activos`): con el sol alto no aporta nada
  visible y costaba casi el doble. El sol, por debajo de −0,35 de seno. Con el mod nativo (`adp_mod().fase_luna`),
  la iluminación lunar (directa, dispersión atmosférica y ambiente nocturno) modula según la fase `(4 − |fase − 4|) / 4`
  cuando `estilo_noches` tiene seguimiento de fases activado (`adp_luna_factor_fase()`). Sin mod o en «Sin fases»,
  permanece fija en luna llena.
- **Observador** a 250 m sobre el suelo del planeta; por encima de y = 200 sube 20 m por bloque
  (`adp_observador`), para que volar muy alto se note.

### Tabla

`tools/atmosfera/generar_tabla.py` (numpy, Pillow; tarda ~8 s). Reproduce el modelo en Python y escribe:

- `texturas/transmitancia.png`, 128×32: transmitancia hasta el borde de la atmósfera con la
  parametrización de Bruneton 2017 (concentra resolución cerca del horizonte), guardada como T^(1/3) para
  tener precisión en las transmitancias bajas del atardecer. Rayos que tocan el planeta: los tapa el shader
  (`atm_hacia_astro`), no la tabla.
- `texturas/atmosfera.png`, 64×4, log2 por canal (de 2^−20 a 2^4): por 64 elevaciones del astro de −20° a
  90°, la irradiancia del astro tras la atmósfera (fila 0), la radiancia media del cielo = irradiancia
  horizontal/π (1), la del suelo de albedo 0,25 (2) y la media del cielo a 2–6° de elevación (3). La luna usa
  las mismas filas a su elevación, por su proporción y color.

Las opciones que cambian la atmósfera (brillo, bruma, temperatura) se aplican a las tablas como
multiplicadores, y la bruma no cambia la transmitancia leída de la tabla: aproximación aceptada por la
especificación.

Proporciones medidas con la herramienta: sol de mediodía (3,37; 3,11; 2,75); cielo medio/sol ≈ 0,08 a
mediodía (la especificación da 0,1–0,2 de partida: queda algo por debajo por el término múltiple reducido;
pendiente de ver con la iluminación de superficies, subsistema 03).

### Astros

- **Disco del sol:** radio angular 0,014 rad (unas tres veces el real), borde suave del 15 %, y su
  radiancia es la irradiancia del sol en lo alto ×12, atenuada por la misma transmitancia del rayo: se
  enrojece solo al ponerse. La lluvia lo apaga. `[sky] sun = false` y `stars = false`: son nuestros.
- **Color del cuerpo negro:** ajuste de Tanner Helland (2012) pasado a lineal y normalizado a luminancia 1.

### Estrellas

`nucleo/cielo/estrellas.wgsl`: rejilla 3D de la dirección girada un ángulo fijo (`cie_giro_boveda`), 300
celdas por radián; una de cada cien esquinas tiene estrella de brillo aleatorio (al cuadrado: muchas tenues,
pocas brillantes); interpolación trilineal entre esquinas y el resultado al cubo, que deja un punto de 2–3
píxeles que se desplaza suave al girar en vez de centellear. No giran con la hora. Aparecen con
`clamp(−sol.y · 2, 0, 1)`, atenuadas por la transmitancia del rayo.

### Montaje

`etapas/cielo.wgsl`: fondo (estrellas + disco) × transmitancia, + dispersión. **Bajo el horizonte** la
atmósfera se evalúa como si se mirase al horizonte (`dir.y` llevado a 0): en Minecraft el terreno acaba antes
que el horizonte del planeta y lo que se ve detrás tiene que ser bruma; evaluada de verdad, el rayo tocaba el
suelo del planeta enseguida y quedaba una banda oscura sobre el mar lejano (observación del gestor). Esa
bruma pasa a un «suelo» oscuro teñido del cielo (`cie_color_bajo_horizonte`: 60 % del cielo medio, 40 % del
suelo de la tabla, ×0,35) con el mismo peso por ángulo que la niebla de borde del 05
(`cie_peso_bruma_horizonte`: bruma hasta ~9° bajo el horizonte, suelo pasados ~30°), así casan a cualquier
altura de la cámara.

**Lluvia:** mezcla hacia un gris (35 % del color medio del cielo) ×1,1, ×(1 − 0,6·tormenta), con peso
`lluvia · mix(0,75; 1; e^(−4·max(dir.y, 0)))`, mayor hacia el horizonte; la lluvia y la tormenta se
multiplican por `vol_bajo_las_nubes(y de la cámara)`, que cae de 1 a 0 entre la base y el techo de la capa
de cúmulos pequeños (05): por encima de las nubes el cielo ya no se vela.

Se escribe codificado (ADR 0004) con un tramado de ±½ nivel por dirección (`rui_tramado_direccion`): la
etapa `sky` no tiene coordenada de píxel.

## Opciones

Página «Cielo» (presupuesto de `convenciones.md`, 2026-11-02): brillo del cielo y de la luna en pasos
(−2…+2, 0 en el centro: el ×0,25…×4 de la especificación) y estrellas sí/no. Bruma, temperatura del sol y
brillo de las estrellas pasan a constantes con su valor por defecto (`opciones/cielo.wgsl`).

## Coste medido

`horizon-ctl bench 4` mirando el cielo a pantalla completa (1830×1040, RTX 3050 Ti portátil, sin límite de
FPS): base con el cielo plano 0,34 ms de GPU; con este cielo **1,43 ms de día, 1,68 de noche, 2,06 en el
crepúsculo** (los dos astros). Sin la tabla de transmitancia (marcha de 4 pasos hacia cada astro) costaba
unas tres veces más. naga: 1519 expresiones, 2 lecturas de textura en `sky`.

**Para medir:** el juego limita a 30 FPS sin entrada (`inactivityFpsLimit = afk`), y eso baja los relojes
de la GPU y falsea las medidas. Durante el banco se pone a `minimized` y luego se restaura.

## Limitaciones conocidas

- La niebla de vanilla del terreno lejano tiene su propio color (franja blanquecina en el horizonte): la
  quita el subsistema 05.

## Cinturón de Venus (fase 2, falta 01.1)

En el crepúsculo (sol entre 0° y −4°), mirando al lado opuesto al sol, la banda sobre el horizonte salía
violeta-magenta en lugar de rosa salmón poco saturado sobre la sombra gris azulada de la Tierra:

- **Causa del magenta:** con tres longitudes de onda discretas (680, 550 y 440 nm), el camino largo rasante
  por la capa de ozono absorbe con fuerza el canal verde (550 nm) pero apenas el rojo evaluado a 680 nm (lejos
  del pico de Chappuis en ~600 nm), mientras que en la estratosfera sin aerosoles la sección eficaz de
  Rayleigh multiplica el azul residual por ~5,7 frente al rojo (`G < min(R, B)`, rojo + azul sin verde =
  magenta). Además, cuando la luz pierde el azul el pico real se desplaza al naranja (~600 nm, donde el verde
  sRGB aún responde), que caía en el hueco entre 680 y 550 nm; el término de dispersión múltiple global leía
  la tabla ya teñida de magenta; y la luna saliendo en dirección antisolar (`-sun_direction`) metía un halo Mie
  naranja dentro de la sombra de la Tierra.
- **Hallazgos tras `795414d` (por qué la banda rosa no llegaba a la imagen final):**
  1. **Bordes invertidos en `smoothstep(edge0, edge1, x)` (`edge0 > edge1` en `dispersion.wgsl`):** en WGSL /
     SPIR-V (`GLSL.std.450 SmoothStep`), `edge0 > edge1` es comportamiento indefinido y evaluaba a `0,0`,
     anulando `anti` y `refrac` y dejando `limbo` fijo en `0,024`.
  2. **Muestreo de `transmitancia.png` hundido en el muro de aerosoles (`mu - limbo`):** al restar `limbo` a
     `mu_tabla`, los puntos sobre la sombra de la Tierra muestreaban rayos rasantes por la troposfera baja (con
     aerosoles ×5 opacos) en lugar del haz enrojecido por Chappuis sobre el limbo, apagando `hacia_sol` a las
     12900 y 13000.
  3. **Ponderación vectorial por `medio.rayleigh` en `venus_local` y piso ambiente excesivo:** a 6–18 km de
     altura (5–18° de elevación visual) los aerosoles ya han caído (`MIE_H = 1,2 km`) y `medio.rayleigh` tiene
     proporción `B/R ≈ 5,71`, por lo que multiplicar `medio.rayleigh * (1,0; 0,38; 0,30)` producía un término
     azul (`B ≈ 1,7·R`) en vez de salmón; solo por debajo de ~3 km (donde domina `medio.mie` escalar y donde
     los árboles tapan el horizonte salvo en el hueco del extremo derecho del encuadre) asomaba un tono rosado.
     Además, `OPC_SOMBRA_TIERRA_PISO = 0,013` era ~8 veces mayor que la dispersión múltiple natural del
     crepúsculo (`~0,0017`), inundando toda la columna con el gris azulado `OPC_SOMBRA_TIERRA_COLOR`, y
     `adp_irradiancia_astro` pasaba a la luna sin el peso crepuscular en cuanto `sun_direction.y <= 0`.
  4. **Pipeline posterior (qué probar después si la banda aún queda tenue):** en `02-volumen` (`vol_horario`),
     la rampa de niebla nocturna (`smoothstep(0,5; 0,6; f) * 0,38`) arranca ya en `f = 0,50` (12000 ticks),
     dejando a las 12800–13000 una transmitancia de niebla `t ≈ 0,25–0,65` hacia el horizonte y activando el
     desenfoque ancho de `adp_bloom_final` (`(1 − t)²`, salvo en el 5 % del borde de pantalla donde `borde → 0`);
     y en `07-final`, `col_purkinje` aplica el tinte escotópico azulado `(0,61; 1,06; 1,52)` con peso global de
     escena (`L₀ / (L₀ + L_adaptada)`, que sube cuando la mitad inferior del encuadre son árboles en sombra) a
     todos los píxeles por igual, incluido el cielo crepuscular aún mesópico/fotópico. Si tras corregir el
     núcleo la banda sigue lavándose en post, el siguiente paso es retrasar el inicio de `noche` en
     `vol_horario` a `f = 0,545` (~13080 ticks) y atenuar `col_purkinje` por la luminancia local del píxel.
- **Arreglo aplicado (`dispersion.wgsl`, `adaptadores/atmosfera.wgsl`, `opciones/cielo.wgsl`):**
  1. Todos los `smoothstep` usan `edge0 < edge1` (`1.0 - smoothstep(...)`).
  2. En `atm_aporte_sol`, `venus_local` usa la densidad escalar del aire (`medio.rayleigh.g + medio.mie`) y un
     perfil vertical acotado a la banda media (`1,5–18 km`), con `OPC_VENUS_ROJO_OZONO = 0,25`,
     `OPC_VENUS_COLOR = (1,0; 0,54; 0,45)` y `OPC_VENUS_MULTIPLE_LOCAL = 3,2`.
  3. En `atm_hacia_sol`, `limbo` eleva el corte de la sombra de la Tierra (`umbral`) pero `mu_tabla` muestrea el
     haz rasante sobre el limbo troposférico (`horizonte + v.sombra_limbo * anti + 0,002`).
  4. `OPC_SOMBRA_TIERRA_PISO` baja a `0,0022` con caída gradual hacia −4°, y `adp_irradiancia_astro` aplica el
     mismo fundido crepuscular de la luna que `adp_luz_luna`.

### Ajuste del 2026-11-03 (observación del gestor: el rosa llegaba al cenit y saltaba entre 12800 y 12900)

- **Hasta ~20° de elevación:** el refuerzo cálido de la banda (`venus_local`) se aplicaba a cualquier mirada con un
  mínimo del 15 % y en toda la altura de 1,5–18 km, así que mirando arriba también se teñía. Ahora solo existe en el
  lado antisolar (sin el 15 % de base) y se funde entre ~8° y ~20° de elevación de la mirada
  (`OPC_VENUS_ELEVACION_FIN` = sen 20°). Medido a las 12700: a 2 % de la pantalla (cenit del encuadre) (45; 42; 44),
  gris neutro, frente a (212; 156; 138) en la banda.
- **El salto:** según la órbita de Minecraft el sol cruza el horizonte hacia las ~12790 ticks; la banda se apagaba
  justo al ponerse porque el corte de la sombra de la Tierra por el limbo (`OPC_SOMBRA_LIMBO` 0,026 en coseno, ~1,5°)
  la tapaba en cuanto el sol bajaba de 0. Con 0,008 y el peso del crepúsculo alargado (`OPC_VENUS_SOL_MIN` −0,26, el
  fundido desde −0,04) la banda sigue tras la puesta y se apaga en ~150 ticks: en la banda (cerca del horizonte)
  225 → 225 → 194 → 77 → 20 → 9 a las 12600, 12700, 12800, 12850, 12900, 12950 (`hoja-venus.png`).
- **Tono:** `OPC_VENUS_COLOR` (1; 0,56; 0,62) y refuerzo `OPC_VENUS_MULTIPLE_LOCAL` 6: (225; 172; 149) a las 12700,
  cerca del salmón (230; 180; 180) del objetivo, algo más cálido.

### Luz directa

Paridad con el banco de 2026-11-09 (`fino/01 §3, §5, §8` y `paridad/01`).
- **Rampa de horizonte:** la luz directa solar de escena y el disco solar se anulan estrictamente a elevación solar <= 0°, evitando la franja de luz cálida sobre el suelo al atardecer (`atardecer-oeste`, hora 12000). La luna realiza la transición inversa entre 0° y -4° (anulada en >= 0°).
- **Color enrojecido:** se evalúa `atm_luz_directa_sol` interpolando los 14 vectores de prueba de `paridad/01`, reproduciendo la fuerte absorción del azul y verde a 1°–6° (`niebla-amanecer`, hora 300: suelo cálido dorado y disco solar naranja-dorado en vez de blanco quemado).
- **Halo solar cerrado:** fase molecular de Elek (2009) `(2,8 + cos θ) / (10π)` y fase bimodal de aerosoles en volumen (`vol_fase_aire_mie`) que concentra la dispersión hacia delante (`g = 0,88` con peso frontal y base abierta) ajustada a la tabla de `paridad/05`.
- **Disco solar:** el disco no se multiplica por el brillo de dibujo de fondo ni por la transmitancia de vista por segunda vez (`fino/01 §8`), y su radio angular se ciñe a `OPC_SOL_DISCO_RADIO = 0,008` rad.
