# Recorrido de prueba para luz de cielo direccional, cara inferior de techos y halos de siluetas (B-16.3)
# Hora 6000 (mediodía): aproximación a voladizo/techo (16, 8, 4, 2 y 1 bloques), giros de 15-30° y silueta de tronco contra el cielo.
close
command weather clear
time 6000
sleep 1

# 1. Aproximación al voladizo y cara inferior del techo (16, 8, 4, 2 y 1 bloques)
# Mirando hacia arriba con inclinación de 45° hacia la cara inferior
command tp @s 170.5 70 150.5
look 0 -45
sleep 1
screenshot techo-d16

command tp @s 170.5 70 158.5
look 0 -45
sleep 0.5
screenshot techo-d8

command tp @s 170.5 70 162.5
look 0 -45
sleep 0.5
screenshot techo-d4

command tp @s 170.5 70 164.5
look 0 -45
sleep 0.5
screenshot techo-d2

command tp @s 170.5 70 165.5
look 0 -45
sleep 0.5
screenshot techo-d1

# 2. Giro de cámara en pasos de 15° y 30° mirando hacia el techo y las paredes laterales
look 0 -30
sleep 0.5
screenshot techo-g0-p30

look 15 -30
sleep 0.5
screenshot techo-g15-p30

look 30 -30
sleep 0.5
screenshot techo-g30-p30

look 45 -30
sleep 0.5
screenshot techo-g45-p30

look 60 -30
sleep 0.5
screenshot techo-g60-p30

# 3. Inspección directa de la cara inferior (cenit recto: pitch -90°)
look 0 -90
sleep 0.5
screenshot techo-cenit-inferior

# 4. Silueta de tronco o arista contra el cielo (sin halos negros ni penumbra fantasma)
command tp @s 170.5 75 166.5
look 90 -20
sleep 0.5
screenshot silueta-cielo-base

look 75 -20
sleep 0.5
screenshot silueta-cielo-g15

look 60 -20
sleep 0.5
screenshot silueta-cielo-g30

# Cruce de superficie de 1 en 1 bloque alejándose de la arista
command tp @s 170.5 75 167.5
look 90 -20
sleep 0.5
screenshot silueta-cruce-1

command tp @s 170.5 75 168.5
look 90 -20
sleep 0.5
screenshot silueta-cruce-2
