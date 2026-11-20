# Aislamiento de color (subsistema 13, PROPIO)

Especificación: `../vulpe-horizon-spec/subsistemas/13-aislamiento-de-color.md`. Capturas: `pruebas/capturas/aislamiento-*.png`
y `hoja-aislamiento.png` (escena `pruebas/escenas/aislamiento.ctl`: un bloque de redstone de 3×3 y dos flores).

## Por qué del código

`nucleo/imagen/aislamiento.wgsl`, la regla de Vulpe tal cual la especificación: calificador de matiz (distancia en
círculo) y saturación mínima; densidad del entorno con 16 muestras de Vogel de radio 5 px a 1080p con salida a
mitad; mancha con `smoothstep(umbral ± 0,18)` y cierre suave; fuera, 80 % de desaturación con los pesos de Rec.
709; dentro, realce del 30 %. En la pasada final, **después del tonemap y en sRGB** (el color que se ve).

**Muestras del entorno:** salen de `previous` (la imagen del TAA, HDR lineal); para calificarlas en el mismo
espacio que el color final se llevan con la exposición del fotograma, `c/(1 + c)` y sRGB (aproximación que la
especificación da por buena para matiz y saturación).

## Opciones

Aislamiento sí/no (encendido por defecto, es parte del aspecto de Vulpe), matiz y amplitud, en la página «Imagen».
El resto, constantes con los valores que el usuario ajustó jugando. Sin presets (cabrían como una opción de
elección si sobran). Van 46.

## Visto y no visto

- **Visto:** de día, el mundo en grises verdosos muy apagados con el bloque de redstone y las dos flores en rojo
  limpio (como `referencias/fg2_dia.png`); de noche, todo en gris con la aurora en gris y el bloque rojo.
- **El naranja de la tierra es de la regla, no un fallo** (medido el 2026-11-02): la cara lateral de la tierra sale
  con matiz ≈ 25° y saturación ≈ 0,5 sin aislamiento; con los valores por defecto (matiz 0°, rango 20°, suavidad
  12°, saturación mínima 0,17) su pertenencia vale ≈ 0,7, y como las caras son manchas grandes pasan la prueba de
  tamaño. En la referencia de Vulpe (`fg2_dia.png`) pasa lo mismo: la montaña de terracota rojiza de la derecha
  conserva su rojo. No se cambia: los valores son los del usuario. Si se quiere la tierra en gris, bajar la
  amplitud a ~10 (opción del menú) o la suavidad (constante).

## Color de la superficie (F-39, 2026-11-12)

Observación del dueño 5.1 (`observaciones-del-dueno-2026-11-12.md`): el aislamiento parecía centrado en el naranja.

- **Por qué:** se comparaba el matiz del color final, que es el del bloque **por la luz que le llega**. Medido con una
  vista de depuración por cuadrantes (pertenencia tras la exposición, tras Purkinje, tras el balance y la final, de
  noche con una antorcha): Purkinje, balance y gradación casi no mueven el matiz; lo que lo mueve es el **tinte de la
  luz**. La antorcha (1; 0,5; 0,25) lleva el rosa, el marrón y hasta el magenta hacia el rojo y quema el centro del
  naranja; la luz azul del cielo en sombra hace lo contrario. Al sol del mediodía sí salía bien.
- **Arreglo:** la etapa material guarda el matiz y la saturación del **albedo en sRGB, antes de la luz** (con estaciones
  y humedad), 8 bits cada uno, junto a la suavidad (8 bits) en el `smoothness` de `set_surface`, como un entero exacto
  menor que 2²⁴ (`sup_empaquetar_suavidad`, `nucleo/superficie/datos.wgsl`). La final (`adp_aislar`,
  `adaptadores/aislamiento.wgsl`) compara ese matiz en el píxel y en las 16 muestras del entorno (`surface_at`). Donde
  no hay terreno sólido (cielo, entidades, agua, cristal, partículas) sigue comparando el color de la imagen como
  antes. Los reflejos de pantalla desempaquetan la suavidad (`adaptadores/reflejo.wgsl`).
- **Espacio:** sRGB de la textura (la columna «sRGB» de la tabla del dueño): rojo 1, rosa 0,9, naranja y marrón ~0,5,
  magenta 0.
- **Límites:** el cristal tintado y los demás translúcidos no llaman a `set_surface` (F-30): se aíslan por el color de la
  imagen. Las entidades y los objetos en la mano, igual.
- **Comprobado** (`pruebas/escenas/aislamiento-hormigon.ctl`, cinco hormigones al sol y de noche con antorcha): el mismo
  resultado en las dos luces, y el rojo nunca por debajo del naranja.

## Bajo el agua (F-60, 2026-11-13)

Observación del dueño 2026-11-13 §3.1: bajo el agua salían manchas azules saturadas con forma de bloque. Reproducido
con `pruebas/escenas/aislamiento-colores.ctl` (tierra, arcilla, terracota y hormigón rojo en el fondo del océano):
`pruebas/capturas/aisl-agua-antes.png`. Desde F-39 la pertenencia al rango sale del color del **bloque**; la tierra y la
arcilla son rojizas y entraban en el rango del rojo, y entonces el realce se aplicaba al color de la **imagen**, que bajo
el agua es azul: azul realzado.

**Arreglo:** un freno con el matiz de la imagen, con margen amplio (`OPC_AISLAMIENTO_MARGEN_IMAGEN` = 45° sumados al
rango, sin saturación mínima, y solo cuando la imagen tiene algo de color): **solo puede sacar del rango, nunca meter**.
La luz cálida de una antorcha o el cielo sobre un bloque rojo no lo saca (el matiz se mueve menos de 45°); el azul del
agua, sí. Después: `pruebas/capturas/aisl-agua.png`, sin manchas.

### Lo que se conserva y lo que no (§3.2), medido

`tools/aislamiento/medir.py` sobre la fila de hormigón al sol (rango 20 alrededor del rojo), saturación HSV con el
aislamiento entre sin él:

| hormigón | matiz | sat. con / sin |
|---|---|---|
| rojo | 3° | **1,11** (realzado) |
| marrón | 28° | 1,09 (entra en el rango) |
| naranja | 40° | 0,95 (borde suave del rango) |
| amarillo | 54° | **0,22** |
| lima | 77° | 0,22 |
| azul | 242° | 0,35 |

A pleno sol ya hace lo que pide el dueño: el rango entero y realzado (×1,1 con el realce 30), y los demás conservan
~1/5 de su saturación (el 80 % de desaturación) con su matiz. No se cambia; queda para comprobar con el dueño de noche, donde
la saturación de partida es baja y 1/5 de ella apenas se ve. El freno de F-60 no cambia esta tabla.

## Marco y brillos del cristal transparente (F-102, 2026-11-20, N-09c)

**El fallo.** En bioma nevado, con una antorcha o un farol detrás de una ventana de `glass`, salían trazos naranjas en
el marco y en los brillos diagonales. El marco y los brillos (téxeles opacos de `glass.png`) los dibuja `[material]` en
la pasada translúcida, que no llama a `set_surface`; el cuerpo transparente no se dibuja (alfa < 0,01) y lo pinta el DDA
de `adp_cristales_post` en `06-taa`, de modo que en esos píxeles `surface_at` ve el terreno de detrás. El aislamiento
tomaba así el matiz del **bloque de detrás** en el cuerpo y el de la **imagen** en el marco: la luz de la antorcha (y el
desenfoque de la capa 7, que corre la llama sobre el marco) metía el marco en el rango del naranja y lo realzaba, mientras
el cristal de alrededor se desaturaba.

**Comprobado con datos** (vista de depuración temporal, `pruebas/capturas/n09c-dbg*`): el marco y los brillos salen de
`[material]` con `MaterialInput.translucent = true` y el DDA los cubre (desde `a317499`); el cuerpo solo lo pinta el DDA.

**Lo que se hace.** `adp_aislamiento_superficie` (`adaptadores/aislamiento.wgsl`) reconoce el marco y los brillos del
cristal transparente: reconstruye el punto con la profundidad, avanza 0,02 bloques en el sentido de la vista por cada eje
por separado (en diagonal, en el borde de la ventana caía en el muro y dejaba una línea de un píxel) y lee en la
caché `cristal_mapa` si ese bloque es cristal transparente (bits válido, cristal y claro, con la firma del bloque). Ahí
usa el matiz del bloque antes de la luz, como en el terreno sólido: el cristal transparente es incoloro (saturación 0),
así que no entra en el rango y se desatura como el resto de la ventana. El freno de F-60 se aplica igual.

- Mismo interruptor que el DDA (`OPC_CRISTAL_ACTIVO`, trazado de rayos, caché con cristal transparente y clima activo):
  con el efecto apagado o sin clima, la caché no se actualiza y el aislamiento hace lo de antes (lo de `e7ad1c4`).
- El cristal tintado y el ahumado siguen con el matiz de la imagen: su color es suyo y se dibujan enteros en `[material]`.
- Coste: una lectura de profundidad y hasta seis de la caché por píxel sin superficie (cielo excluido), y solo con cristales
  cerca y clima activo; en el bosque sin cristales el resumen de `cristal_sim` corta antes.
