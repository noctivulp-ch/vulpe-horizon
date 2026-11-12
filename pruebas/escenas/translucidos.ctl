# Translúcidos (22): muro de cristal tintado (rojo claro y oscuro, azul, blanco), hielo, slime y miel delante del
# paisaje; de frente y de refilón. Mediodía con la hora congelada.
close
command weather clear
command gamerule advance_time false
time 6000
command tp @s 170.5 110 150.5 0 0
command fill 166 109 154 174 113 154 minecraft:air
command fill 166 109 154 167 113 154 minecraft:red_stained_glass
command fill 168 109 154 169 113 154 minecraft:brown_stained_glass
command fill 170 109 154 171 113 154 minecraft:blue_stained_glass
command fill 172 109 154 172 113 154 minecraft:white_stained_glass
command fill 173 109 154 173 113 154 minecraft:ice
command fill 174 109 154 174 110 154 minecraft:slime_block
command fill 174 111 154 174 113 154 minecraft:honey_block
sleep 8
screenshot transl-frente
command tp @s 178.5 111 151.5 60 0
sleep 3
screenshot transl-refilon
command fill 166 109 154 174 113 154 minecraft:air
