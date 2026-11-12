# Translúcidos que no son agua (subsistema 22)

Cristal tintado, hielo, bloque de slime y bloque de miel. Especificación: `vulpe-horizon-spec/subsistemas/22-translucidos-y-detalles.md`.
Código: `fn translucido` en `etapas/material.wgsl`; constantes en `opciones/translucidos.wgsl`.

## Cómo se hace

Igual que el agua, la superficie translúcida **sale opaca** (alfa 1) y lleva dentro lo de detrás: Horizon da en la etapa
`material` el color y la profundidad del mundo antes de los translúcidos (`opaque_color`, `opaque_depth`), así que el
tinte multiplicativo se hace aquí y no depende de la mezcla de Horizon (que con alfa 1 no mezcla nada).

1. **Refracción**: la misma función que el agua (`adp_agua_refraccion`): desplazamiento por la normal en espacio
   tangente menos la de la cara, con caída por distancia, protección de bordes y separación cromática. Una cara lisa
   sin mapa de normales no desplaza nada. Si el punto desplazado está delante de la superficie, se descarta.
   Fuerza 50 (`OPC_TRANSL_REFRACCION`, misma escala que la opción del agua); dispersión, la del agua (50). Emborronado
   0: no se implementa (sería otra lectura por muestra).
2. **Tinte**: lo de detrás × el color de la superficie normalizado a longitud 1. Un cristal oscuro no ennegrece la
   escena; cambia el tono. Se desvanece linealmente a cero por debajo del 10 % de opacidad (`OPC_TRANSL_TINTE_MIN`).
3. **La superficie encima**, por su opacidad: `mix(fondo teñido, superficie iluminada, alfa)`. La luz de la superficie
   es la misma que la de las opacas (`03`): ya es la versión «larga», que incluye directa con sombra teñida, ambiente
   direccional, mano y relámpago.
4. **Reflejo con Fresnel** (Schlick, F0 = 2 % sin datos; con LabPBR, el F0 del paquete): el resultado se mezcla
   hacia el reflejo por la reflectancia, así que la opacidad sube con ella: de frente se ve a través, de refilón es
   espejo. Lo reflejado es lo mismo que en el agua (`adp_agua_reflejo`): cielo con nubes y, cerca del plano del agua,
   el espejo de Horizon.

## Diferencias con la especificación, y por qué

- **Desvanecer el tinte con la niebla de borde**: no se hace en el material. La niebla de borde se compone después en
  el post sobre el píxel entero (`03-composicion`), y tapa igual el cristal y lo de detrás, que es lo que se ve.
- **Bajo el agua** (absorción y cáusticas sobre la luz directa del translúcido): no se añade; usa la luz general.
- **Entidades translúcidas (slime), tinte de daño, etiquetas de nombre, grietas, contorno de selección, brillo de
  encantamiento y partículas**: no pasan por el pack. La API 0.1 de Horizon dice que la etapa `material` cubre solo
  el terreno y que aún no hay etapas para entidades, entidades de bloque ni partículas
  (`docs/horizon/.../api/shaders.md` §«Not there yet»). Quedan como las dibuja Horizon. Las partículas luminosas
  solo pueden aportar luz coloreada con `[[particle_lights]]`, no un multiplicador de brillo propio.

## Comprobado en Horizon (2026-11-12)

Escena `pruebas/escenas/translucidos.ctl`: muro de cristal rojo, marrón, azul y blanco, hielo, slime y miel, de frente
y de refilón a mediodía. De frente: lo de detrás teñido sin oscurecerse (el marrón da un tono anaranjado, que es lo
que hace normalizar). De refilón: la superficie se vuelve clara, reflejando el cielo.
