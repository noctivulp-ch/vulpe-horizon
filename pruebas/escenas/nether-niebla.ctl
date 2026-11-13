# Niebla del Nether (observación del dueño 6.1): desde Y 70 mirando horizontal y desde Y 50 mirando al mar de lava,
# en el desierto de almas/yermos de (0, 0) del mundo de pruebas.
close
command execute in minecraft:the_nether run tp @s 0.5 70 0.5 0 0
sleep 12
screenshot nether-niebla-70
command execute in minecraft:the_nether run tp @s 0.5 50 0.5 0 20
sleep 4
screenshot nether-niebla-50
command execute in minecraft:overworld run tp @s 150.5 80 230.5 -150 25
