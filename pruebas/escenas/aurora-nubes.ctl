# Nubes delante de la aurora (observación del dueño 3.2): medianoche despejada con cúmulos, mirando al cenit y 45°
# arriba. Hora congelada. Con el mod, el día decide si hay aurora: se prueban tres días.
close
command weather clear
command gamerule advance_time false
time 18000
command tp @s 170.5 100 150.5 0 -85
sleep 10
screenshot aurora-nubes-cenit
look 0 -45
sleep 3
screenshot aurora-nubes-45
command time add 24000
sleep 6
screenshot aurora-nubes-45-d1
command time add 24000
sleep 6
screenshot aurora-nubes-45-d2
