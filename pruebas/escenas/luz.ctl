# Luz de superficie (subsistema 03): mediodía, contraluz en las hojas, atardecer, noche, lluvia (mojado).
close
command tp @s 170.5 77 166.5
command weather clear
time 6000
look 0 15
sleep 3
screenshot luz-mediodia
time 11800
look 90 0
sleep 2
screenshot luz-contraluz
time 18000
look 0 15
sleep 2
screenshot luz-noche
time 6000
command weather rain
sleep 40
command tp @s 172.5 72 160.5
look 180 30
screenshot luz-lluvia
command weather clear
