# TAA en movimiento (paridad 09): la pradera de (170, 77, 166) con el borde de la explanada de piedra, quieta y girando
# 3° por fotograma (aprox.) hacia la derecha; se captura en mitad del giro.
close
command weather clear
time 6000
command tp @s 170.5 78 150.5 0 15
sleep 6
screenshot taa-mov-quieta
look 3 15
look 6 15
look 9 15
look 12 15
look 15 15
screenshot taa-mov-girando
look 15 15
sleep 3
screenshot taa-mov-quieta-2
