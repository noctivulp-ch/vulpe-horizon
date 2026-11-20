# Recorrido de «el tiempo en los cristales» (27 v2, N-09): casa de cristal bajo techo y de día (/time set 6000)
# con cristal transparente, paneles, tintado y ahumado; alero corto vs porche hondo; recorridos 16/8/4/2/1,
# giros de 15-30° y pasos de 1 en 1 bloque en lluvia/secado, frío (escarcha, repisa, copos, condensación, borde,
# vaho y desenfoque con luces) y desierto/arena.
close
command gamemode spectator
command gamerule advance_time false
command time set 6000
command weather clear

# === 1. LLUVIA, ALERO CORTO VS PORCHE HONDO Y SECADO (bajo techo, de día) ===
command tp @s 170.0 110 158.0 180 0
sleep 4
command fill 161 106 147 180 116 161 minecraft:air
command fill 162 106 154 178 106 160 minecraft:oak_planks
command fill 162 106 154 162 114 160 minecraft:stone_bricks
command fill 178 106 154 178 114 160 minecraft:stone_bricks
command fill 162 106 160 178 114 160 minecraft:stone_bricks
command fill 162 114 154 178 114 160 minecraft:stone_bricks
command fill 163 107 154 166 113 154 minecraft:glass
command fill 167 107 154 169 113 154 minecraft:glass_pane
command fill 170 107 154 172 113 154 minecraft:light_blue_stained_glass
command fill 173 107 154 177 113 154 minecraft:tinted_glass
# Alero corto (1 bloque) sobre tinted derecha; porche hondo (5 bloques) sobre glass izquierda
command fill 175 114 153 178 114 153 minecraft:stone_bricks
command fill 162 114 149 164 114 153 minecraft:stone_bricks
command setblock 165 107 158 minecraft:lantern
command setblock 175 107 158 minecraft:lantern
sleep 2
command tp @s 170.0 110 156.8 180 0
sleep 1
screenshot cristales-v2-despejado

command weather rain
sleep 22
# Secuencia de 5 capturas seguidas para ver las gotas bajar, fusionarse y dejar rastro (1,8 bloques del cristal)
screenshot cristales-v2-lluvia-f1
sleep 0.5
screenshot cristales-v2-lluvia-f2
sleep 0.5
screenshot cristales-v2-lluvia-f3
sleep 0.5
screenshot cristales-v2-lluvia-f4
sleep 0.5
screenshot cristales-v2-lluvia-f5

# Acercamiento 16, 8, 4, 2 y 1 bloques por fuera y giros 20°
command tp @s 170.0 110 138.0 0 0
sleep 1
screenshot cristales-v2-lluvia-d16
command tp @s 170.0 110 146.0 0 0
sleep 1
screenshot cristales-v2-lluvia-d08
command tp @s 170.0 110 150.0 0 0
sleep 1
screenshot cristales-v2-lluvia-d04
command tp @s 168.5 110 152.0 0 0
sleep 1
screenshot cristales-v2-lluvia-d02
command tp @s 168.5 110 153.0 0 0
sleep 1
screenshot cristales-v2-lluvia-d01
command tp @s 168.5 110 152.0 20 0
sleep 1
screenshot cristales-v2-lluvia-g20
command tp @s 168.5 110 152.0 -20 0
sleep 1
screenshot cristales-v2-lluvia-gn20
# Cruce de 1 en 1 bloque (fuera -> dentro)
command tp @s 168.5 110 153.2 0 0
sleep 1
screenshot cristales-v2-cruce-ext
command tp @s 168.5 110 155.8 180 0
sleep 1
screenshot cristales-v2-cruce-int

# Secado gradual (6-26 s)
command weather clear
sleep 10
screenshot cristales-v2-secado-10s
sleep 18
screenshot cristales-v2-secado-28s
command fill 161 106 147 180 116 161 minecraft:air

# === 2. FRÍO: ESCARCHA EN MARCO ENTERO, REPISA, COPOS, CONDENSACIÓN, BORDE, VAHO Y DESENFOQUE CON LUCES ===
command time set 6000
command weather rain
command tp @s -500.0 97.3 -763.2 180 5
sleep 4
command fill -506 94 -773 -494 101 -760 minecraft:air
command fill -505 94 -766 -495 94 -761 minecraft:oak_planks
command fill -505 94 -766 -505 100 -761 minecraft:quartz_bricks
command fill -495 94 -766 -495 100 -761 minecraft:quartz_bricks
command fill -505 94 -761 -495 100 -761 minecraft:quartz_bricks
command fill -505 100 -766 -495 100 -761 minecraft:quartz_bricks
command fill -505 95 -766 -495 99 -766 minecraft:quartz_bricks
command fill -503 96 -766 -501 98 -766 minecraft:glass
command fill -499 96 -766 -497 98 -766 minecraft:light_blue_stained_glass
command setblock -503 95 -763 minecraft:lantern
command setblock -497 95 -763 minecraft:lantern
# Fondo de prueba con luces exteriores para comprobar el desenfoque conservando las luces
command fill -504 95 -771 -496 98 -771 minecraft:deepslate_bricks
command setblock -502 97 -771 minecraft:glowstone
command setblock -498 97 -771 minecraft:glowstone
sleep 35
screenshot cristales-v2-frio-nieve
command weather thunder
sleep 45
command weather clear
sleep 4
screenshot cristales-v2-frio-cond-blur
# Giro 15° en movimiento
command tp @s -500.0 97.3 -763.2 165 5
sleep 0.5
screenshot cristales-v2-frio-g15
command tp @s -500.0 97.3 -763.2 195 5
sleep 0.5
screenshot cristales-v2-frio-gn15

# Vaho del aliento (modo creativo a 1,1 bloques -> retención al retroceder)
command gamemode creative
command tp @s -502.0 95.0 -763.9 180 0
sleep 12
screenshot cristales-v2-vaho-cerca
command tp @s -502.0 95.0 -763.1 180 0
sleep 5
screenshot cristales-v2-vaho-retencion
command gamemode spectator
command fill -506 94 -773 -494 101 -760 minecraft:air

# === 3. DESIERTO TRAS TORMENTA (ARENA) ===
command time set 6000
command weather clear
command tp @s -9872.0 98.0 -2202.2 180 6
sleep 4
command fill -9878 95 -2209 -9866 102 -2199 minecraft:air
command fill -9877 95 -2205 -9867 95 -2200 minecraft:smooth_sandstone
command fill -9877 95 -2205 -9877 101 -2200 minecraft:smooth_sandstone
command fill -9867 95 -2205 -9867 101 -2200 minecraft:smooth_sandstone
command fill -9877 95 -2200 -9867 101 -2200 minecraft:smooth_sandstone
command fill -9877 101 -2205 -9867 101 -2200 minecraft:smooth_sandstone
command fill -9877 96 -2205 -9867 100 -2205 minecraft:smooth_sandstone
command fill -9875 97 -2205 -9873 99 -2205 minecraft:glass
command fill -9871 97 -2205 -9869 99 -2205 minecraft:light_blue_stained_glass
command weather thunder
sleep 42
command weather clear
sleep 4
screenshot cristales-v2-desierto-arena
command fill -9878 95 -2209 -9866 102 -2199 minecraft:air
command tp @s 170.5 90 166.5 0 10
