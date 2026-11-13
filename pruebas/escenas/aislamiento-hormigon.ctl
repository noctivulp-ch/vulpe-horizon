# Aislamiento (13, observación del dueño 5.1): hormigón magenta, marrón, naranja, rojo y rosa en fila, al sol, mediodía
# congelado, mirando abajo.
close
command weather clear
command gamerule advance_time false
time 6000
command fill 166 109 154 176 115 160 minecraft:air
command fill 166 108 154 167 108 157 minecraft:magenta_concrete
command fill 168 108 154 169 108 157 minecraft:brown_concrete
command fill 170 108 154 171 108 157 minecraft:orange_concrete
command fill 172 108 154 173 108 157 minecraft:red_concrete
command fill 174 108 154 175 108 157 minecraft:pink_concrete
command fill 166 112 156 176 112 160 minecraft:air
command tp @s 171 112 152 0 62
sleep 8
screenshot aislamiento-hormigon
# De noche con una antorcha junto a la fila (luz baja: exposición alta y Purkinje).
time 18000
command setblock 171 109 153 minecraft:torch
sleep 6
screenshot aislamiento-hormigon-noche
command setblock 171 109 153 minecraft:air
time 6000
