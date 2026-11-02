# Exposición, tonemap, gradación y bloom (subsistemas 10 y 11): día, atardecer al sol (bloom), noche, y la
# adaptación en una «cueva»: una caja de piedra construida en el aire (sin luz de cielo) con una piedra luminosa,
# y la salida al sol justo al salir y unos segundos después.
close
command tp @s 170.5 77 166.5
command weather clear
time 6000
look 0 15
sleep 6
screenshot imagen-dia
time 12300
look 90 -5
sleep 6
screenshot imagen-atardecer
time 18000
look 0 -15
sleep 8
screenshot imagen-noche
time 6000
fill 230 118 230 242 130 242 stone
fill 231 119 231 241 129 241 air
setblock 240 119 240 glowstone
command tp @s 233.5 119 233.5
look -45 10
sleep 10
screenshot imagen-cueva
command tp @s 170.5 77 166.5
look 0 15
sleep 0.3
screenshot imagen-salida-cueva
sleep 7
screenshot imagen-salida-adaptado
