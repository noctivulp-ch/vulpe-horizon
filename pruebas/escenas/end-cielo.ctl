# Cielo del End (B-23 §2.1): desde (0,5, 90, 120,5) mirando al centro (el vórtice) y lejos de él 35° arriba
# (como original-noche/end-cielo), y desde (250, 90, 0) hacia fuera.
close
command gamemode spectator
command execute in minecraft:the_end run tp @s 0.5 90 120.5 180 -10
sleep 14
look 180 -10
sleep 2
screenshot end-cielo-vortice
look 0 -35
sleep 3
screenshot end-cielo-fuera
command execute in minecraft:the_end run tp @s 250.5 90 0.5 -90 5
sleep 6
look -90 -10
sleep 3
screenshot end-cielo-lejos
command execute in minecraft:overworld run tp @s 301.5 103.5 296.5 0 40
