# Color de la luz de bloque (03.1): de noche, en una caja de piedra sin luz de cielo, antorcha normal, de almas, lámpara de
# redstone encendida y cúmulo de amatista. Con «command» (el fill/setblock de horizon-ctl solo cambia el cliente) y de
# uno en uno con pausa.
close
command weather clear
time 18000
command fill 230 118 230 252 126 242 stone
sleep 1
command fill 231 119 231 251 125 241 air
sleep 1
command setblock 234 119 234 torch
sleep 1
command setblock 239 119 234 soul_torch
sleep 1
command setblock 244 118 234 redstone_block
sleep 1
command setblock 244 119 234 redstone_lamp
sleep 1
command setblock 249 119 234 amethyst_cluster
sleep 1
command tp @s 241.5 119 236.5
options-set fov 110
look 180 30
sleep 12
screenshot luces-colores
options-set fov 70
command fill 230 117 230 252 126 242 air
