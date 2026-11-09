# Recorrido de verificación de niebla de cueva (05.3).
# Cueva cerrada sin luz de cielo ni fuentes de luz, a medianoche (time 18000), mano vacía.
# Recorrido alejándose y acercándose a la pared de fondo (16, 8, 4, 2 y 1 bloques),
# con giros de 15–30° e inclinación vertical (abajo, frente, arriba).
close
command weather clear
time 18000

# Construcción de la galería de piedra cerrada (230 118 230 a 265 125 240, interior vaciado)
command fill 230 118 230 265 125 240 stone
sleep 1
command fill 231 119 231 264 124 239 air
sleep 1

# Mano vacía para no emitir luz dinámica
command clear @s
sleep 1

# ==============================================================================
# 1. Distancia 16 bloques (X = 247.0 frente a pared en X = 231.0)
# ==============================================================================
command tp @s 247.0 119 235.0 90 0
sleep 2
screenshot cueva-niebla-16b
look 75 0
sleep 0.5
screenshot cueva-niebla-16b-g75
look 105 0
sleep 0.5
screenshot cueva-niebla-16b-g105
# Vista vertical: abajo (-30°), frente (0°), arriba (+30°) para probar factor dir.y
look 90 -30
sleep 0.5
screenshot cueva-niebla-16b-abajo
look 90 30
sleep 0.5
screenshot cueva-niebla-16b-arriba
look 90 0

# ==============================================================================
# 2. Distancia 8 bloques (X = 239.0)
# ==============================================================================
command tp @s 239.0 119 235.0 90 0
sleep 1
screenshot cueva-niebla-08b
look 75 0
sleep 0.5
screenshot cueva-niebla-08b-g75
look 105 0
sleep 0.5
screenshot cueva-niebla-08b-g105
look 90 0

# ==============================================================================
# 3. Distancia 4 bloques (X = 235.0)
# ==============================================================================
command tp @s 235.0 119 235.0 90 0
sleep 1
screenshot cueva-niebla-04b
look 75 0
sleep 0.5
screenshot cueva-niebla-04b-g75
look 105 0
sleep 0.5
screenshot cueva-niebla-04b-g105
look 90 0

# ==============================================================================
# 4. Acercamiento final a 2 y 1 bloque
# ==============================================================================
command tp @s 233.0 119 235.0 90 0
sleep 1
screenshot cueva-niebla-02b
command tp @s 232.0 119 235.0 90 0
sleep 1
screenshot cueva-niebla-01b
