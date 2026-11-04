# Luz de bloque (paridad 03): una antorcha en el suelo de una caja de piedra cerrada (cueva sin luz de cielo), vista a 16,
# 8, 4, 2 y 1 bloques, y luego fuera de día y de noche para comprobar que la imagen sigue en el objetivo.
close
command weather clear
time 6000
command fill 230 118 230 262 126 242 stone
sleep 1
command fill 231 119 231 261 125 241 air
sleep 1
command setblock 232 119 236 torch
sleep 1
command tp @s 248.5 119 236.5 90 10
sleep 10
screenshot antorcha-16
command tp @s 240.5 119 236.5 90 10
sleep 5
screenshot antorcha-08
command tp @s 236.5 119 236.5 90 15
sleep 5
screenshot antorcha-04
command tp @s 234.5 119 236.5 90 25
sleep 5
screenshot antorcha-02
command tp @s 233.5 119 236.5 90 40
sleep 5
screenshot antorcha-01
command setblock 232 119 236 air
command tp @s 240.5 119 236.5 90 10
sleep 10
screenshot antorcha-sin
command setblock 232 119 236 torch
command tp @s 170.5 78 150.5 0 5
sleep 10
screenshot antorcha-fuera-dia
time 18000
sleep 10
screenshot antorcha-fuera-noche
