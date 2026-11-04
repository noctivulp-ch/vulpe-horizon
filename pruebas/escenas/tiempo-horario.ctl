# Horario de la niebla y tiempo diario como datos (paridad 05): la pradera de (170, 78, 150) mirando al horizonte al
# amanecer (23500), a mediodía (6000), al atardecer (12000) y de noche (18000).
close
command weather clear
command tp @s 170.5 78 150.5 0 -5
time 23500
sleep 8
screenshot tiempo-amanecer
time 6000
sleep 8
screenshot tiempo-mediodia
time 12000
sleep 8
screenshot tiempo-atardecer
time 18000
sleep 8
screenshot tiempo-noche
