# Penumbra de un borde recto según la altura del ocluyente (paridad 04): sobre el suelo de piedra lisa de la escena
# ao-rincon, cuatro losas de 2×3 a 1, 2, 4 y 8 bloques del suelo, a mediodía; vistas desde arriba y de cerca.
close
command weather clear
time 6000
command fill 164 77 160 176 90 181 air
command fill 164 76 160 176 76 182 smooth_stone
command fill 165 78 168 166 78 170 stone
sleep 0.5
command fill 168 79 168 169 79 170 stone
sleep 0.5
command fill 171 81 168 172 81 170 stone
sleep 0.5
command fill 174 85 168 175 85 170 stone
sleep 1
command tp @s 170.5 92 176.5 180 70
sleep 8
screenshot sombras-borde-arriba
command tp @s 166.5 79 173.5 180 60
sleep 4
screenshot sombras-borde-h1
command tp @s 172.5 79 173.5 180 60
sleep 4
screenshot sombras-borde-h4
command tp @s 175.5 79 173.5 180 60
sleep 4
screenshot sombras-borde-h8
