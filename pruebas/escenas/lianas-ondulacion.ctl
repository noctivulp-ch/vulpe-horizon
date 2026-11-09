# Recorrido de verificación de balanceo de enredaderas y lianas (15.1).
# Pared vertical de piedra con lianas y enredaderas de 5 bloques de altura en exteriores a mediodía (time 6000).
# Capturas seguidas en el tiempo para comprobar el balanceo continuo sin dientes de sierra,
# y recorrido de acercamiento (16, 8, 4, 2 y 1 bloques) con giros de cámara de 15–30°.
close
command weather clear
time 6000

# Construcción de la pared de soporte y suelo (150 70 150 a 160 76 150)
command fill 148 69 140 162 69 160 stone
sleep 1
command fill 150 70 150 160 76 150 stone
sleep 1

# Colocación de columnas de enredaderas (vines) colgadas en la cara sur de la pared
command fill 152 70 151 158 75 151 vine[south=true]
sleep 1

# ==============================================================================
# 1. Capturas seguidas para evaluar el movimiento temporal a 4 bloques (Z = 155.0)
# ==============================================================================
command tp @s 155.0 72.0 155.0 180 0
sleep 2

# Capturas sucesivas cada 0,5 s durante un ciclo de viento
screenshot lianas-t00
sleep 0.5
screenshot lianas-t05
sleep 0.5
screenshot lianas-t10
sleep 0.5
screenshot lianas-t15
sleep 0.5
screenshot lianas-t20
sleep 0.5
screenshot lianas-t25
sleep 0.5
screenshot lianas-t30

# ==============================================================================
# 2. Recorrido acercándose y alejándose (16, 8, 4, 2 y 1 bloques) y giros 15–30°
# ==============================================================================
# A 16 bloques (Z = 167.0)
command tp @s 155.0 72.0 167.0 180 0
sleep 1
screenshot lianas-16b
look 160 0
sleep 0.4
screenshot lianas-16b-gn20
look 200 0
sleep 0.4
screenshot lianas-16b-g20
look 180 0

# A 8 bloques (Z = 159.0)
command tp @s 155.0 72.0 159.0 180 0
sleep 1
screenshot lianas-08b
look 165 0
sleep 0.4
screenshot lianas-08b-gn15
look 195 0
sleep 0.4
screenshot lianas-08b-g15
look 180 0

# A 4 bloques (Z = 155.0)
command tp @s 155.0 72.0 155.0 180 0
sleep 1
screenshot lianas-04b

# A 2 bloques (Z = 153.0)
command tp @s 155.0 72.0 153.0 180 0
sleep 1
screenshot lianas-02b
look 180 -25
sleep 0.4
screenshot lianas-02b-arriba
look 180 25
sleep 0.4
screenshot lianas-02b-abajo
look 180 0

# A 1 bloque (Z = 152.0)
command tp @s 155.0 72.0 152.0 180 0
sleep 1
screenshot lianas-01b
