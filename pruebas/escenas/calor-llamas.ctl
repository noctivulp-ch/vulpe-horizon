# Calor al arder y en lava (N-07 / F-73, subsistema 19):
# Recorrido de comprobación con plataforma de ladrillos para ver con claridad la ondulación:
# sin fuego -> en fuego (recto y girado 20°) -> 3 s, 10 s y 12 s tras salir del fuego ->
# reencendido y salida a agua (0,5 s y 4 s) -> en lava.
close
command weather clear
command gamerule advance_time false
time 6000

# Plataforma de prueba en el aire con pared de ladrillos al frente (z=176).
command fill 160 99 158 172 108 182 minecraft:air
command fill 160 99 158 172 99 182 minecraft:stone_bricks
command fill 160 100 176 172 105 176 minecraft:stone_bricks

# 1. Sin fuego (referencia, igual que antes).
command tp @s 166.5 100 166.5 0 15
sleep 1.5
screenshot calor-sin-fuego

# 2. De pie en fuego (pies en minecraft:fire, cabeza en aire).
command setblock 166 99 166 minecraft:netherrack
command setblock 166 100 166 minecraft:fire
command tp @s 166.5 100 166.5 0 15
sleep 1.5
screenshot calor-en-fuego
command tp @s 166.5 100 166.5 20 15
sleep 0.4
screenshot calor-en-fuego-g20

# 3. Sale del fuego: a 3 s sigue ardiendo (~8 s); a 10 s está terminando la bajada de 3 s; a 12 s ya sin calor.
command tp @s 166.5 100 168.5 0 15
sleep 3
screenshot calor-tras-fuego-3s
sleep 7
screenshot calor-tras-fuego-10s
sleep 2
screenshot calor-tras-fuego-12s

# 4. Saliendo a agua: se apaga al instante al tocar agua (pies en agua, cabeza en aire) y la distorsión cae en ~3 s.
command fill 164 100 169 168 100 173 minecraft:stone_bricks
command fill 165 100 170 167 100 172 minecraft:water
command tp @s 166.5 100 166.5 0 15
sleep 1.5
command tp @s 166.5 100 171.5 0 15
sleep 0.5
screenshot calor-agua-05s
sleep 3.5
screenshot calor-agua-4s

# 5. En lava (pies y cabeza en lava).
command fill 164 100 159 168 101 163 minecraft:stone_bricks
command fill 165 100 160 167 101 162 minecraft:lava
command tp @s 166.5 100 161.5 0 15
sleep 1.5
screenshot calor-en-lava

# Limpieza de la plataforma de prueba.
command fill 160 99 158 172 108 182 minecraft:air
command tp @s 166.5 95 152.5 0 10
