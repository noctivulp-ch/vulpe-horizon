# AO junto a un rincón suelo–pared (paridad 08): pared de piedra de 7×5 en z = 182, vista desde 16, 8, 4 y 2 bloques con
# la arista en el centro de la pantalla, sobre un suelo de piedra lisa llano (el terreno de allí no lo es; deja la
# explanada hecha), por la mañana (la cara norte solo recibe luz indirecta).
close
command weather clear
time 2000
command fill 164 77 160 176 90 181 air
command fill 164 76 160 176 76 182 smooth_stone
command fill 164 77 182 176 81 182 stone
sleep 1
command tp @s 170.5 77 166.5 0 6
sleep 8
screenshot ao-rincon-16
command tp @s 170.5 77 174.5 0 11
sleep 4
screenshot ao-rincon-08
command tp @s 170.5 77 178.5 0 22
sleep 4
screenshot ao-rincon-04
command tp @s 170.5 77 180.5 0 39
sleep 4
screenshot ao-rincon-02
