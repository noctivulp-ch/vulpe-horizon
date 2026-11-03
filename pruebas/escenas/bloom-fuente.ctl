# Bloom de una fuente de luz en la oscuridad (observación del dueño: «se ve la dispersión como palitos»): una piedra
# luminosa en una caja de piedra sin luz, vista a 16, 8, 4, 2 y 1 bloques.
close
command weather clear
time 18000
command fill 230 118 230 262 126 242 stone
sleep 1
command fill 231 119 231 261 125 241 air
sleep 1
command setblock 232 120 236 glowstone
sleep 1
command tp @s 248.5 119 236.5
look 90 -5
sleep 8
screenshot bloom-16
command tp @s 240.5 119 236.5
sleep 4
screenshot bloom-08
command tp @s 236.5 119 236.5
sleep 4
screenshot bloom-04
command tp @s 234.5 119 236.5
sleep 4
screenshot bloom-02
command tp @s 233.5 119 236.5
sleep 4
screenshot bloom-01
command fill 230 118 230 262 126 242 air
