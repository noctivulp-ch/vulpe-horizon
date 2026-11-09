# Recorrido de verificación de gotas en la cámara al salir del agua (07.2).
# Estanque de agua en exteriores a mediodía (time 6000).
# Cruce de la superficie del agua bloque a bloque y capturas temporales exactas a los 0, 1, 2 y 4 s tras salir,
# seguido de recorrido alejándose (1, 2, 4, 8 y 16 bloques) y giros de cámara de 15–30°.
close
command weather clear
time 6000

# Construcción de un estanque de agua (100 60 100 a 115 65 115) con brocal de piedra
command fill 100 60 100 115 65 115 stone
sleep 1
command fill 102 61 102 113 64 113 water
sleep 1
command fill 102 65 102 113 68 113 air
sleep 1

# Posicionamiento inicial bajo el agua (sumergido en X=105 Y=62.5 Z=105)
command tp @s 105.0 62.5 105.0 0 0
sleep 2

# ==============================================================================
# 1. Salida del agua bloque a bloque y capturas temporales (0, 1, 2 y 4 s)
# ==============================================================================
# Paso 1: subida al nivel del borde (aún sumergido)
command tp @s 105.0 63.8 105.0 0 0
sleep 0.5

# Paso 2: salir del agua sobre el brocal seco (X=105.0 Y=66.0 Z=101.0, mirando al estanque al sur)
command tp @s 105.0 66.0 101.0 0 0

# Captura inmediata: 0 s tras salir del agua (gotas completas, máxima distorsión)
screenshot gotas-00s

# Captura a 1 s (gotas escurriendo hacia abajo, intensidad media)
sleep 1
screenshot gotas-01s

# Captura a 2 s (1 s más, gotas residuales desvaneciéndose)
sleep 1
screenshot gotas-02s

# Captura a 4 s (2 s más, lente completamente limpia)
sleep 2
screenshot gotas-04s

# ==============================================================================
# 2. Recorrido alejándose del agua (1, 2, 4, 8 y 16 bloques) y giros de 15–30°
# ==============================================================================
# A 1 bloque del brocal (Z = 100.0)
command tp @s 105.0 66.0 100.0 0 0
sleep 0.5
screenshot gotas-recorrido-01b
look -20 0
sleep 0.3
screenshot gotas-recorrido-01b-gn20
look 20 0
sleep 0.3
screenshot gotas-recorrido-01b-g20
look 0 0

# A 2 bloques (Z = 99.0)
command tp @s 105.0 66.0 99.0 0 0
sleep 0.5
screenshot gotas-recorrido-02b

# A 4 bloques (Z = 97.0)
command tp @s 105.0 66.0 97.0 0 0
sleep 0.5
screenshot gotas-recorrido-04b
look -30 0
sleep 0.3
screenshot gotas-recorrido-04b-gn30
look 30 0
sleep 0.3
screenshot gotas-recorrido-04b-g30
look 0 0

# A 8 bloques (Z = 93.0)
command tp @s 105.0 66.0 93.0 0 0
sleep 0.5
screenshot gotas-recorrido-08b

# A 16 bloques (Z = 85.0)
command tp @s 105.0 66.0 85.0 0 0
sleep 0.5
screenshot gotas-recorrido-16b
