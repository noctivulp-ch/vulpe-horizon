# Nether contra referencias/original-dimensiones (B-23 §7): yermo mirando 20° abajo, suelo 60° abajo, yermo al frente,
# y valle de almas. Normal; con OPC_DEPURACION_VISTA_DEFECTO = 17 da la opacidad (como las *-forma del original).
close
command gamemode spectator
command execute in minecraft:the_nether run tp @s 0.5 100 0.5 0 20
sleep 14
look 0 20
sleep 3
screenshot dim-nether-yermo
look 0 60
sleep 2
screenshot dim-nether-suelo
look 0 0
sleep 2
screenshot dim-nether-yermo-horizonte
command execute in minecraft:the_nether run tp @s 64.5 100 64.5 0 20
sleep 10
look 0 20
sleep 2
screenshot dim-nether-almas
command execute in minecraft:overworld run tp @s 301.5 103.5 296.5 0 40
