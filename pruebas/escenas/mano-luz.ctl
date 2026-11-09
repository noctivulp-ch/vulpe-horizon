# Luz de color en la mano (novedad Horizon nightly 2026-11-08 / MaterialInput.colored_light).
# Cueva cerrada, de noche, con una antorcha en la mano acercándose a una pared a 8, 4, 2 y 1 bloques.
# Recorrido con acercamiento, giros de cámara de 15–30°, alejamiento de 1 en 1 bloque y comparación sin antorcha.
close
command weather clear
time 18000

# Construcción de la caja de piedra cerrada (sin luz de cielo)
command fill 230 118 230 252 126 242 stone
sleep 1
command fill 231 119 231 251 125 241 air
sleep 1

# Entregar antorcha al jugador y seleccionarla en la mano
command give @s minecraft:torch 1
sleep 1
select minecraft:torch
sleep 1

# ==============================================================================
# Recorrido acercándose a la pared (oeste, X = 231 interior)
# ==============================================================================

# 1. Distancia 8 bloques (X = 239.0)
command tp @s 239.0 119 236.5 90 0
sleep 4
screenshot mano-luz-08
look 75 0
sleep 1
screenshot mano-luz-08-g75
look 105 0
sleep 1
screenshot mano-luz-08-g105
look 90 0
sleep 0.5

# 2. Distancia 4 bloques (X = 235.0)
command tp @s 235.0 119 236.5 90 0
sleep 4
screenshot mano-luz-04
look 75 0
sleep 1
screenshot mano-luz-04-g75
look 105 0
sleep 1
screenshot mano-luz-04-g105
look 90 0
sleep 0.5

# 3. Distancia 2 bloques (X = 233.0)
command tp @s 233.0 119 236.5 90 0
sleep 4
screenshot mano-luz-02
look 75 0
sleep 1
screenshot mano-luz-02-g75
look 105 0
sleep 1
screenshot mano-luz-02-g105
look 90 0
sleep 0.5

# 4. Distancia 1 bloque (X = 232.0)
command tp @s 232.0 119 236.5 90 0
sleep 4
screenshot mano-luz-01
look 75 0
sleep 1
screenshot mano-luz-01-g75
look 105 0
sleep 1
screenshot mano-luz-01-g105
look 90 0
sleep 0.5

# ==============================================================================
# Recorrido alejándose de 1 en 1 bloque
# ==============================================================================
command tp @s 233.0 119 236.5 90 0
sleep 1
command tp @s 234.0 119 236.5 90 0
sleep 1
command tp @s 235.0 119 236.5 90 0
sleep 1
command tp @s 236.0 119 236.5 90 0
sleep 1
command tp @s 237.0 119 236.5 90 0
sleep 1
command tp @s 238.0 119 236.5 90 0
sleep 1
command tp @s 239.0 119 236.5 90 0
sleep 2
screenshot mano-luz-08-vuelta

# Alejar a 16 bloques
command tp @s 247.0 119 236.5 90 0
sleep 4
screenshot mano-luz-16

# ==============================================================================
# Comparación sin antorcha en la mano (slot vacío)
# ==============================================================================
select 2
sleep 4
screenshot mano-luz-16-sin
command tp @s 235.0 119 236.5 90 0
sleep 4
screenshot mano-luz-04-sin

# ==============================================================================
# Limpieza
# ==============================================================================
select 1
command clear @s
command fill 230 117 230 252 126 242 air
