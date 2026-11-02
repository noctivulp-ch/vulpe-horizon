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

**Escala de la luz:** el mapa trae la radiancia del fractal del cielo (muy baja: del orden de las estrellas
tenues); la emisión es esa × intensidad 600 × 0,5 (`ADP_AURORA_ESCALA`) × el ajuste del usuario. Con
0,01, la de la especificación tomada literal, no se veía nada en nuestra escala de luz; 0,5 afinado a ojo.

## Opciones

Las dos imprescindibles del presupuesto (`convenciones.md`), en la página del cielo fractal: aurora sí/no y
brillo relativo (−90 … +200 %, 0). El resto de la tabla de la especificación son constantes.

## Coste

Noche mirando la figura (1830×1040, RTX 3050 Ti portátil): 6,09 ms de GPU con aurora, 5,92 sin ella:
**≈0,17 ms** (mapa y gancho juntos).

## Visto y no visto

- **Visto:** la luz con la forma y el tono del fractal dentro de la niebla nocturna, donde está la figura (al
  sur con la semilla 8), con huecos; nada al norte (sin figura); de día no corre.
- **Diferencia con la referencia** (`ruidov_noche.png`): allí son **cortinas verticales** con vetas que bajan
  desde las figuras; aquí se lee más como una **lámina horizontal** brillante con la silueta del fractal. Sin
  resolver: puede ser la escala de la luz frente a la del borde superior, el ancho del velo visto desde el
  suelo o la poca niebla de la franja (σ ≈ 0,0076).
- **No visto:** la ventana al cielo de forma clara (los huecos se ven oscuros), el despeje en detalle con la
  depuración de conos (no implementada) y el suelo medido del mod nativo.
