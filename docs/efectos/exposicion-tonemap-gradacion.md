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
