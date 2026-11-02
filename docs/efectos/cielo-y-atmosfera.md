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
  aire), ×0,4 (`OPC_MULTIPLE_REFUERZO`). Con ×1 el cielo de mediodía salía gris; la tabla itera el mismo
  término cuatro veces hasta converger.
- **Aerosoles ×5** sobre Hillaire (`OPC_BRUMA_BASE`) por defecto: con el aire limpio el halo del sol era
  pequeño y apagado, y la referencia (`base_Bliss-UNS_dia_r1.png`) lo quiere amplio y blanco.
- **Saturación del cielo** (`OPC_CIELO_SATURACION`): fue ×1,5 mientras la codificación usaba Reinhard por
  canal (comprimía el cenit de ~1 : 2 : 4,5 a ~1 : 1,6 : 2,4); con el Reinhard sobre el canal máximo
  (ADR 0004) vuelve a 1.
- **Brillo propio del cielo dibujado ×2** (`OPC_CIELO_BRILLO_DIBUJO`), no de la luz que da al terreno: al
  encender la luz de superficie (03) la exposición de día bajó de 2³ a 2² para que la hierba al sol no se
  lavase, y el cielo, que se había afinado con 2³, lo compensa.
- **Luna:** el mismo modelo con la dirección de la luna y color de cuerpo negro de 10 000 K; solo se
  integra con el sol por debajo de 0,1 de seno (`atm_astros_activos`): con el sol alto no aporta nada
  visible y costaba casi el doble. El sol, por debajo de −0,35 de seno.
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

`etapas/cielo.wgsl`: fondo (estrellas + disco) × transmitancia, + dispersión; bajo el horizonte un factor
gaussiano de 0,06 de anchura en `dir.y` lleva a un «suelo» oscuro teñido del cielo
(`cie_color_bajo_horizonte`: 60 % del cielo medio, 40 % del suelo de la tabla, ×0,35). El suelo iluminado
de la tabla a secas salía casi blanco con la exposición del día. La dispersión bajo el horizonte se deja
al 60 % (perspectiva aérea hasta el suelo del planeta).

**Lluvia:** mezcla hacia un gris (35 % del color medio del cielo) ×1,1, ×(1 − 0,6·tormenta), con peso
`lluvia · mix(0,75; 1; e^(−4·max(dir.y, 0)))`, mayor hacia el horizonte. Pendiente: anularla por encima de
la capa de nubes cuando exista el subsistema 05.

Se escribe codificado (ADR 0004) con un tramado de ±½ nivel por dirección (`rui_tramado_direccion`): la
etapa `sky` no tiene coordenada de píxel.

## Opciones

Página «Cielo»: brillo del cielo, bruma y brillo de la luna en pasos (−2…+2, 0 en el centro: la regla del
valor por defecto centrado de las convenciones, con el ×0,25…×4 de la especificación), temperatura del sol
4000–8000 K (6000 en el centro), estrellas sí/no y su brillo. El multiplicador de Rayleigh por canal
(prioridad baja) queda fuera para ahorrar opciones.

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
- El lado opuesto al sol en el crepúsculo sale violeta-magenta, más que el rosado del «cinturón de Venus».
