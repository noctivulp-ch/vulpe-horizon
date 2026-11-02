# Lluvia y nieve (subsistema 16): lluvia de día, al atardecer mirando al sol, de noche, y nieve en el bioma nevado.
close
command tp @s 170.5 77 166.5
sleep 3
command weather rain
time 6000
look 0 0
sleep 12
screenshot clima-lluvia-dia
time 11800
look 90 0
sleep 4
screenshot clima-lluvia-contraluz
time 18000
look 0 0
sleep 6
screenshot clima-lluvia-noche
time 6000
command tp @s -502 100 -762
wait-ready
sleep 8
look 0 5
screenshot clima-nieve
command weather clear
command tp @s 170.5 77 166.5
