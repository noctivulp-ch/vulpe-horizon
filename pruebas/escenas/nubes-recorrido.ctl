# Recorrido de nubes (05.4): de día y despejado (hora 3000, cúmulos bajos activos), giro desde el suelo en 6 rumbos
# (con pasos intermedios de 30° para el TAA) y subida de 20 en 20 bloques desde Y = 80 hasta Y = 380 cruzando la
# capa baja (Y = 250..350).
close
command tp @s 170.5 77 166.5
command weather clear
time 3000
wait-ready
sleep 3

# 1. Desde el suelo (Y = 77) en 6 rumbos (cada 60°, con paso intermedio de 30°).
look 0 -25
sleep 2
screenshot nubes-rumbo-000
look 30 -25
sleep 0.5
look 60 -25
sleep 1.5
screenshot nubes-rumbo-060
look 90 -25
sleep 0.5
look 120 -25
sleep 1.5
screenshot nubes-rumbo-120
look 150 -25
sleep 0.5
look 180 -25
sleep 1.5
screenshot nubes-rumbo-180
look -150 -25
sleep 0.5
look -120 -25
sleep 1.5
screenshot nubes-rumbo-240
look -90 -25
sleep 0.5
look -60 -25
sleep 1.5
screenshot nubes-rumbo-300

# 2. Subida de 20 en 20 bloques hasta cruzar la capa baja (Y = 250..350).
look 0 -20
command tp @s 170.5 80 166.5
sleep 1
screenshot nubes-subida-080
command tp @s 170.5 100 166.5
sleep 1
screenshot nubes-subida-100
command tp @s 170.5 120 166.5
sleep 1
screenshot nubes-subida-120
command tp @s 170.5 140 166.5
sleep 1
screenshot nubes-subida-140
command tp @s 170.5 160 166.5
sleep 1
screenshot nubes-subida-160
command tp @s 170.5 180 166.5
sleep 1
screenshot nubes-subida-180
command tp @s 170.5 200 166.5
sleep 1
screenshot nubes-subida-200
look 0 -12
command tp @s 170.5 220 166.5
sleep 1
screenshot nubes-subida-220
command tp @s 170.5 240 166.5
sleep 1
screenshot nubes-subida-240
look 0 -5
command tp @s 170.5 260 166.5
sleep 1
screenshot nubes-subida-260
command tp @s 170.5 280 166.5
sleep 1
screenshot nubes-subida-280
look 0 0
command tp @s 170.5 300 166.5
sleep 1
screenshot nubes-subida-300
command tp @s 170.5 320 166.5
sleep 1
screenshot nubes-subida-320
look 0 8
command tp @s 170.5 340 166.5
sleep 1
screenshot nubes-subida-340
look 0 15
command tp @s 170.5 360 166.5
sleep 1
screenshot nubes-subida-360
command tp @s 170.5 380 166.5
sleep 1
screenshot nubes-subida-380

command tp @s 170.5 77 166.5
wait-ready
