# Bloom (subsistema 10)

Especificación: `../vulpe-horizon-spec/subsistemas/10-bloom.md` y `paridad/10-bloom.md`. Capturas: `imagen-atardecer.png`
(halo del sol); recorridos `bloom-fuente` (piedra luminosa en una caja oscura a 16, 8, 4, 2 y 1 bloques: `bloom-NN.png`)
y `bloom-niebla` (al aire libre de noche, la luna saliendo y una vista de día: `bloom-niebla-NN.png`, `bloom-luna.png`,
`bloom-dia.png`).

## Por qué del código

- **Sin umbral** (Jimenez 2014): se suma el desenfoque de toda la imagen con peso `0,3 × fuerza × viñeta`, la viñeta
  propia del bloom de ×1,5 en el centro a ×0,5 en las esquinas (0,45 y 0,15: `paridad/10`, medido por extracción).
  Antes era 0,08 fijo. De día aclara el centro de la imagen unos 12/255 (170 → 183 en `bloom-dia.png`, medido
  con el bloom a 0).
- **Pasada 4** (¼, `bloom`): la caja 4×4 compuesta de 13 lecturas desde `history` con el promedio de Karis
  `1/(1 + luma)` en los cinco grupos (`img_bloom_bajada`).
- **Pasada 5** (¼, `bloom2`): **anillos** concéntricos (12) con tantas lecturas bilineales por anillo que no quedan a
  más de ~2 téxeles entre sí, girados por píxel con el ruido IGN; radio 0,06 del alto y gaussiana `exp(−2,5 r²)·(1 − r²)²`,
  que llega a 0 en el borde. **Por qué (observación del dueño, 2026-11-03: al acercarse a una fuente en lo oscuro «se ve
  la dispersión como palitos en vez de crecer como una nube difusa»):** las 32 lecturas de Vogel en un radio de 1/8 del
  alto quedaban a ~10 téxeles unas de otras, y una fuente pequeña y brillante salía repetida en copias. Con 8 anillos
  aún se veían anillos tenues; con 16 era igual de liso que con 12 y costaba ~1 ms más. Cortada en `r = 1` la gaussiana
  valía aún un 8 % y dejaba un disco de borde duro. **Radio 0,06 (antes 0,125):** `paridad/10` mide un halo compacto
  (46 % de la energía en 4 px, 93 % en 32 px, 97,6 % en 0,06 del alto); el radio de 1/8 daba un halo enorme.
- **El alfa de `bloom2`** guarda la opacidad de la niebla **en las fuentes de alrededor**
  (`img_opacidad_fuentes`: media de `1 − T` del volumen pesada por la luminancia, 6 anillos). **Por qué:** el bloom de
  niebla mezclaba hacia el desenfoque según la niebla del propio píxel; de noche el fondo lejano tiene la niebla espesa y
  las hojas cercanas no, así que el halo de una fuente solo aparecía sobre el fondo y quedaba recortado por las hojas:
  un disco desplazado arriba a la derecha de la piedra luminosa (`bloom-niebla-08.png` antes del cambio). La niebla que
  dispersa la luz de una fuente es la que hay delante de ella; ahora se usa la mayor de las dos opacidades.
- **Final:** `mix(ancho, núcleo bicúbico, 0,75) · peso` sumado (el núcleo da la parte compacta del halo,
  el ancho la cola), y el bloom de niebla
  `mix(color, ancho, opacidad²)`, con la opacidad `(1 − T_volumen) · (1 + 0,5·lluvia + agua)` y apagado en el 5 %
  del borde. **Al cuadrado (desviación):** con la opacidad lineal de la especificación, la bruma de día
  (0,2–0,4) mezclaba media imagen con el desenfoque ancho y la lavaba de verde azulado; al cuadrado solo actúa la
  niebla espesa.
- Las esquinas (0,0) y (1,0) del alfa guardan la exposición (11); el rgb no se toca.

### Destello del sol

C-08.2 (2026-11-09), banco `cielo-dia`: el original tiene un destello fuerte y concentrado junto al borde del techo,
con el sol detrás; en el pack el sol apenas se veía. Dos causas:

1. **El disco era 25 veces más pequeño en área y 39 veces más tenue** que el de `paridad/01` (tabla del disco:
   radiancia = 702,9 × luz directa, plena hasta ~0,95° y nula hacia 1,6°). Ahora `OPC_SOL_DISCO_RADIO` = 1,275°,
   `OPC_SOL_DISCO_BORDE` = 0,255 (de 0,95° a 1,6°) y `OPC_SOL_DISCO_BRILLO` = 702,9.
2. **La codificación de 8 bits recorta el disco** (ADR 0004: techo `OPC_BLANCO / exposición previa`, unas 3,7 en la
   escala común de día). El bloom del original trabaja en coma flotante y reparte toda la energía del disco; el del
   pack solo ve el techo, así que por mucho que suba el disco, el halo no crece. `adp_destello_sol` devuelve al bloom
   la parte recortada: `(radiancia del disco × transmitancia del volumen − techo) × parte visible × área del disco ×
   respuesta del bloom`. Se suma a `b` antes del peso `0,3 × viñeta`, igual que el resto del bloom.
   - **Parte visible:** profundidad en el centro y en 8 puntos a 0,7 del radio (`OPC_DESTELLO_MUESTRAS`); con el sol
     tras el borde de un techo, el destello baja en proporción.
   - **Transmitancia:** el alfa del destino `volumen` en el centro del sol: nubes y niebla delante lo apagan.
   - **Respuesta:** `img_bloom_respuesta`, cuatro gaussianas (σ = 0,0022; 0,006; 0,015; 0,04 del alto; pesos 0,55;
     0,25; 0,12; 0,08) ajustadas a la energía encerrada de `paridad/10` (46/70/84/93/97,6 % en 4/8/16/32/64 px a
     1080). Energía total 0,9379 (`OPC_BLOOM_ENERGIA`).
   - Cuenta a mano para el banco (sol a ~55°, sin nubes, entero): exceso ≈ 680, área ≈ 3,9·10⁻⁴; tras el peso del
     bloom y la exposición, blanco hasta ~0,04 del alto y resplandor visible hasta ~0,08. Sin comprobar en el juego.
- Alternativa descartada: subir el peso del bloom o bajar la exposición previa para que el disco no se recorte.
  Lo primero aclara toda la imagen; lo segundo cambia la codificación de toda la escena (ADR 0004) por un píxel.
- Límite conocido: con el sol fuera de pantalla no hay destello (el original sí deja algo de cola en el borde).

## Opciones

Fuerza del bloom (0–4, 1). Bloom de niebla y bajo el agua, constantes.

## Bloom de niebla sin halos en las siluetas (F-11, 2026-11-10)

**Qué se veía** (paneles `banco-2026-11-10`, `cielo-dia`, `nubes-dia`, `atardecer-oeste`, `lluvia-dia`): un halo borroso
de ~6 % del alto alrededor de cada bloque contra el cielo, y las nubes lisas, sin borde. En el original las siluetas y
las nubes son nítidas.

**Causa (dos, las dos nuestras):**
1. Desde 10.1 el peso del bloom de niebla era el máximo entre la opacidad del píxel y la de «las fuentes de alrededor»
   (un desenfoque de la opacidad guardado en el alfa de `bloom2`). Junto a una silueta, el bloque (sin niebla) heredaba
   la opacidad del cielo de al lado y se mezclaba con el desenfoque ancho. El original usa la opacidad **del píxel**
   (`fino/10` §4).
2. La opacidad era la del volumen entero, **nubes incluidas**: donde hay nube la transmitancia es ~0, el peso 1 y la nube
   quedaba sustituida por su propio desenfoque de radio 0,06.

**Ahora:**
- La composición escribe en su alfa la opacidad que pesa el bloom de niebla (`adp_opacidad_bloom_niebla`): sobre el
  terreno, `1 − T` del volumen; sobre el cielo, solo la niebla uniforme del momento hasta su techo (analítica, sin nubes
  ni manchas). El TAA pasa ese alfa y la final lo lee de `previous`. Sale `img_opacidad_fuentes` y su pasada (la final
  baja de 63 a 61 lecturas de textura; las de bloom, de 55 a 53).
- El desenfoque de niebla es `mix(ancho, núcleo, 0,3)` (`OPC_BLOOM_NIEBLA_NUCLEO`): en `paridad/10` el desenfoque de
  niebla del original tiene un pico de 0,38 del ponderado (0,00605 frente a 0,0158), no es solo la cola ancha.
- Sigue al cuadrado (desviación de 10, pendiente del «factor reductor» del original: pregunta para A).

**Lo que se pierde:** el halo de una fuente en la niebla vuelve a depender de la niebla de cada píxel (el «disco
recortado por las hojas» de 10.1); con el desenfoque más compacto se nota menos. **Visto** en Horizon (`banco-f.ctl`,
aislamiento a 0): bloques y nubes nítidos de día, de noche y con lluvia.
