# Fundido de las tormentas (observaciones del dueño 1.1 y 1.2), el día de tormenta de arena de la escena
# tormenta-desierto (no cambia el día): A) dentro del desierto empieza a llover: 1, 3 y 6 s. B) con lluvia, desde
# fuera (océano) se entra al desierto: 0,5, 2 y 5 s. Mediodía congelado.
close
command gamerule advance_time false
command weather clear
command tp @s -9871.5 90 -2199.5 0 5
sleep 14
command weather rain
sleep 1
screenshot fundido-a-1
sleep 2
screenshot fundido-a-3
sleep 3
screenshot fundido-a-6
command tp @s -9871.5 90 -1500.5 0 5
sleep 8
command tp @s -9871.5 90 -2199.5 0 5
sleep 0.5
screenshot fundido-b-0
sleep 1.5
screenshot fundido-b-2
sleep 3
screenshot fundido-b-5
command weather clear
