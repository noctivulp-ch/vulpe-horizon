# Halo de las menas (observación del dueño 2.3): caja de piedra cerrada a medianoche con menas de diamante, redstone,
# lapislázuli, cobre y oro en la pared, mirándolas a 5 bloques sin antorcha.
close
command weather clear
command gamerule advance_time false
time 18000
command tp @s 236.5 120.4 236.5 90 5
sleep 6
command fill 230 118 230 252 126 242 stone
command fill 231 119 231 251 125 241 air
command setblock 231 121 234 minecraft:diamond_ore
command setblock 231 121 236 minecraft:redstone_ore
command setblock 231 121 238 minecraft:lapis_ore
command setblock 231 123 235 minecraft:copper_ore
command setblock 231 123 237 minecraft:gold_ore
command tp @s 236.5 120.4 236.5 90 5
sleep 10
screenshot menas-halo
