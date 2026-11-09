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
