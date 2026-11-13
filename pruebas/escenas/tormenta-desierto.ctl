# Tormentas (observaciones del dueño 1.1 y 1.2): en el desierto de (-9872, -2200), la lluvia se pone estando dentro, tres
# días seguidos (perfil del día: nada, polvo o tormenta de arena); capturas a los 3 y a los 12 s. Mediodía congelado.
close
command gamerule advance_time false
command weather clear
time 6000
command tp @s -9871.5 90 -2199.5 0 5
sleep 14
screenshot desierto-d0-sin
command weather rain
sleep 3
screenshot desierto-d0-03
sleep 9
screenshot desierto-d0-12
command weather clear
command time add 24000
sleep 8
command weather rain
sleep 12
screenshot desierto-d1-12
command weather clear
command time add 24000
sleep 8
command weather rain
sleep 12
screenshot desierto-d2-12
command weather clear
