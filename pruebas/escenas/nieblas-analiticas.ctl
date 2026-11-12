# Nieblas analíticas (23): campo abierto mirando al horizonte y 15° arriba (borde), ceguera, oscuridad, nieve en polvo y
# lava; mediodía con la hora congelada.
close
command weather clear
command gamerule advance_time false
time 6000
command tp @s 170.5 110 150.5 0 3
sleep 8
screenshot analiticas-borde
look 0 -15
sleep 2
screenshot analiticas-borde-arriba
look 0 10
command effect give @s minecraft:blindness 30
sleep 3
screenshot analiticas-ceguera
command effect clear @s
command effect give @s minecraft:darkness 30
sleep 3
screenshot analiticas-oscuridad
command effect clear @s
command fill 169 109 149 171 112 151 minecraft:powder_snow
sleep 2
screenshot analiticas-nieve-polvo
command fill 169 109 149 171 112 151 minecraft:lava
sleep 2
screenshot analiticas-lava
command fill 169 109 149 171 112 151 minecraft:air
