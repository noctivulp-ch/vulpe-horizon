# Aislamiento (B-23 §3): fila de hormigón rojo, naranja, amarillo, lima, azul y marrón (2×2 cada uno) al sol a mediodía,
# y debajo del agua del océano bloques de tierra, arcilla, terracota, arena y hormigón rojo. Hora congelada.
close
command gamemode spectator
command weather clear
command gamerule advance_time false
command time set 6000
command tp @s 315.5 104 296.5 0 45
sleep 6
command fill 309 99 297 322 99 304 minecraft:white_concrete
command fill 310 100 300 311 100 301 minecraft:red_concrete
command fill 312 100 300 313 100 301 minecraft:orange_concrete
command fill 314 100 300 315 100 301 minecraft:yellow_concrete
command fill 316 100 300 317 100 301 minecraft:lime_concrete
command fill 318 100 300 319 100 301 minecraft:blue_concrete
command fill 320 100 300 321 100 301 minecraft:brown_concrete
sleep 2
look 0 45
sleep 5
screenshot aisl-fila
command tp @s 478.5 56 195.5 0 35
sleep 6
command fill 475 47 199 482 49 203 minecraft:water
command fill 475 46 199 482 46 203 minecraft:stone
command fill 475 47 200 476 47 201 minecraft:dirt
command fill 477 47 200 478 47 201 minecraft:clay
command fill 479 47 200 480 47 201 minecraft:terracotta
command fill 481 47 200 482 47 201 minecraft:red_concrete
sleep 2
look 0 35
sleep 6
screenshot aisl-agua
command tp @s 315.5 104 296.5 0 45
