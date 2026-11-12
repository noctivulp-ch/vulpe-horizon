# Comprobación rápida de los cambios F-1..F-10 en las escenas del banco (hora, mirada), sin medir píxeles.
close
command weather clear
command gamerule advance_time false
command tp @s 170.5 77 166.5
time 6000
sleep 2
look 0 -55
sleep 1
screenshot f-cielo-dia
look 0 -70
sleep 0.5
screenshot f-nubes-dia
look 0 0
sleep 0.5
screenshot f-dia-horizonte
time 12000
sleep 2
look 90 -3
sleep 1
screenshot f-atardecer-oeste
time 300
sleep 2
look -90 -5
sleep 1
screenshot f-niebla-amanecer
time 18000
sleep 2
look 0 -90
sleep 1
screenshot f-noche-fractal
look 0 0
sleep 0.5
screenshot f-noche-horizonte
time 6000
command weather rain
sleep 8
look 0 0
sleep 1
screenshot f-lluvia-dia
command weather clear
command gamerule advance_time false
