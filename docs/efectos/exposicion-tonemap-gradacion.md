# Exposición, tonemap y gradación (subsistema 11)

Especificación: `../vulpe-horizon-spec/subsistemas/11-exposicion-tonemap-gradacion.md`. Capturas:
`pruebas/capturas/imagen-*.png` y `hoja-imagen.png` (escena `pruebas/escenas/imagen.ctl`).

## Pasadas

01 mapa de la aurora · 02 volumen · 03 composición · **04 bloom: bajada (¼, `bloom`)** · **05 bloom: ancho (¼,
`bloom2`)** · 06 TAA (penúltima) · **07 final**. Comprobado en el juego que con las dos pasadas de destino propio
en medio el TAA sigue recibiendo la composición en `previous`.

## Por qué del código

### Exposición

- **Medida** (`img_luminancia_media`): media logarítmica de la luminancia en una rejilla de 8×8 de `history` (la
  salida del TAA, luz lineal), con más peso en el centro (Reinhard et al. 2002). Solo la calculan dos píxeles.
- **Realimentación sin compute:** texeles de esquina, en el alfa (el rgb sigue siendo bloom): (0,0) la luminancia
  adaptada, (1,0) la de los bastones. La pasada 4 lee el estado anterior de la esquina de `bloom2` (aún del
  fotograma anterior), adapta y lo escribe en su esquina; la 5 lo copia a la suya; la final lo lee de `bloom2`.
- **Adaptación:** mezcla exponencial con τ 1,5 s hacia la luz y 4 s hacia la oscuridad; los bastones, 10 s. En
  el primer fotograma o tras una pausa, la medida sin mezclar.
- **Curva:** `k / ln(L + 1 + c)` con k = 0,2 y c = 0,002: E ≈ 3,2 de día (L medida ≈ 0,06) y tope ≈ 100 cuando L →
  0. Medido en el juego: L ≈ 0,0625 de día y ≈ 0,0094 de noche.
- **Calibración (decisión de A, `0fcece2`):** objetivo de brillo medio de la imagen final, medido como media del
  cuarto central de la pantalla (por la viñeta): día ≈ 146/255 y noche ≈ 17–18/255. Ajustado con la exposición
  previa (`OPC_EV_DIA` 3,1 y `OPC_EV_NOCHE` 4,3 tras oscurecer la niebla de noche y darle su tono (05.2)), que entra en la media: medido **148,3 de
  día y 17,3 de noche**.
- **Mezcla con la exposición previa (aceptada por A):** la noche medida es solo ~6,6 veces más oscura
  que el día (la niebla iluminada por la luna y la aurora suben la media), y ninguna curva compresiva puede dar
  más de esa razón de exposición: con la automática sola la noche salía casi negra (E ≈ 18 frente a ≈ 104 de la
  previa analítica, que se había afinado con las referencias). La exposición final es la media en log de la
  automática y la previa (`OPC_EXPOSICION_PESO_AUTO` = 0,5): sigue adaptándose y la noche queda oscura pero con
  el paisaje en silueta y la aurora, cerca de `aurora_off_noche.png`.
- **Visión nocturna** (`frame.night_vision`): exposición ×4 y sin Purkinje. Brillo de Minecraft
  (`frame.brightness`): no se usa.

### Purkinje

Luminancia escotópica aproximada con pesos (0,06; 0,53; 0,41) sobre sRGB lineal y mezcla hacia ella × un azul
pálido (0,4; 0,7; 1,0) normalizado, con peso `L₀/(L₀ + L_bastones)`, L₀ = 0,0015 (de día ≈ 2 %, de noche ≈ 14 %).

### Orden en la pasada final

nitidez → bloom → ceguera/oscuridad → × exposición → Purkinje → balance de blancos (6500 K, neutro) → mapeo de
tonos → saturación y contraste → sRGB → tramado.

- **Nitidez** a la manera de CAS (AMD 2019) con cantidad 0,35, **al principio** sobre `previous` en espacio
  comprimido: la pasada final no puede leer su propio resultado, y la imagen es HDR.
- **Mapeo de tonos:** opción con fílmico (Hejl-Burgess-Dawson, devuelto a lineal para que todos tengan la misma
  firma), ACES (Narkowicz) y Reinhard extendido **sobre la luminancia**. **Por defecto Reinhard** (aceptado por A
  como provisional, con la condición de ir sobre la luminancia y que el día no quede plano). Antes iba sobre el
  canal máximo; sobre la luminancia el cielo sale más azul y luminoso y la hierba más viva (comparados en la misma
  vista). **Prueba que pidió A** con el fílmico y la exposición bajando hasta que el cenit quedara en 0,4–0,6:
  con −2 pasos el cenit vale (0,56; 0,61; 0,69), luminancia 0,6, y sigue azul grisáceo, mucho menos saturado que
  con el Reinhard, y la hierba más oscura: no era solo la exposición, el hombro del fílmico desatura. Sin AgX.
- **Saturación y contraste** (opciones −1…+1, 0) después del mapeo: `mix(luma, c, 1 + s)` y potencia alrededor de
  0,18 con exponente `1 + 0,5·contraste`.
- **Tramado** triangular de ±1 nivel con dos canales del ruido azul.
- **Ceguera y oscuridad:** oscurece con la distancia hasta negro a pocos bloques (sin pulso propio: se usa
  `frame.darkness` tal cual llega).

### Viñeta de Horizon

Medido: después de la pasada final Horizon oscurece las esquinas con la viñeta de vanilla (más de noche). No es
del pack. Al medir valores en pantalla, hacerlo en el centro.

## Opciones

Compensación de exposición (−2…+2 pasos), saturación, contraste (imprescindibles), mapeo de tonos y tramado (de
margen), en la página «Imagen». Constantes en `opciones/imagen.wgsl`.

## Coste

Plano de terreno de día con todo: 7,3 ms de GPU (6,9 sin las pasadas de bloom y exposición). Lecturas: 44 en cada
pasada de bloom, 49 en la final (por sitio en el código; límite 64).

## Visto y no visto

- **Visto:** día con el cielo azul y la hierba saturada; atardecer con halo alrededor del sol; noche oscura con la
  aurora y el paisaje en silueta; **cueva** (caja de piedra construida con `fill` en el aire, sin luz de cielo, con
  una piedra luminosa): oscura y azulada por la luz mínima y el Purkinje, con la piedra luminosa brillando; **al
  salir al sol** deslumbra (imagen lavada, `imagen-salida-cueva.png`) y en unos segundos se adapta
  (`imagen-salida-adaptado.png`).
- **No visto:** la ceguera y la oscuridad del Warden.

## Oscuridad mínima y máxima (fase 2b, punto 5)

Observación del dueño (2026-11-03): «falta poder controlar la oscuridad mínima y máxima y efectos similares». Contra los
inventarios de `paridad/11` (el original deja oscurecer y aclarar la curva de la exposición automática, dos ajustes) y
`paridad/03` (luz mínima en cuevas, al aire libre y en el End):

- **«Brillo de lo oscuro»** (`exposicion_oscuro`) y **«Brillo de lo claro»** (`exposicion_claro`), en pasos de −2 a +2:
  se suman a la exposición según la luminancia media adaptada, en log entre `OPC_EXPOSICION_L_OSCURO` (0,0003) y
  `OPC_EXPOSICION_L_CLARO` (0,03); antes de la primera medida, según la hora (`adp_factor_dia`). **Por qué así y no
  dos multiplicadores de la curva como el original:** nuestra curva es otra (`k / ln(L + 1 + c)` mezclada con la previa),
  y lo que el dueño pide es lo que se ve: lo negra que queda la noche y lo claro que queda el día, cada uno sin mover el
  otro. La compensación general (`imagen_exposicion`) sigue moviendo las dos.
- **«Luz mínima al aire libre»** (`luz_minima_exterior`, 0–1, 0 como el original): era una constante.
- La luz mínima del End sigue en `OPC_AMBIENTE_END` (17).

**Medido** (media del cuarto central, `oscuridad-*.png`, pradera de (170, 77, 166)): de noche 20,0/255 con 0 →
15,4 con −1 y 36,8 con +1; de día 165,0 con 0 y 138,6 con «claro» −1. «Luz mínima al aire libre» a 1 no cambia la noche
con luna (16,0 frente a 20,0, dentro de lo que varía entre capturas): su escala es la de la luz mínima (0,0004), solo
pesa en una noche sin luna ni estrellas.

## Fílmico según paridad 11 (fase 3, 2026-11-04)

`paridad/11` da la salida del fílmico por defecto del original para entradas grises y un naranja. **Encaja con la curva
pública de Hejl (2015)** con punto blanco 3,1, por canal (`col_tonemap_filmico`, `OPC_FILMICO_BLANCO`): error máximo
0,009 en pantalla desde 0,01 de entrada (`tools/paridad/filmico.py`); en 0,005 da 0,002 frente a 0,010. La nuestra era la
racional de Hejl y Dawson 2010, que daba 0,51 en el gris medio frente a 0,54 y 0,95 en 4 frente a 1.

**El cielo gris con el fílmico venía de la exposición, no de la curva** (lo que apuntaba la paridad): nuestro día va a
E ≈ 3, y el cielo llegaba a la curva por encima de 1, donde el fílmico por canal satura y desatura. Con la exposición
×0,5 solo para el fílmico (`OPC_TONEMAP_EXPOSICION` = 0,5; 1 para ACES y Reinhard, cada curva responde distinto en los
medios) el cielo de día queda azul (151, 173, 195 de media en el quinto superior) y la imagen donde la dejaba Reinhard.
**Por eso el fílmico pasa a ser el valor por defecto** (requisito del dueño: mismas salidas), en vez de Reinhard.

**Visto** (`hoja-tonemap.png`: Reinhard, a la izquierda, frente al fílmico, en la pradera de (170, 78, 150), con el
aislamiento apagado; media del cuarto central): día 179 → 183, saturación 59 → 37 (el cielo, algo menos saturado pero
azul); atardecer 136 → 133; noche 36 → 19, más cerca del objetivo de 17 (el pie del fílmico oscurece más que Reinhard). Con
los valores por defecto (aislamiento encendido) 183 / 139 / 21. Con −1,5 pasos el día bajaba a 166 y la noche a 14.

## Velocidad de adaptación medida (F-7, 2026-11-10)

`fino/11 §Medidos 4–5`: el original mezcla la medida nueva un 5 % por fotograma (peso 0,95: constante de tiempo 0,33 s
a 60 fps; 90 % del salto de exposición en 18 fotogramas de oscuro a claro, 72–96 de claro a oscuro por la curva) y los
bastones un 1,5 % (0,985: 1,1 s). El pack llevaba 1,5 s al subir, 4 s al bajar y 10 s en los bastones: entre 5 y 10
veces más lento. Ahora `OPC_ADAPTACION_SUBE = OPC_ADAPTACION_BAJA = 0,33` y `OPC_BASTONES_TAU = 1,1`; la asimetría
subir/bajar sale sola de la curva `k / ln(L + 1 + c)` sobre la luminancia adaptada, como en el original. En el banco
(20 s de espera) no cambia nada; al entrar y salir de una cueva, la adaptación se ve en medio segundo.
