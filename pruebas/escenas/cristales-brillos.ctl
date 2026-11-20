# N-09c: brillos y marco del cristal transparente con antorcha y farol detrás, de día y bajo alero (27 v2).
# Cristal transparente, tintado (azul claro) y panel, cada uno con una antorcha (izquierda) y un farol (derecha)
# un bloque por dentro. Cámara fuera, bajo un alero de 3 bloques, a 2,5 bloques del cristal. Nevado y templado.
# PREFIJO: las capturas salen como <prefijo>-<bioma>-<ventana>; cambiarlo con sed antes de cada pasada.
close
command gamemode spectator
command gamerule advance_time false
command time set 6000

# === nevado ===
command weather clear
command tp @s -499.5 95 -768.5 0 0
sleep 4
command fill -507 94 -771 -493 102 -761 minecraft:air
command fill -506 94 -770 -494 94 -762 minecraft:oak_planks
command fill -506 95 -766 -494 99 -766 minecraft:quartz_bricks
command fill -506 95 -762 -494 99 -762 minecraft:quartz_bricks
command fill -506 95 -766 -506 99 -762 minecraft:quartz_bricks
command fill -494 95 -766 -494 99 -762 minecraft:quartz_bricks
command fill -506 100 -769 -494 100 -762 minecraft:quartz_bricks
command fill -505 95 -766 -504 97 -766 minecraft:glass
command setblock -505 95 -765 minecraft:torch
command setblock -504 95 -765 minecraft:lantern
command fill -501 95 -766 -500 97 -766 minecraft:light_blue_stained_glass
command setblock -501 95 -765 minecraft:torch
command setblock -500 95 -765 minecraft:lantern
command fill -497 95 -766 -496 97 -766 minecraft:glass_pane
command setblock -497 95 -765 minecraft:torch
command setblock -496 95 -765 minecraft:lantern
command weather rain
sleep 75
command tp @s -504 94.4 -768.5 0 0
sleep 1.5
screenshot PREFIJO-nevado-claro
command tp @s -500 94.4 -768.5 0 0
sleep 1.5
screenshot PREFIJO-nevado-color
command tp @s -496 94.4 -768.5 0 0
sleep 1.5
screenshot PREFIJO-nevado-panel
command tp @s -504 94.4 -767.3 0 0
sleep 1.5
screenshot PREFIJO-nevado-claro-cerca
command weather clear
command fill -507 94 -771 -493 102 -761 minecraft:air

# === templado ===
command weather clear
command tp @s 170.5 107 151.5 0 0
sleep 4
command fill 163 106 149 177 114 159 minecraft:air
command fill 164 106 150 176 106 158 minecraft:oak_planks
command fill 164 107 154 176 111 154 minecraft:stone_bricks
command fill 164 107 158 176 111 158 minecraft:stone_bricks
command fill 164 107 154 164 111 158 minecraft:stone_bricks
command fill 176 107 154 176 111 158 minecraft:stone_bricks
command fill 164 112 151 176 112 158 minecraft:stone_bricks
command fill 165 107 154 166 109 154 minecraft:glass
command setblock 165 107 155 minecraft:torch
command setblock 166 107 155 minecraft:lantern
command fill 169 107 154 170 109 154 minecraft:light_blue_stained_glass
command setblock 169 107 155 minecraft:torch
command setblock 170 107 155 minecraft:lantern
command fill 173 107 154 174 109 154 minecraft:glass_pane
command setblock 173 107 155 minecraft:torch
command setblock 174 107 155 minecraft:lantern
command weather rain
sleep 25
command tp @s 166 106.4 151.5 0 0
sleep 1.5
screenshot PREFIJO-templado-claro
command tp @s 170 106.4 151.5 0 0
sleep 1.5
screenshot PREFIJO-templado-color
command tp @s 174 106.4 151.5 0 0
sleep 1.5
screenshot PREFIJO-templado-panel
command tp @s 166 106.4 152.7 0 0
sleep 1.5
screenshot PREFIJO-templado-claro-cerca
command weather clear
command fill 163 106 149 177 114 159 minecraft:air
command tp @s 170.5 90 166.5 0 10
