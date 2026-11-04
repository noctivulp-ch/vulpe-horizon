# Mapeo de tonos (paridad 11): la pradera de (170, 77, 166) mirando al horizonte con cielo, de día, al atardecer contra
# el sol y de noche.
close
command weather clear
command tp @s 170.5 78 150.5 0 -10
time 6000
sleep 10
screenshot tonemap-dia
command tp @s 170.5 78 150.5 -90 -5
time 11900
sleep 8
screenshot tonemap-atardecer
command tp @s 170.5 78 150.5 0 -10
time 18000
sleep 10
screenshot tonemap-noche
