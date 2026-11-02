# Luz de superficie (subsistema 03): mediodía, contraluz en las hojas, atardecer, noche, lluvia (mojado).
close
tp 170.5 77 166.5
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
sleep 35
look 0 40
screenshot luz-lluvia
command weather clear
