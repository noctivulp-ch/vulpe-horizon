# Efectos de cámara de juego (19): salida del agua (gotas) a 0,3, 1,5 y 3,5 s; entrada (onda) a 0,3 s; lava (calor).
# Mar de (125, 245), mediodía con la hora congelada.
close
command weather clear
command gamerule advance_time false
time 6000
command tp @s 125.5 58 245.5 0 10
sleep 6
command tp @s 125.5 66 245.5 0 10
sleep 0.3
screenshot camara-salida-03
sleep 1.2
screenshot camara-salida-15
sleep 2
screenshot camara-salida-35
sleep 3
command tp @s 125.5 58 245.5 0 10
sleep 0.3
screenshot camara-entrada-03
command tp @s 125.5 75 245.5 0 10
command fill 124 74 244 126 76 246 minecraft:lava
sleep 1.5
screenshot camara-lava
command fill 124 74 244 126 76 246 minecraft:air
