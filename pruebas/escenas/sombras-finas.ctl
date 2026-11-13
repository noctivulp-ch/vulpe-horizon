# Penumbras finas (B-23 lote 2, atajo del PCF): vallas, barrotes, cristal y un bloque, sobre hormigón blanco, con el
# sol a ~35° (hora 1510 de Horizon), cámara cerca mirando abajo. Hora congelada. Para comparar antes y después,
# perfil de tiempo fijo despejado (sin sombras de nubes que se mueven).
close
command gamemode spectator
command weather clear
command gamerule advance_time false
command time set 1510
command tp @s 330.5 104 296.5 0 50
sleep 6
command fill 325 99 297 336 99 308 minecraft:white_concrete
command fill 325 100 297 336 104 308 minecraft:air
command fill 327 100 301 333 100 301 minecraft:oak_fence
command fill 327 101 303 333 101 303 minecraft:iron_bars
command fill 327 100 305 329 102 305 minecraft:glass_pane
command setblock 332 102 305 minecraft:stone
command fill 330 103 299 331 103 299 minecraft:oak_slab
sleep 3
look 0 50
sleep 6
screenshot sombras-finas
look 0 80
sleep 3
screenshot sombras-finas-abajo
