# Agua (subsistema 07): orilla de día (transparencia por profundidad, cáusticas, reflejo de la orilla), mirando
# abajo, atardecer contra el sol (reguero), noche, y bajo el agua (horizontal, arriba, abajo).
close
command weather clear
command tp @s 150.5 68 225.5
sleep 3
time 6000
look 0 25
sleep 4
screenshot agua-orilla
look 0 80
sleep 1
screenshot agua-abajo
time 11800
look 90 4
sleep 3
screenshot agua-atardecer
time 18000
look 0 25
sleep 4
screenshot agua-noche
time 6000
command tp @s 125.5 58 245.5
sleep 4
look 0 0
sleep 2
screenshot agua-dentro
look 0 -60
sleep 1
screenshot agua-dentro-arriba
look 0 40
sleep 1
screenshot agua-dentro-abajo
command tp @s 170.5 77 166.5
