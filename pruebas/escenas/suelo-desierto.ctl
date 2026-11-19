# Recorrido del suelo en bioma desértico (N-02): desierto en (-9872, -2200), punto exacto de
# tormenta-desierto.ctl (-9871.5, 90, -2199.5). Plataforma de arena, arena roja y arenisca a Y=86
# para juzgar ondulaciones finas alineadas con el viento (3-6 texeles en rejilla de 32),
# desplazamiento lento, sin charcos, más marcadas con tormenta (niveles 6-10) que con lluvia (1-5).
close
command gamemode spectator
command gamerule advance_time false
command time set 6000
command weather clear
command tp @s -9871.5 90 -2199.5 0 55
sleep 6
command fill -9876 85 -2204 -9864 85 -2192 minecraft:sandstone
command fill -9876 86 -2204 -9864 86 -2192 minecraft:sand
command fill -9871 86 -2199 -9864 86 -2192 minecraft:red_sand
command fill -9874 86 -2196 -9872 86 -2193 minecraft:sandstone
sleep 2
screenshot suelo-desierto-despejado
# Lluvia (niveles 1-5)
command weather rain
sleep 9
# Acercamiento 16, 8, 4, 2 y 1 bloques sobre la arena (Y=86)
command tp @s -9871.5 102 -2199.5 0 65
sleep 1
screenshot suelo-desierto-lluvia-d16
command tp @s -9871.5 94 -2199.5 0 60
sleep 1
screenshot suelo-desierto-lluvia-d08
command tp @s -9871.5 90 -2199.5 0 55
sleep 1
screenshot suelo-desierto-lluvia-d04
command tp @s -9871.5 88.5 -2199.5 0 55
sleep 1
screenshot suelo-desierto-lluvia-d02
command tp @s -9871.5 87.6 -2199.5 0 50
sleep 1
screenshot suelo-desierto-lluvia-d01
# Desplazamiento en el tiempo (2 s) desde el mismo punto
sleep 2
screenshot suelo-desierto-lluvia-d01-t2
# Giro en pasos de 20° y cruce de 1 en 1 bloque
command tp @s -9871.5 88.5 -2199.5 20 55
sleep 1
screenshot suelo-desierto-lluvia-giro-20
command tp @s -9871.5 88.5 -2199.5 40 55
sleep 1
screenshot suelo-desierto-lluvia-giro-40
command tp @s -9870.5 88.5 -2199.5 0 55
sleep 1
screenshot suelo-desierto-lluvia-paso-1
command tp @s -9869.5 88.5 -2199.5 0 55
sleep 1
screenshot suelo-desierto-lluvia-paso-2
# Tormenta eléctrica (niveles 6-10): más marcada y rápida, sin charcos
command weather thunder
sleep 9
command tp @s -9871.5 90 -2199.5 0 65
sleep 1
screenshot suelo-desierto-tormenta-d04
command tp @s -9871.5 88.5 -2199.5 0 65
sleep 1
screenshot suelo-desierto-tormenta-d02
command tp @s -9871.5 87.6 -2199.5 0 65
sleep 1
screenshot suelo-desierto-tormenta-d01
sleep 2
screenshot suelo-desierto-tormenta-d01-t2
command fill -9876 85 -2204 -9864 86 -2192 minecraft:air
command weather clear
sleep 5
