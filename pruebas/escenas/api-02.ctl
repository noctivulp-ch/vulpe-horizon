# Comprobación de la migración a la API 0.2 (encargo N-04):
# carta de color (mediodía, atardecer, noche), tormenta con partículas del mod (bit 7),
# agua, noche con el fractal, cueva cerrada, Nether y End.
close
command weather clear
command gamemode spectator
command gamerule advance_time false

# 1. Carta de color (subsistema 28): cubo de hormigón blanco 3x3x3
command tp @s 474.5 104 193.5 45 20
sleep 6
command fill 470 100 198 472 102 200 minecraft:white_concrete
sleep 4
time 2965
look 45 20
sleep 3
screenshot api02-carta-06000
time 13155
look 45 20
sleep 3
screenshot api02-carta-12500
time 18000
look 45 20
sleep 3
screenshot api02-carta-18000

# 2. Tormenta (y comprobación del mod con partículas en el bit 7)
command tp @s 150.5 75 198.5 -150 10
time 6000
command weather thunder
sleep 8
screenshot api02-tormenta
command weather clear

# 3. Agua (orilla de día)
command tp @s 150.5 68 225.5
time 6000
look 0 25
sleep 5
screenshot api02-agua-orilla

# 4. Noche con el fractal
command tp @s 170.5 77 166.5
options-set fov 110
time 18000
look 0 -90
sleep 4
screenshot api02-fractal-cenit
options-set fov 70

# 5. Cueva cerrada sin luz
command fill 230 118 230 252 126 242 stone
sleep 1
command fill 231 119 231 251 125 241 air
sleep 1
command clear @s
command tp @s 235.0 119 236.5 90 0
sleep 5
screenshot api02-cueva-05s
command fill 230 118 230 252 126 242 air

# 6. Nether y End
command execute in minecraft:the_nether run tp @s 0.5 80 0.5 0 30
sleep 12
screenshot api02-nether
command execute in minecraft:the_end run tp @s 60.5 75 0.5 90 20
sleep 12
screenshot api02-end
command execute in minecraft:overworld run tp @s 150.5 80 230.5 -150 25
