# Datos del mod nativo (formato v1)

Especificación: `../vulpe-horizon-spec/flexibilidad/mod-nativo.md` (formato v1) y `../vulpe-horizon-mod/docs/guia.md`.
Documentación de Horizon: `docs/horizon/horizon/docs/api/shaders.md` y `docs/horizon/horizon/docs/api/shaders-reference.md` (gancho `native_shader_params`, API 84).

## Por qué leer el mod nativo frente a valores fijos

Horizon entrega a los shaders un conjunto básico de variables uniformes en `Frame` (`frame.day_time`, `frame.sun_direction`, etc.), pero omite datos acumulados del mundo y del cliente necesarios para efectos dinámicos avanzados:
- **Número de día acumulado:** `frame.day_time` solo cicla de 0 a 24000 ticks. Sin el día acumulado, el fractal nocturno y la secuencia de tiempo diario no pueden variar de una noche a la siguiente.
- **Fase de la luna (0..7):** Horizon proporciona `frame.moon_direction`, pero no la fase lunar de Minecraft.
- **Estación continua (0..4):** el avance estacional a lo largo del año requiere conocer el día acumulado y el calendario.
- **Último rayo y estado del jugador:** relámpagos con posición en mundo relativa a cámara y parámetros de juego (salud, fuego, daño).

El mod nativo inyecta estos datos cada fotograma en `frame.mods` (`array<vec4<f32>, 8>`).

## §Adaptador

En `adaptadores/mod.wgsl`, la función `adp_mod() -> AdpModDatos` decodifica la cabecera y componentes según el formato v1:
- Si `frame.mods[0].x` no coincide con la firma `1001.0`, se descarta todo el bloque y se devuelven los valores por defecto del pack sin mod (luna llena, día 0, estación desactivada/fija, sin rayo, estado sano).
- Cuando la firma está presente, se leen las banderas de validez (`mods[0].z`):
  - **Bit 0 (tiempo):** `mods[1].x` (número de día acumulado) y `mods[1].y` (fase lunar 0..7).
  - **Bit 2 (estación):** `mods[1].z` (estación continua 0..4).
  - **Bit 1 (rayo):** `mods[2]` (posición relativa a la cámara y edad en segundos).
  - **Bit 3 (jugador):** `mods[3]` (salud, tiempo desde daño, fuego y mojado).

## Qué lee cada efecto del mod nativo

| Efecto / Subsistema | Qué lee de `adp_mod()` | Bandera requerida | Comportamiento con mod | Comportamiento sin mod (por defecto) |
|---|---|---|---|---|
| **Luz nocturna** (`01`, `03`) | `fase_luna` (0..7) | Bit 0 (`tiene_tiempo`) | `adp_luna_factor_fase()` aplica `abs(4.0 - fase) / 4.0`. Modula luz directa de la luna, dispersión atmosférica y ambiente nocturno (cielo/suelo). | Factor 1,0 constante (luna llena). Si `estilo_noches` es «Sin fases», se fuerza factor 1,0. |
| **Cielo fractal** (`02`) | `dia` (acumulado) | Bit 0 (`tiene_tiempo`) | `adp_fractal_sorteo` suma `m.dia + frame.day_time`, sorteando nuevas constelaciones cada noche con `fractal_cambia_cada_noche`. | `dia = frame.day_time`, constelaciones idénticas cada noche. |
| **Tiempo diario** (`05`) | `dia` (acumulado) | Bit 0 (`tiene_tiempo`) | `adp_momento` entrega el día del mundo para alternar los perfiles de nubes procedimentales del calendario. | Día 0, perfil fijo inicial. |
| **Aurora boreal** (`06`) | `dia` (acumulado) | Bit 0 (`tiene_tiempo`) | Varía la fase temporal de la cortina boreal noche a noche. | Día 0 + hora diaria. |
| **Estaciones del follaje** (`03.2`) | `estacion` (continua 0..4) | Bit 2 (`tiene_estacion`) | `sup_estacion_mod()` tiñe hierba y hojas: 0 Primavera, 1 Verano, 2 Otoño, 3 Invierno, con fundido suave en el último 25 % y desaturación invernal. | Fija en estación inicial (por defecto Verano = sin cambio de albedo). |
| **Rayo** (`17.1`) | `rayo` (posición, edad) | Bit 1 (`tiene_rayo`) | Disponible en struct para destellos y volumetría de relámpago. | Sin rayo (`edad = -1.0`, `activo = false`). |
| **Estado del jugador** (`11`) | `jugador` (salud, daño, fuego, humedad) | Bit 3 (`tiene_jugador`) | Disponible en struct para viñeta de daño, desaturación por salud baja y gotas en lente. | Jugador sano al 100 %, sin fuego ni humedad. |

## Vista de depuración «Mod nativo» (`OPC_VISTA_MOD_NATIVO`)

En `opciones/depuracion.wgsl` se declara `OPC_VISTA_MOD_NATIVO = 8u` sobre la opción interna existente (sin consumir ninguna de las 64 opciones del menú). Al activarse (`OPC_DEPURACION_VISTA_DEFECTO = 8u`), `07-final.wgsl` dibuja una interfaz a pantalla completa dividida en tres bandas horizontales:
1. **Franja superior (Firma y estado):** verde esmeralda si la firma `1001.0` está presente; rojo si no hay mod nativo. Muestra indicadores de las 5 banderas de cabecera (tiempo, rayo, estación, jugador, canal fijo).
2. **Franja central (Fase lunar 0..7):** 8 casillas discretas con divisores marcados. La casilla de la fase actual se ilumina en blanco/dorado lunar brillante, con brillo proporcional a la iluminación de la fase.
3. **Franja inferior (Estación continua 0..4):** 4 cuadrantes coloreados (Primavera verde tierno, Verano dorado, Otoño ámbar, Invierno cian/hielo) con barra de progreso continua y aguja marcadora blanca en `estacion / 4.0`.
4. **Píxel de muestreo (esquina superior izquierda):** codifica exactamente `R = activo`, `G = fase / 7.0`, `B = estacion / 4.0` para verificación automatizada o lectura con cuentagotas.
