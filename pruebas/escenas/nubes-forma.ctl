# Nubes con la forma de F-36: mediodía despejado congelado, desde el suelo hacia el horizonte y 40° arriba, y desde
# Y = 420 mirando abajo a la capa de pequeños.
close
command weather clear
command gamerule advance_time false
time 4000
command tp @s 170.5 90 166.5 0 -12
sleep 10
screenshot nubes-forma-horizonte
look 90 -40
sleep 3
screenshot nubes-forma-arriba
command tp @s 170.5 420 166.5 0 35
sleep 5
screenshot nubes-forma-encima
