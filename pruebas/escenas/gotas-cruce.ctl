# Comprobación de gotas en cámara en f32 (F-73b):
# 1) Teletransporte saliendo del agua (antes congelaba el contador f16 a nivel=7): capturas a 0, 2, 5 y 10 s.
# 2) Entrada y salida del Nether: sin gotas atascadas; capturas a 0, 2, 5 y 10 s.
close
command weather clear
command gamerule advance_time false
time 6000

# 1. Teletransporte desde bajo el agua (y=58) hacia fuera (y=66) en el mar (125, 245).
command tp @s 125.5 58 245.5 0 10
sleep 2
command tp @s 125.5 66 245.5 0 10
sleep 0.2
screenshot gotas-tp-0s
sleep 1.8
screenshot gotas-tp-2s
sleep 3
screenshot gotas-tp-5s
sleep 5
screenshot gotas-tp-10s

# 2. Entrar y salir del Nether (cambio de dimensión limpia el estado).
command execute in minecraft:the_nether run tp @s 0.5 70 0.5
sleep 2
command execute in minecraft:overworld run tp @s 166.5 95 152.5 0 10
sleep 0.2
screenshot gotas-nether-0s
sleep 1.8
screenshot gotas-nether-2s
sleep 3
screenshot gotas-nether-5s
sleep 5
screenshot gotas-nether-10s
