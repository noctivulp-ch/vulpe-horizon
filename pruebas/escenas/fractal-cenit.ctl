# Fractal (B-23 §2.3): noche despejada de luna llena, mirando al cenit a Y normal y a Y 5000. Hora congelada.
close
command gamemode spectator
command weather clear
command gamerule advance_time false
time 18000
command tp @s 170.5 90 166.5
sleep 6
look 0 -90
sleep 3
screenshot fractal-cenit-y90
look 0 -30
sleep 2
screenshot fractal-30-y90
command tp @s 170.5 5000 166.5
sleep 4
look 0 -90
sleep 3
screenshot fractal-cenit-y5000
look 0 -30
sleep 2
screenshot fractal-30-y5000
command tp @s 170.5 90 166.5
