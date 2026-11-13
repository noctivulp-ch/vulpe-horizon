# Nether y End en las mismas vistas que vulpe-horizon-spec/referencias/original-dimensiones (mundo de semilla 1).
close
command gamemode spectator
command execute in minecraft:the_nether run tp @s 0.5 100 0.5 0 20
sleep 14
screenshot dim-nether-yermo
look 0 0
sleep 3
screenshot dim-nether-yermo-horizonte
look 0 60
sleep 3
screenshot dim-nether-suelo
command execute in minecraft:the_nether run tp @s 224.5 100 192.5 0 20
sleep 10
screenshot dim-nether-carmesi
command execute in minecraft:the_nether run tp @s -63.5 100 -127.5 0 20
sleep 10
screenshot dim-nether-distorsionado
command execute in minecraft:the_nether run tp @s 64.5 100 64.5 0 20
sleep 10
screenshot dim-nether-almas
command execute in minecraft:the_nether run tp @s -63.5 100 64.5 0 20
sleep 10
screenshot dim-nether-basalto
command execute in minecraft:the_end run tp @s 0.5 90 120.5 180 -10
sleep 14
look 180 -10
sleep 2
screenshot dim-end-vortice
command execute in minecraft:the_end run tp @s 0.5 70 120.5 180 -60
sleep 5
look 180 -60
sleep 2
screenshot dim-end-arriba
look 180 45
sleep 3
screenshot dim-end-suelo
command execute in minecraft:overworld run tp @s 474.5 104 193.5 45 20
