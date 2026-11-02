# Menas brillantes (subsistema 12): una pared de menas en una caja de piedra sin luz (la de la cueva del 11), sin
# antorchas, de cerca y de lejos; y de día al aire libre.
close
command weather clear
time 6000
fill 230 118 230 242 130 242 stone
fill 231 119 231 241 129 241 air
setblock 240 119 240 air
setblock 241 120 232 coal_ore
setblock 241 120 233 iron_ore
setblock 241 120 234 gold_ore
setblock 241 120 235 diamond_ore
setblock 241 120 236 redstone_ore
setblock 241 120 237 lapis_ore
setblock 241 120 238 emerald_ore
setblock 241 120 239 copper_ore
setblock 241 121 232 deepslate_coal_ore
setblock 241 121 233 deepslate_iron_ore
setblock 241 121 234 deepslate_gold_ore
setblock 241 121 235 deepslate_diamond_ore
setblock 241 121 236 deepslate_redstone_ore
setblock 241 121 237 nether_quartz_ore
setblock 241 121 238 nether_gold_ore
setblock 241 121 239 gilded_blackstone
command tp @s 237.5 119 235.5
look -90 -8
sleep 10
screenshot menas-cerca
command tp @s 232.5 119 235.5
look -90 -4
sleep 3
screenshot menas-lejos
fill 230 118 230 242 130 242 air
