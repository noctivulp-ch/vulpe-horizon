# Carta de color, solo el crepúsculo (0°, −6°, −12° por la mañana y por la tarde) con espera larga: entre esas horas
# la luz cambia 6× y la exposición automática necesita ~7 s para converger. Ver carta-color.ctl.
close
command weather clear
command gamemode spectator
command gamerule advance_time false
command tp @s 474.5 104 193.5 45 20
sleep 6
command fill 470 100 198 472 102 200 minecraft:white_concrete
sleep 6
time 22480
look 45 20
sleep 7
screenshot carta-23000
look 45 -35
sleep 3
screenshot cielo-23000
time 22845
look 45 20
sleep 7
screenshot carta-23500
look 45 -35
sleep 3
screenshot cielo-23500
time 23215
look 45 20
sleep 7
screenshot carta-00000
look 45 -35
sleep 3
screenshot cielo-00000
time 12785
look 45 20
sleep 7
screenshot carta-12000
look 45 -35
sleep 3
screenshot cielo-12000
time 13155
look 45 20
sleep 7
screenshot carta-12500
look 45 -35
sleep 3
screenshot cielo-12500
time 13520
look 45 20
sleep 7
screenshot carta-13000
look 45 -35
sleep 3
screenshot cielo-13000
