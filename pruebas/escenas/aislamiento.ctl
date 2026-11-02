# Aislamiento de color (subsistema 13): pradera de día con un bloque de redstone grande (3×3), una flor suelta y
# amapolas; de noche con la aurora.
close
command weather clear
command tp @s 170.5 77 166.5
sleep 3
fill 168 77 172 170 79 172 redstone_block
setblock 172 77 170 poppy
setblock 173 77 171 red_tulip
time 6000
look 0 25
sleep 4
screenshot aislamiento-dia
options-set fov 110
time 18000
look 0 -15
sleep 8
screenshot aislamiento-noche
options-set fov 70
fill 168 77 172 170 79 172 air
setblock 172 77 170 air
setblock 173 77 171 air
