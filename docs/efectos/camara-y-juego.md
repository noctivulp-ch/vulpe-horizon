# Cámara y efectos de juego (subsistema 19)

Especificación: `vulpe-horizon-spec/subsistemas/19-camara-y-efectos-de-juego.md`. Código: `nucleo/imagen/gotas.wgsl`
(puro, sin lecturas de textura), `adp_gotas_camara`, `adp_calor` y la codificación del cruce en `adaptadores/imagen.wgsl`,
el estado en `adaptadores/bloom_estado.wgsl`; constantes en `opciones/gotas.wgsl`; el orden en `etapas/post/07-final.wgsl`.

## Agua en la cámara (sustituye a las gotas de B-15)

- **Memoria**: el téxel (4,0) de `bloom2` guarda en un solo valor el tiempo desde el cruce, si fue salida o entrada y la
  rapidez: `±(1 + 8·nivel + t)`, positivo al salir, 0 sin cruce, con t < 8 s y la rapidez en 8 niveles de 2 bloques/s.
  El (5,0) guarda si la cámara estaba en el agua (`eye_in == 1`) el fotograma anterior: el cruce es el cambio de ese
  valor. La rapidez es `|camera_motion| / delta_time` en ese fotograma. Un solo téxel porque la pasada final iba por
  63 lecturas.
- **Dirección**: la especificación pide la velocidad del cruce proyectada en pantalla y congelada. No cabe en el
  téxel con precisión de 16 bits; se usa el sentido vertical (al salir el agua escurre hacia abajo, al entrar sube).
- **Salida**: dos octavas de ruido de valor a baja frecuencia, estiradas en esa dirección, que escurren; el umbral
  sube de 0,25 a 0,85 en los 5 s y solo quedan las gotas gruesas. Cada punto se acerca al centro una fracción
  `fuerza · gota · rapidez · vida`, con tope 0,5 (la gota más gruesa con el ajuste 50). Un leve oscurecido en el
  borde de las gotas.
- **Entrada**: una onda que se abre desde el centro a 0,5 de pantalla por segundo, de amplitud 0,06 · fuerza.
- **Duración**: 5 s; después nada.

## Calor

`adp_estado_calor` (`adaptadores/bloom_estado.wgsl`) guarda el nivel suavizado (`0..1`) en el téxel `(7,0).a` de
`bloom`/`bloom2`, usando la función pura `img_calor_nivel` (`nucleo/imagen/gotas.wgsl`): sube en `OPC_CALOR_SUBE`
(0,5 s) cuando el jugador arde (`mods[3].z > 0,5` con bit 3 activo del mod) o la cámara está en lava
(`frame.eye_in == 2u`), y baja en `OPC_CALOR_BAJA` (3,0 s) al salir. Sin el mod, el estado «en llamas» queda inactivo
(solo actúa con la cámara en lava).

En la pasada final (`adp_calor` en `adaptadores/imagen.wgsl`), una salida temprana comprueba `opc_calor_fuerza() <= 0`
(opción `efectos_juego`: 0 apagado, 1 sutil ×0,5, 2 defecto ×1, 3 intenso ×1,5) y `nivel <= 0,001` con una sola lectura
uniforme de `(7,0).a`, evitando el ruido procedural y cualquier llamada a `adp_mod()` por píxel cuando no arde. Cuando
está activo, aplica `smoothstep(0, 1, nivel)` al ruido que sube a 0,3 de la altura por segundo, cuadrático hacia abajo
y nulo en el tercio superior, más un acercamiento al centro del 2 % (fuerza 0,7 por defecto). El calor del desierto no
se hace (decisión del dueño, `observaciones-del-dueno-2026-11-13.md` §5.2b).

- Comprobado en `vulpe-pruebas` (`native-dd67b76-9841443bb307`, `pruebas/escenas/calor-llamas.ctl`, 2026-11-19):
  `tools/validar.sh` pasa (Final 64/64 lecturas); en fuego y a 3 s tras salir se aprecia la ondulación y el
  acercamiento al centro (diferencia media 10,81 en el cuadrante inferior derecho frente a 12 s), a 10 s cae a la mitad
  (5,20, en plena bajada de 3 s) y a 12 s desaparece por completo; al entrar en agua se apaga en ~3 s; en lava activo.
  Coste sin fuego (`bench 20` bosque): 48,33 fps, CPU 4,30 ms (`tick` 0,48 ms), GPU 13,60 ms.
- Nota observada al capturar: el efecto previo de gotas de agua en cámara (`adp_estado_cruce`, téxel `(4,0).a`) puede
  quedar atascado tras un teletransporte (`nivel = 7` → valor 57 en `rgba16float`, donde el paso de precisión f16 es
  0,03125 s > `delta_time` a >32 fps). No afecta al téxel `(7,0).a` del calor (rango 0..1, paso f16 0,00049).

## Lecturas de la pasada final

El validador cuenta las lecturas de todo el módulo, no solo las alcanzables desde `post`. Las funciones de las pasadas
de bloom (bajada y ancho, con su estado) se movieron a `adaptadores/bloom_estado.wgsl`, que la final no incluye, y el
alfa de la niebla se toma de la muestra central de la nitidez en lugar de leerlo aparte. La final pasó de 63 a 60.

## Comprobado en Horizon (2026-11-12)

Escena `pruebas/escenas/camara-juego.ctl`: al salir del agua (con `tp`, rapidez máxima) las gotas deforman media
pantalla a 0,3 s, quedan pocas a 1,5 s y ninguna a 3,5 s; la onda de entrada es suave; en lava la imagen ondula
abajo y queda quieta arriba.

## Ajustes de cámara (apagados por defecto)

Constantes en `opciones/imagen.wgsl` (`OPC_CAM_*`), funciones puras en `nucleo/imagen/camara.wgsl`, aplicación en
`adp_desenfoque_movimiento` y `adp_camara_final` (`adaptadores/imagen.wgsl`). Cada uno va tras un `if` sobre su
constante: en 0 el compilador lo quita.

- **Zoom** (`OPC_CAM_ZOOM`, 0..1 → ×1..×4): lo primero, antes del agua y el calor.
- **Desenfoque de movimiento**: la opción del menú `desenfoque_movimiento` ya existía y no hacía nada. Reproyección del
  píxel con la profundidad (`view_position`) y `previous_view_projection` + `camera_motion` (el cielo, a 10 000
  bloques); desplazamiento normalizado a un fotograma de 60 Hz y comprimido `v/(1+4|v|)`; tres muestras más con
  tramado de ruido azul (la cuarta es la central de la nitidez). La mano (más cerca de 0,6 bloques) no se desenfoca.
  Solo mueve la cámara: las entidades que se mueven solas no (Horizon no da vectores de movimiento).
- **Viñeta** (`OPC_CAM_VINETA`): `1 − f·smoothstep(0,5; 1; r)²`, con r 1 en las esquinas; el tramado final evita bandas.
- **Grano** (`OPC_CAM_GRANO`): ruido blanco por canal (hash por píxel y fotograma, ciclo de 60), × brillo, tras el
  tonemap.
- **Bandas de cine** (`OPC_CAM_BANDAS_ALTO` / `_ANCHO`): fracción de pantalla.
- **Líneas de encuadre** (`OPC_CAM_TERCIOS`): regla de tercios de un píxel.
- **No hechos**: la **aberración cromática** (dos lecturas más; cabe, pero se dejó para no cargar la final sin
  pedirlo) y la **profundidad de campo** (la última de la lista; necesita su propia pasada: hay 7 de 8). El modo de
  captura de la profundidad de campo queda fuera (Horizon no tiene jitter).

Comprobado en Horizon (2026-11-12) con todo encendido a mano (`pruebas/escenas/camara-ajustes.ctl`): bandas, viñeta,
grano y zoom visibles; con la cámara quieta el desenfoque no cambia nada. Devueltos a 0 antes del commit.
