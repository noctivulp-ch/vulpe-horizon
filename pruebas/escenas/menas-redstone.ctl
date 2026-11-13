# Menas (B-23 §6): muro de piedra con redstone, diamante, oro y hierro, en una caja cerrada a oscuras, a 3 bloques.
close
command gamemode spectator
command gamerule advance_time false
command time set 18000
command tp @s 266.5 121.5 236.5 90 10
sleep 6
command fill 258 118 230 272 126 242 minecraft:stone
command fill 259 119 231 271 125 241 minecraft:air
command setblock 262 121 235 minecraft:redstone_ore
command setblock 262 121 237 minecraft:diamond_ore
command setblock 262 122 236 minecraft:gold_ore
command setblock 262 120 236 minecraft:iron_ore
command setblock 262 121 236 minecraft:redstone_ore
sleep 2
look 90 10
sleep 6
screenshot menas-redstone
