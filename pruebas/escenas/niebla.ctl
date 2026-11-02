# Niebla y nubes (subsistema 05): cúmulos de mañana, cenit, jirones al amanecer, bruma al atardecer, niebla
# de noche, lluvia, sobre las nubes y tormenta de nieve.
close
command tp @s 170.5 77 166.5
command weather clear
time 3000
look 0 -30
sleep 3
screenshot niebla-nubes
look 0 -85
sleep 1
screenshot niebla-cenit
time 300
look -90 -10
sleep 2
screenshot niebla-amanecer
time 12300
look 90 -5
sleep 2
screenshot niebla-atardecer
time 18000
look 0 0
sleep 2
screenshot niebla-noche
time 3000
look 30 10
command tp @s 170.5 900 166.5
sleep 1
screenshot niebla-sobre-nubes
command tp @s 170.5 77 166.5
time 6000
command weather rain
sleep 10
look 0 -10
screenshot niebla-lluvia
command tp @s -502 100 -762
wait-ready
sleep 6
look 0 10
screenshot niebla-nieve
command weather clear
command tp @s 170.5 77 166.5
wait-ready
