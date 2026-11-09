# Recorrido de prueba B-17.9: luz mínima en cueva con linterna de cámara frontal y tinte neutro
# Cueva subterránea sin luz de cielo a hora 18000.
# Verifica:
# 1. Distancias 16, 8, 4, 2 y 1 bloques: el fondo a 16 bloques se funde en oscuridad absoluta, mientras
#    que a 2 y 1 bloques el entibado de madera frontal se distingue sutilmente.
# 2. Giros de cámara de 15° y 30°: linterna direccional aclara caras perpendiculares y apaga caras rasantes.
# 3. Tinte de niebla y ambiente completamente neutro, sin azul escotópico/Purkinje ni niebla saturada.

close
command weather clear
time 18000
sleep 1

# Construcción de la galería subterránea (X: 100..130, Y: 10..14, Z: 100..106)
command fill 100 9 100 130 15 106 deepslate
sleep 1
command fill 101 10 101 129 14 105 air
sleep 1

# Entibado de madera de roble a X=103 (cerca del fondo oeste X=101)
command fill 103 10 101 103 14 101 oak_fence
command fill 103 10 105 103 14 105 oak_fence
command fill 103 14 101 103 14 105 oak_planks
sleep 1

# Mano vacía para no emitir luz de mano
command clear @s
sleep 1

# 1. Distancia 16 bloques al entibado (jugador en X=119.0, mirando hacia el oeste yaw -90 / 270)
command tp @s 119.0 10.0 103.0 -90 0
sleep 10
screenshot cueva-recorrido-16b
look -75 0
sleep 1
screenshot cueva-recorrido-16b-g15
look -60 0
sleep 1
screenshot cueva-recorrido-16b-g30

# 2. Distancia 8 bloques (jugador en X=111.0)
command tp @s 111.0 10.0 103.0 -90 0
sleep 2
screenshot cueva-recorrido-08b
look -105 0
sleep 1
screenshot cueva-recorrido-08b-g15

# 3. Distancia 4 bloques (jugador en X=107.0)
command tp @s 107.0 10.0 103.0 -90 0
sleep 2
screenshot cueva-recorrido-04b
look -75 0
sleep 1
screenshot cueva-recorrido-04b-g15
look -60 0
sleep 1
screenshot cueva-recorrido-04b-g30

# 4. Distancia 2 bloques (jugador en X=105.0)
command tp @s 105.0 10.0 103.0 -90 0
sleep 2
screenshot cueva-recorrido-02b
look -75 0
sleep 1
screenshot cueva-recorrido-02b-g15
look -105 0
sleep 1
screenshot cueva-recorrido-02b-g-15

# 5. Distancia 1 bloque (jugador en X=104.0, frente a la madera)
command tp @s 104.0 10.0 103.0 -90 0
sleep 2
screenshot cueva-recorrido-01b
look -90 20
sleep 1
screenshot cueva-recorrido-01b-abajo
look -90 -20
sleep 1
screenshot cueva-recorrido-01b-arriba
