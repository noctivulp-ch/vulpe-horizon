# Aurora del fractal en la niebla (subsistema 06, PROPIO)

Especificación: `../vulpe-horizon-spec/subsistemas/06-aurora.md`. Capturas: `pruebas/capturas/aurora-*.png` y
`hoja-aurora.png` (escena `pruebas/escenas/aurora.ctl`, de noche, campo de visión 110). Todo es código propio
de Vulpe descrito en la especificación; la técnica de distancia es la de Quílez y Hart.

## Qué hay

- **Pasada 1, mapa** (`etapas/post/01-aurora.wgsl`, ¼ de resolución, destino `mapa_aurora`): el cielo fractal
  sobre el disco del cielo con 24 iteraciones (rgb, sin el factor de noche) y la distancia con signo a la línea
  (a). Solo de noche; de día escribe vacío. Las pasadas del post quedan: 01 mapa de la aurora, 02 volumen,
  03 composición, 04 final.
- **Gancho en el volumen** (`nucleo/volumen/aurora.wgsl`, llamado desde `vol_tramo_niebla`): en cada paso de
  la niebla, el tramo exacto que cruza la franja del velo se muestrea con 4 puntos; luz de las cortinas,
  niebla despejada por los conos y bloques de cono atravesados; al final del rayo, la ventana al cielo.
- El destino se llama `mapa_aurora`, no `aurora`: Horizon declara cada destino como identificador WGSL y
  chocaba con la opción `aurora`.

## Por qué del código

### Disco y mapa

Disco del cielo: proyección ortográfica del hemisferio desde el cenit, `(x, z) ↦ (x, √(1−x²−z²), z)`; la uv
de la pasada es el punto del disco (`p = uv·2 − 1`; el destino no es cuadrado y no importa). Color: el
`cie_fractal` del 02 en esa dirección (con la dirección real del sol para el hueco de los astros, noche = 1,
sin estrellas). Línea: la curva de nivel 0,2 de la **silueta** de cada instancia
(`cie_fractal_silueta`: `smoothstep(0,03; 0,30; t)` × caída ancha × lejos del polo, extraída del 02 para
reutilizarla), con un paso de Newton `(m − 0,2)/|∇m|` y gradiente por diferencias finitas de 0,002 en el
disco; la menor en valor absoluto, con signo, acotada a ±1.

Para eso el valor de escape de una instancia sale a `cie_fractal_t` y los ajustes del dibujo del fractal a
`adaptadores/fractal_dibujo.wgsl` (los usan el cielo y la pasada del mapa).

### Velo

Suelo de referencia fijo Y = 70 (o la altura media del terreno del mod nativo, `frame.mods[0].w` con
`mods[1].x` = 1); el velo termina 130 por encima (Y = 200) y su borde superior 96 más arriba (Y = 296).
Perfil: 0 en la base, `smoothstep` hasta el tope, y por encima `2^(−Δy/6)`. La caída de la niebla del 05
empieza en Y = 320 = tope + 24, como pide la especificación.

### Luz, conos, ventana

Tal cual la especificación §4–7, con sus constantes (en `nucleo/volumen/aurora.wgsl`, en mayúsculas): radio
del disco en el mundo 512 bloques (≤ alcance de la niebla), vetas del 30 % con ruido de valor de 6 bloques,
conos desde el tope con radio 1,5 + 1,5·h, el 30 % de la línea con cono (ruido de valor con derivadas
analíticas, `rui_valor2_derivadas`, para la distancia a lo largo de la línea), ruido del despeje de dos
octavas inclinado con la altura y movido con el día, ventana ×2 sumada sin pesarla por la transmitancia.
La normal de la línea sale de diferencias del canal a entre texeles vecinos del mapa.

### Peso de la luz

La especificación suma la luz de cada muestra pesada por `1 − e^(−densidad·(1 − despeje)·largo)`, con la
densidad de la niebla **en las unidades de Vulpe**. Con nuestra extinción física de noche (≈0,0076 por
bloque) ese peso no pasaba de ~0,15 y la luz solo salía donde el rayo recorre mucho velo: un ribete en el
borde de la figura, con el interior oscuro y sin altura (lo vio el gestor). Se multiplica la extinción por
`VOL_AURORA_DENSIDAD` = 25 solo para ese peso: satura casi en cada muestra, como en Vulpe, y la cortina brilla
en toda su altura con el color del mapa en ese punto (también el interior de la figura).

**Escala de la luz:** el mapa trae la radiancia del fractal del cielo (muy baja: del orden de las estrellas
tenues); la emisión es esa × intensidad 600 × 0,5 (`ADP_AURORA_ESCALA`) × el ajuste del usuario. Con 0,01, la
de la especificación tomada literal, no se veía nada en nuestra escala de luz; 0,5 afinado a ojo.

### Ventana

Respuesta de A (especificación 06 §7, `8873b86`): con la dirección de vista el mapa se lee lejos de la línea de la
que baja el cono, donde no hay fractal; por eso no se veía. Ahora se usa **el color del cono**: durante el tramo,
cada muestra acumula el color del mapa en su punto (`rel.xz / R`, la misma lectura que la luz de la cortina)
pesado por despeje × largo, y al final se normaliza por la ventana. El peso es el de Vulpe (ventana / largo del
cono × 2 × ruido del despeje × noche), sumado sin la transmitancia de delante, y el color se escala por la
intensidad de las cortinas × 0,6 (`VOL_AURORA_VENTANA_ESCALA`), como propone A, para que los filamentos dentro del
cono no queden por debajo de la niebla. **Visto:** trazos y puntos brillantes del fractal dentro de los conos,
sobre la cortina (diferencia con «sin ventana» de hasta 135/255, media 4,4; antes 2,7 de puro ruido). Da además
los «puntos y filamentos brillantes sobre una cortina más oscura» que el gestor echaba en falta.

### Depuración

Dos vistas en la opción de depuración del pack (como pide la especificación): «Aurora: conos» suma rojo
proporcional al despeje de cada muestra; «Aurora: sin ventana» quita la ventana.

## Opciones

Las dos imprescindibles del presupuesto (`convenciones.md`), en la página del cielo fractal: aurora sí/no y
brillo relativo (−90 … +200 %, 0). El resto de la tabla de la especificación son constantes.

## Coste

Noche mirando la figura (1830×1040, RTX 3050 Ti portátil): 6,09 ms de GPU con aurora, 5,92 sin ella:
**≈0,17 ms** (mapa y gancho juntos).

## Visto y no visto

- **Visto, con el peso corregido:** la luz llena el cuerpo de las figuras (relleno y filamentos), no solo el
  borde. Con la semilla 3 (varias figuras, algunas altas) la aurora ocupa buena parte del cielo y se ven las
  cortinas verticales como rayas que convergen hacia arriba vistas desde abajo (`aurora-semilla3*.png`). Con
  la semilla 8 (la de por defecto, una figura cerca del horizonte) la huella sobre el velo, que es un plano a
  200–300 bloques de altura, se ve muy escorzada y se lee más como una lámina (`aurora-sur.png`).
- **Conos** (`aurora-conos.png`): zonas y rayos rojos que bajan desde tramos de la línea del fractal, como en
  `dbg_conos.png`.
- **Ventana** (`aurora-sin-ventana.png` frente a `aurora-semilla3.png`): ver §Ventana.
- **No visto:** el suelo medido del mod nativo.
