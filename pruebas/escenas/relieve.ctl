# Relieve con [displacement] teselado (subsistema 18).
# Requiere un paquete de recursos LabPBR con mapa de altura (LabPBR 1.3 con altura en canal alfa de _n),
# como por ejemplo Vanilla PBR, Faithful PBR, Realistico o Bare Bones PBR.
# Sin dicho paquete, el terreno permanece plano e idéntico a vanilla (sin desplazamiento).
#
# Escena: pared y suelo de ladrillos de piedra (stone_bricks) iluminados con sol bajo rasante (time 23300).
# Recorridos de acercamiento a 16, 8, 4, 2 y 1 bloques, giros de 30° y avance de 1 en 1 bloque.

close
command weather clear
time 23300

# Construcción de la zona de prueba: suelo y pared vertical norte-sur en ladrillos de piedra
command fill 200 64 200 230 64 230 stone_bricks
sleep 1
command fill 210 65 205 210 75 225 stone_bricks
sleep 1

# Asegurar mano vacía
command clear @s
sleep 1

# ==============================================================================
# 1. Recorrido frente a la pared con sol rasante del este (incidencia lateral)
# ==============================================================================

# Distancia 16 bloques (X = 226.0, Y = 66, Z = 215.0, mirando al oeste 90° con sol lateral)
command tp @s 226.0 66 215.0 90 0
sleep 2
screenshot relieve-pared-16

# Distancia 8 bloques (X = 218.0)
command tp @s 218.0 66 215.0 90 0
sleep 2
screenshot relieve-pared-08

# Distancia 4 bloques (X = 214.0) con giros de 30°
command tp @s 214.0 66 215.0 90 0
sleep 2
screenshot relieve-pared-04
look 60 0
sleep 1
screenshot relieve-pared-04-g30
look 120 0
sleep 1
screenshot relieve-pared-04-gn30
look 90 0
sleep 0.5

# Avance de 1 en 1 bloque: a 3 bloques
command tp @s 213.0 66 215.0 90 0
sleep 1
screenshot relieve-pared-03

# Distancia 2 bloques (X = 212.0) con giros de 30°
command tp @s 212.0 66 215.0 90 0
sleep 2
screenshot relieve-pared-02
look 60 0
sleep 1
screenshot relieve-pared-02-g30
look 120 0
sleep 1
screenshot relieve-pared-02-gn30
look 90 0
sleep 0.5

# Distancia 1 bloque (X = 211.0) con giros de 30°
command tp @s 211.0 66 215.0 90 0
sleep 2
screenshot relieve-pared-01
look 60 0
sleep 1
screenshot relieve-pared-01-g30
look 120 0
sleep 1
screenshot relieve-pared-01-gn30
look 90 0
sleep 0.5

# ==============================================================================
# 2. Recorrido hacia el suelo con sol rasante (pitch 45°)
# ==============================================================================

# Altura 4 bloques sobre el suelo (Y = 68.0, mirando a 45° hacia abajo)
command tp @s 220.0 68 215.0 90 45
sleep 2
screenshot relieve-suelo-04
look 60 45
sleep 1
screenshot relieve-suelo-04-g30
look 120 45
sleep 1
screenshot relieve-suelo-04-gn30
look 90 45
sleep 0.5

# Avance hacia el suelo: altura 3 bloques (Y = 67.0)
command tp @s 220.0 67 215.0 90 45
sleep 1
screenshot relieve-suelo-03

# Altura 2 bloques sobre el suelo (Y = 66.0) con giros de 30°
command tp @s 220.0 66 215.0 90 45
sleep 2
screenshot relieve-suelo-02
look 60 45
sleep 1
screenshot relieve-suelo-02-g30
look 120 45
sleep 1
screenshot relieve-suelo-02-gn30
look 90 45
sleep 0.5

# Altura 1 bloque sobre el suelo (Y = 65.0) con giros de 30°
command tp @s 220.0 65 215.0 90 45
sleep 2
screenshot relieve-suelo-01
look 60 45
sleep 1
screenshot relieve-suelo-01-g30
look 120 45
sleep 1
screenshot relieve-suelo-01-gn30
look 90 45
