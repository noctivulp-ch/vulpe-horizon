# Suelo de luz de noche y en cuevas (B-23 §1): parches de 3×3 de piedra, arena y pasto vistos a ~5 bloques.
# A cielo abierto (plataforma a Y 100 en (296..306, 296..306)) con luna llena (día 0), cuarto (día 2) y nueva (día 4),
# a medianoche; y en la caja de piedra cerrada de cueva-oscura (sin luz de cielo). Hora congelada, despejado.
close
command gamemode spectator
command weather clear
command gamerule advance_time false
command clear @s
command tp @s 301.5 103.5 296.5 0 40
sleep 6
command fill 296 99 294 306 99 306 minecraft:stone
command fill 297 100 299 299 100 301 minecraft:stone
command fill 300 100 299 302 100 301 minecraft:sand
command fill 303 100 299 305 100 301 minecraft:grass_block
command fill 230 118 230 252 126 242 minecraft:stone
command fill 231 119 231 251 125 241 minecraft:air
command fill 235 118 236 237 118 238 minecraft:stone
command fill 238 118 236 240 118 238 minecraft:sand
command fill 241 118 236 243 118 238 minecraft:grass_block
sleep 3
command time set 18000
command tp @s 301.5 103.5 296.5 0 40
look 0 40
sleep 8
screenshot noche-suelo-llena
command time set 66000
sleep 8
screenshot noche-suelo-cuarto
command time set 114000
sleep 8
screenshot noche-suelo-nueva
command tp @s 239.5 121.5 232.5 0 40
look 0 40
sleep 10
screenshot noche-suelo-cueva
command time set 18000
command tp @s 301.5 103.5 296.5 0 40
