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
