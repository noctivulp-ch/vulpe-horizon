# Recorrido de prueba para niebla y perfiles de lluvia (B-16.2)
# Mediodía (hora 6000) con lluvia hacia bloques cercanos y muro lejano.
close
command weather rain
sleep 4
time 6000
command tp @s 170.5 77 166.5

# Mirada al frente hacia el muro lejano (debe verse velado por la niebla densa gris azulada)
look 0 0
sleep 1
screenshot lluvia-recorrido-frente

# Giro de cámara en pasos de 15-30° horizontalmente
look 15 0
sleep 0.5
screenshot lluvia-recorrido-g15
look 30 0
sleep 0.5
screenshot lluvia-recorrido-g30
look 60 0
sleep 0.5
screenshot lluvia-recorrido-g60

# Giro vertical hacia el cenit (64° y 90°: cielo debe conservar azul sin oscurecer a carbón)
look 0 -45
sleep 0.5
screenshot lluvia-recorrido-cenit-45
look 0 -75
sleep 0.5
screenshot lluvia-recorrido-cenit-75
look 0 -90
sleep 0.5
screenshot lluvia-recorrido-cenit-90

# Acercamiento al muro/bloques en pasos de distancia: 16, 8, 4, 2 y 1 bloques
command tp @s 170.5 77 182.5
look 0 0
sleep 0.5
screenshot lluvia-recorrido-d16
command tp @s 170.5 77 190.5
look 0 0
sleep 0.5
screenshot lluvia-recorrido-d08
command tp @s 170.5 77 194.5
look 0 0
sleep 0.5
screenshot lluvia-recorrido-d04
command tp @s 170.5 77 196.5
look 0 0
sleep 0.5
screenshot lluvia-recorrido-d02
command tp @s 170.5 77 197.5
look 0 0
sleep 0.5
screenshot lluvia-recorrido-d01

command weather clear
