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

Especificación 06 §7 y §7 bis, **corregidos por A** (`239f0d0`, `9eeb952`): los puntos nítidos de la referencia son la
ventana, y salen nítidos porque se lee el mapa en la **dirección de vista** (`dir.xz`, el disco del cielo): una lectura
por píxel, sin integrar a lo largo del rayo. Así está ahora. El color de los conos atravesados (lo que había hasta
el 2026-11-02, siguiendo la primera respuesta) queda como alternativa (`VOL_AURORA_VENTANA_CONO`).

Peso: `clamp(ventana / largo_cono, 0, 1) · 2 × ruido del despeje × noche`, sumado al final del rayo sin pesar por la
transmitancia. **Escala:** el color del mapa es el cielo fractal (muy tenue en nuestra escala); sin escalar no se
veía (diferencia 1/255), así que se multiplica por la intensidad de las cortinas × 4 (`VOL_AURORA_VENTANA_ESCALA`),
la vía que da la especificación «en vez de subir VENTANA sin límite».

**Muestreo de la cortina:** comprobado igual que en Vulpe (§7 bis): 4 muestras estratificadas por cuartos del trozo
recortado con desfase áureo, peso casi saturado, y el total por la transmitancia al principio del paso.

### Depuración

Dos vistas en la opción de depuración del pack (como pide la especificación): «Aurora: conos» suma rojo
proporcional al despeje de cada muestra; «Aurora: sin ventana» quita la ventana.

## Opciones

Las dos imprescindibles del presupuesto (`convenciones.md`), en la página del cielo fractal: aurora sí/no y
brillo relativo (−90 … +200 %, 0). Las iteraciones y muestras pasan a depender del preset `calidad_fractal` (Baja: 12 y 2;
Media: 24 y 4; Alta: 48 y 8; Ultra: 96 y 12; ver `docs/efectos/calidad.md`). El resto de la tabla de la especificación son constantes.

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

## Comparación con la referencia, ya con el aislamiento de color (2026-11-02)

`hoja-aurora-frente-referencia.png`: a la izquierda la nuestra (semilla 3, mirando al sur un poco hacia arriba),
a la derecha `referencias/ruidov_noche.png`.

- **Ajustes hechos:** la luz de las cortinas ×3 (`ADP_AURORA_ESCALA` 0,5 → 1,5) y la ventana ×2,5
  (`VOL_AURORA_VENTANA_ESCALA` 0,6 → 1,5): con el 13 en gris y la exposición calibrada (11) las cortinas quedaban
  apenas por encima de la niebla iluminada por la luna; ahora destacan como en la referencia.
- **Probado y descartado:** el mapa a ½ resolución con 48 iteraciones: +0,6 ms y no se gana detalle a la vista.
- **Lo que sigue sin parecerse:** en la referencia, dentro de cada figura se ven **puntos y filamentos nítidos y muy
  brillantes** sobre una cortina oscura con vetas, y el fondo entre figuras es casi negro. En la nuestra la luz sale
  como **manchas suaves** con vetas finas, sin puntos nítidos. Diagnóstico: mirando desde el suelo a ~30° el rayo
  cruza la franja del velo (96 bloques de alto) a lo largo de ~190 bloques horizontales, es decir, ~0,4 del radio del
  disco: cada píxel integra un trozo grande del mapa y el detalle del fractal se emborrona. Sospecho que en Vulpe los
  puntos nítidos son la **ventana** (el fractal visto a través de los conos) o el borde superior del velo con un
  perfil más estrecho. **Duda para A:** ¿de dónde salen los puntos nítidos de la referencia, y cuánto del velo se
  integra por píxel en Vulpe?

## Revisión según la especificación 06 §7 bis (2026-11-02)

**Paso 1, el mapa solo** (vista de depuración «Aurora: mapa», `aurora-mapa.png`, semilla 3, ganancia lineal fija):
filamentos y bordes brillantes sobre negro, con el interior de los conjuntos oscuro; la figura grande de la
izquierda (una ampliación del Mandelbrot) tiene bandas de iteración rellenando el entorno, como la noche 3 de
`hoja-auto.png`. A ¼ de resolución cada téxel son ~4 bloques y se ven los escalones. **El mapa no está en manchas:
el problema no es el mapa** sino cómo se integra y el contraste con la niebla.

**Paso 2, la integración:** cada una de las 4 muestras del tramo **suma** su luz con un peso casi saturado (§6), sin
promediar por la longitud; el perfil es el `smoothstep` de la especificación (la mitad de la luz sale de los ~45
bloques de arriba). **Mejora opcional probada y descartada:** estrechar la banda brillante (perfil a la cuarta,
`aurora-45-perfil-estrecho.png`): el detalle se afila, pero con 4 muestras repartidas en ~120 bloques la banda
estrecha se toca pocas veces, la cortina se apaga y se llena de grano.

**Paso 3, la niebla de noche:** más oscura fuera del halo de la luna: la fase de la niebla pasa a 98,5 % de
Henyey-Greenstein con g = 0,95 (antes 96 % con 0,9) y el ambiente a ×0,005–0,015 del cielo (antes 0,015–0,05). Se
deshacen el ×3 de las cortinas y el ×2,5 de la ventana (vuelven a 0,5 y 0,6). La exposición de noche se reajusta
(`OPC_EV_NOCHE` 5,1) para seguir en el objetivo del 11: **17,9 de noche y 148,3 de día** (media del cuarto central).

**Paso 4, a 45° de elevación** (`aurora-45-grados.png` y `hoja-aurora-frente-referencia.png`, semilla 3, campo de
visión 110): ahora se leen cortinas con estructura (el trazado de las figuras, zonas claras y huecos oscuros, rayas
que convergen hacia arriba) sobre un fondo oscuro. **Siguen sin salir** los puntos nítidos y muy brillantes de la
referencia: a esa elevación cada píxel integra todavía ~0,23 R del disco, unos 30 téxeles del mapa, y el detalle de
un téxel se pierde en la suma. En la referencia la cámara mira al horizonte y la luna no está en pantalla; a las
18000 la luna está en el cenit y su halo entra siempre en la vista a 45°.

**En las condiciones de la referencia** (dato del gestor: hora 14000, sur, horizonte, campo de visión 110; escena
`pruebas/escenas/aurora-referencia.ctl`, hoja `hoja-aurora-frente-referencia.png` con la referencia abajo a la
derecha; semilla 8, la de por defecto, y la de la referencia puede ser otra):
- **Al horizonte:** la disposición se parece: cortinas en la mitad de arriba con vetas verticales marcadas, el paisaje
  oscuro en silueta, sin el halo de la luna en el encuadre.
- **A −40° y −55°:** la figura entera como una banda luminosa con vetas; la luna, baja por el este, entra por la
  izquierda.
- **Lo que falta sigue igual:** la referencia tiene dentro de la figura puntos y filamentos nítidos y muy
  brillantes; la nuestra, luz suave con vetas. El contraste general y la disposición ya se parecen.

**Con la ventana en la dirección de vista** (`hoja-aurora-frente-referencia.png`: arriba a la izquierda antes, arriba a
la derecha después, abajo a la izquierda a −40°, abajo a la derecha la referencia; hora 14000, sur, horizonte, 110°):
en la mitad de arriba aparecen **formas y puntos nítidos y brillantes del fractal** entre las cortinas verticales,
como en la referencia. Se ven algo en escalón (el mapa es de ¼ de resolución). Coste de noche con la aurora a la
vista: 9,4 ms de GPU con todo (campo de visión 110, mirando a la aurora).

## Repaso contra `fino/06` (F-26, 2026-11-11, «La noche de Vulpe»)

- **Ruido del despeje con la altura del mundo** (§1): la inclinación del ruido usaba la altura relativa a la cámara; al
  subir o saltar, las manchas despejadas de la niebla subían y bajaban con el jugador. Ahora `y` es la del mundo (en la
  ventana, la mitad del velo), y la ventana evalúa el ruido donde la visual cruza la mitad del velo con una altura mínima
  de 16 bloques. La segunda octava, `2,13·p + 7,1` (era 2,03 y 11,7).
- **Ventana sin la intensidad de las cortinas** (§4): iba multiplicada por la intensidad (600 × 0,5) y por 4; la
  especificación dice que el color del mapa ya es el cielo fractal con su brillo y su techo, y que la ventana solo lleva
  `clamp(ventana / largo del cono) · VENTANA · ruido · noche`. Se quita `VOL_AURORA_VENTANA_ESCALA`. La ventana queda tan
  tenue como el fractal del cielo, que es lo que se ve por ella.
- Revisado y ya bien: caída de la niebla desde Y = 320 (§2), silueta estrecha (§3, F-25), ganancia de saturación 25 (§5),
  geometría del velo (§6).
- **Duda:** la deriva con el día. El texto de §1 dice «unos 30 bloques en X y 17 en Z por día» (la nuestra, 0,37 y 0,21 de
  ruido de 96 bloques, ya son 36 y 20 bloques), pero la fórmula suma `día · (30; 17)` en unidades del ruido (unos 2 900
  bloques por día) y añade que «100 veces menos» lo congela. Pregunta para A.
