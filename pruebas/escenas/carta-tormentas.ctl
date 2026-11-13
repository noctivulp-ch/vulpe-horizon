# Carta de color de las tormentas (28 §5): cubo blanco 3×3×3 a Y 100 en el desierto (−9872, −2200) y en la llanura
# nevada (−490, −762), con tormenta, a la puesta (elevación 0°) y a medianoche, día 2 del mundo (perfil de tormenta).
close
command gamemode spectator
command gamerule advance_time false
command tp @s -9867.5 104 -2204.5 45 20
sleep 8
command fill -9872 100 -2200 -9870 102 -2198 minecraft:white_concrete
command weather thunder
time 60785
sleep 12
screenshot tormenta-arena-12000
look 45 -35
sleep 2
screenshot tormenta-arena-12000-cielo
look 45 20
time 66000
sleep 8
screenshot tormenta-arena-18000
command tp @s -485.5 104 -766.5 45 20
sleep 8
command fill -490 100 -762 -488 102 -760 minecraft:white_concrete
time 60785
sleep 12
screenshot tormenta-nieve-12000
look 45 -35
sleep 2
screenshot tormenta-nieve-12000-cielo
look 45 20
time 66000
sleep 8
screenshot tormenta-nieve-18000
command weather clear
