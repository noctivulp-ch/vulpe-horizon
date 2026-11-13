# Luz de noche, del Nether y del End (observaciones del dueño 2.1 y 2.2): medianoche con luna llena a cielo abierto
# mirando el terreno a ~20 bloques; el Nether y el End mirando el terreno. Hora congelada.
close
command weather clear
command gamerule advance_time false
time 18000
command tp @s 150.5 80 230.5 -150 25
sleep 10
screenshot luz-noche
command execute in minecraft:the_nether run tp @s 0.5 80 0.5 0 30
sleep 12
screenshot luz-nether
command execute in minecraft:the_end run tp @s 60.5 75 0.5 90 20
sleep 12
screenshot luz-end
command execute in minecraft:overworld run tp @s 150.5 80 230.5 -150 25
