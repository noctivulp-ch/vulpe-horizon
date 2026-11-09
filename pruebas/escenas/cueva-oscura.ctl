# Cueva a oscuras sin fuentes de luz (regresión B-10 / paridad 03.4).
# Caja de piedra cerrada (sin luz de cielo), a medianoche (time 18000), con el jugador sin nada en la mano.
# Capturas de adaptación a los 5, 15 y 30 segundos, recorrido acercándose a la pared (16, 8, 4, 2 y 1 bloques),
# giros de cámara de 15–30° y avance/retroceso de 1 en 1 bloque.
close
command weather clear
time 18000

# Construcción de la caja de piedra cerrada (230 118 230 a 252 126 242, interior vaciado)
command fill 230 118 230 252 126 242 stone
sleep 1
command fill 231 119 231 251 125 241 air
sleep 1

# Asegurar mano vacía
command clear @s
sleep 1

# ==============================================================================
# Adaptación temporal en la posición inicial (235.0 119 236.5, a 4 bloques de la pared oeste)
# ==============================================================================
command tp @s 235.0 119 236.5 90 0

# 1. Captura a los 5 segundos
sleep 5
screenshot cueva-oscura-05s

# 2. Captura a los 15 segundos (10 s más)
sleep 10
screenshot cueva-oscura-15s

# 3. Captura a los 30 segundos (15 s más, adaptación completa)
sleep 15
screenshot cueva-oscura-30s

# Giros de 15–30° a 4 bloques
look 75 0
sleep 1
screenshot cueva-oscura-04-g75
look 105 0
sleep 1
screenshot cueva-oscura-04-g105
look 90 0
sleep 0.5

# ==============================================================================
# Acercamiento a la pared de 1 en 1 bloque
# ==============================================================================
# A 3 bloques (X = 234.0)
command tp @s 234.0 119 236.5 90 0
sleep 1

# A 2 bloques (X = 233.0): captura pedida explícitamente
command tp @s 233.0 119 236.5 90 0
sleep 2
screenshot cueva-oscura-02
look 75 0
sleep 1
screenshot cueva-oscura-02-g75
look 105 0
sleep 1
screenshot cueva-oscura-02-g105
look 90 0
sleep 0.5

# A 1 bloque (X = 232.0)
command tp @s 232.0 119 236.5 90 0
sleep 2
screenshot cueva-oscura-01
look 75 0
sleep 1
screenshot cueva-oscura-01-g75
look 105 0
sleep 1
screenshot cueva-oscura-01-g105
look 90 0
sleep 0.5

# ==============================================================================
# Alejamiento de 1 en 1 bloque hasta 8 y 16 bloques
# ==============================================================================
command tp @s 233.0 119 236.5 90 0
sleep 0.5
command tp @s 234.0 119 236.5 90 0
sleep 0.5
command tp @s 235.0 119 236.5 90 0
sleep 0.5
command tp @s 236.0 119 236.5 90 0
sleep 0.5
command tp @s 237.0 119 236.5 90 0
sleep 0.5
command tp @s 238.0 119 236.5 90 0
sleep 0.5

# A 8 bloques (X = 239.0)
command tp @s 239.0 119 236.5 90 0
sleep 2
screenshot cueva-oscura-08

# A 16 bloques (X = 247.0)
command tp @s 247.0 119 236.5 90 0
sleep 2
screenshot cueva-oscura-16

# ==============================================================================
# Limpieza
# ==============================================================================
command fill 230 118 230 252 126 242 air
