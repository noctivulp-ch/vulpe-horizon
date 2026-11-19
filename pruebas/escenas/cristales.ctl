# Recorrido de «el tiempo en los cristales» (27, N-08): muro de cristal (transparente, tintado y ahumado) y paneles
# (transparente y tintado) con alero corto y porche hondo. Recorridos con acercamiento (16/8/4/2/1 bloques),
# giros de 20° y pasos laterales de 1 en 1 bloque en lluvia, secado, frío (escarcha), nieve, aliento y desierto.
close
command gamemode spectator
command gamerule advance_time false
command time set 6000
command weather clear

# === 1. LLUVIA, ALERO CORTO VS PORCHE HONDO Y SECADO ===
command tp @s 170.5 110 149.0 0 0
sleep 4
command fill 162 106 149 180 115 158 minecraft:air
command fill 162 106 154 178 106 154 minecraft:stone_bricks
command fill 162 106 154 162 114 154 minecraft:stone_bricks
command fill 178 106 154 178 114 154 minecraft:stone_bricks
command fill 163 107 154 165 113 154 minecraft:glass
command fill 166 107 154 168 113 154 minecraft:light_blue_stained_glass
command fill 169 107 154 171 113 154 minecraft:tinted_glass
command fill 172 107 154 174 113 154 minecraft:glass_pane
command fill 175 107 154 177 113 154 minecraft:white_stained_glass_pane
# Alero corto (1 bloque) sobre la izquierda; porche hondo (5 bloques) sobre la derecha
command fill 162 114 153 166 114 154 minecraft:stone_bricks
command fill 175 114 149 179 114 156 minecraft:stone_bricks
sleep 2
screenshot cristales-recorrido-despejado

command weather rain
sleep 8
# Acercamiento 16, 8, 4, 2 y 1 bloques al muro (Z=154)
command tp @s 170.5 110 138.0 0 0
sleep 1
screenshot cristales-recorrido-lluvia-d16
command tp @s 170.5 110 146.0 0 0
sleep 1
screenshot cristales-recorrido-lluvia-d08
command tp @s 170.5 110 150.0 0 0
sleep 1
screenshot cristales-recorrido-lluvia-d04
command tp @s 167.5 110 152.0 0 0
sleep 1
screenshot cristales-recorrido-lluvia-d02
command tp @s 167.5 110 153.0 0 0
sleep 1
screenshot cristales-recorrido-lluvia-d01
# Movimiento temporal (2 s): gotas bajando a tirones
sleep 2
screenshot cristales-recorrido-lluvia-d01-t2
# Giro en pasos de 20° y recorrido lateral de 1 en 1 bloque (alero -> expuesto -> paneles -> porche)
command tp @s 167.5 110 151.5 20 0
sleep 1
screenshot cristales-recorrido-lluvia-g20
command tp @s 167.5 110 151.5 -20 0
sleep 1
screenshot cristales-recorrido-lluvia-gn20
command tp @s 164.5 110 151.5 0 0
sleep 1
screenshot cristales-recorrido-lluvia-paso-alero
command tp @s 170.5 110 151.5 0 0
sleep 1
screenshot cristales-recorrido-lluvia-paso-ahumado
command tp @s 173.5 110 151.5 0 0
sleep 1
screenshot cristales-recorrido-lluvia-paso-panel
command tp @s 176.5 110 151.5 0 0
sleep 1
screenshot cristales-recorrido-lluvia-paso-porche
# Cruce de la superficie del cristal de 1 en 1 bloque (exterior -> interior)
command tp @s 167.5 110 153.2 0 0
sleep 1
screenshot cristales-recorrido-cruce-ext
command tp @s 167.5 110 155.2 180 0
sleep 1
screenshot cristales-recorrido-cruce-int

# Secado gradual (mod): 12 s intermedio y 35 s seco
command tp @s 167.5 110 151.8 0 0
command weather clear
sleep 12
screenshot cristales-recorrido-secado-12s
sleep 25
screenshot cristales-recorrido-secado-37s
command fill 162 106 149 180 115 158 minecraft:air

# === 2. FRÍO (ESCARCHA), NIEVE (COPOS Y MONTÓN) Y ALIENTO ===
command time set 18000
command tp @s -499.5 75 -766.0 0 0
sleep 6
command fill -506 72 -765 -492 78 -760 minecraft:air
command fill -506 72 -761 -492 72 -761 minecraft:stone_bricks
command fill -506 72 -761 -506 78 -761 minecraft:stone_bricks
command fill -492 72 -761 -492 78 -761 minecraft:stone_bricks
command fill -506 78 -761 -492 78 -761 minecraft:stone_bricks
command fill -505 73 -761 -503 77 -761 minecraft:glass
command fill -502 73 -761 -499 77 -761 minecraft:light_blue_stained_glass
command fill -498 73 -761 -496 77 -761 minecraft:tinted_glass
command fill -495 73 -761 -493 77 -761 minecraft:white_stained_glass_pane
sleep 6
screenshot cristales-recorrido-escarcha-d05
command tp @s -500.5 75 -763.0 0 0
sleep 1
screenshot cristales-recorrido-escarcha-d02
command tp @s -500.5 75 -763.0 20 0
sleep 1
screenshot cristales-recorrido-escarcha-g20

# Nevando: copos pegados y montón inferior
command time set 6000
command weather rain
sleep 12
command tp @s -499.5 75 -765.0 0 0
sleep 1
screenshot cristales-recorrido-nevando-d04
command tp @s -500.5 75 -763.0 0 0
sleep 1
screenshot cristales-recorrido-nevando-d02

# Aliento (modo creativo, pegado al cristal con escarcha -> memoria al alejarse)
command fill -502 72 -765 -499 72 -762 minecraft:stone_bricks
command gamemode creative
command tp @s -500.5 73 -761.8 0 0
sleep 6
screenshot cristales-recorrido-aliento-cerca
command tp @s -500.5 73 -763.8 0 0
sleep 2
screenshot cristales-recorrido-aliento-memoria
command gamemode spectator
command fill -506 72 -765 -492 78 -760 minecraft:air
command weather clear

# === 3. DESIERTO TRAS TORMENTA (ARENA) ===
command time set 6000
command tp @s -9871.5 91 -2205.0 0 0
sleep 6
command fill -9878 88 -2200 -9864 94 -2200 minecraft:air
command fill -9878 88 -2200 -9864 88 -2200 minecraft:sandstone
command fill -9878 88 -2200 -9878 94 -2200 minecraft:sandstone
command fill -9864 88 -2200 -9864 94 -2200 minecraft:sandstone
command fill -9878 94 -2200 -9864 94 -2200 minecraft:sandstone
command fill -9877 89 -2200 -9875 93 -2200 minecraft:glass
command fill -9874 89 -2200 -9871 93 -2200 minecraft:light_blue_stained_glass
command fill -9870 89 -2200 -9868 93 -2200 minecraft:tinted_glass
command fill -9867 89 -2200 -9865 93 -2200 minecraft:glass_pane
command weather thunder
sleep 12
command weather clear
sleep 6
screenshot cristales-recorrido-desierto-d05
command tp @s -9872.5 91 -2202.0 0 0
sleep 1
screenshot cristales-recorrido-desierto-d02
command tp @s -9872.5 91 -2202.0 20 0
sleep 1
screenshot cristales-recorrido-desierto-g20
command fill -9878 88 -2200 -9864 94 -2200 minecraft:air
command tp @s 170.5 90 166.5 0 10
