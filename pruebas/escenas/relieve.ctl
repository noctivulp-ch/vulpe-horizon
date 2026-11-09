# Relieve con [displacement] teselado (subsistema 18).
# Requiere un paquete de recursos LabPBR con mapa de altura (LabPBR 1.3 con altura en canal alfa de _n),
# como por ejemplo VibrantPBR R1.15, Vanilla PBR, Faithful PBR, Realistico o Bare Bones PBR.
# Sin dicho paquete, el terreno permanece plano e idéntico a vanilla (sin desplazamiento).
#
# Escena construida en el aire (Y = 100, jugador en Y = 101..104) para evitar quedar dentro del terreno del mundo:
# - Suelo de ladrillos de piedra (stone_bricks) en X = 200..230, Y = 100, Z = 200..230.
# - Pared vertical norte-sur en X = 210, Y = 101..111, Z = 205..225.
# - Sol bajo rasante (time 1000) iluminando de lado las juntas y cantos.
#
# Cómo probar las variantes (el gestor):
# 1. Con `relieve` al valor por defecto (0,25) y `OPC_DEPURACION_VISTA_DEFECTO = 0u` en `opciones/depuracion.wgsl`.
# 2. Con `relieve = 0.0` (en opciones del shader o `override relieve: f32 = 0.0` en `opciones/relieve.wgsl`).
# 3. Con la vista de depuración del relieve: fijar `OPC_DEPURACION_VISTA_DEFECTO = 7u` (`OPC_VISTA_RELIEVE`)
#    en `opciones/depuracion.wgsl` (recarga en caliente sin gastar otra opción del manifiesto):
#    - Canal R = `MaterialInput.displaced` (1,0 cerca de la cámara si la malla se desplaza; cae a 0,0 en 12 bloques).
#    - Canal G = altura LabPBR normalizada desde `OPC_RELIEVE_PISO_ALTURA = 0.85` (1,0 en ladrillos, ~0,13 en juntas).
#    - Canal B = `block_pbr_maps()` (1,0 si Horizon ha cargado mapas PBR).
#
# Recorridos en movimiento: acercamiento a 16, 8, 4, 2 y 1 bloques, giros de 15–30° y avance de 1 en 1 bloque.

close
command weather clear
time 1000

# Limpieza del volumen aéreo y construcción de suelo (Y = 100) y pared (X = 210, Y = 101..111)
command fill 198 99 198 232 115 232 air
sleep 1
command fill 200 100 200 230 100 230 stone_bricks
sleep 1
command fill 210 101 205 210 111 225 stone_bricks
sleep 1

# Asegurar mano vacía
command clear @s
sleep 1

# ==============================================================================
# 1. Recorrido frente a la pared con sol bajo (time 1000, mirando al oeste 90°)
# ==============================================================================

# Distancia 16 bloques (X = 226.0, Y = 101, Z = 215.0: fuera del radio de [displacement] = 12)
command tp @s 226.0 101 215.0 90 0
sleep 2
screenshot relieve-pared-16

# Distancia 8 bloques (X = 218.0: dentro de la zona de atenuación cuadrática)
command tp @s 218.0 101 215.0 90 0
sleep 2
screenshot relieve-pared-08

# Avance de 1 en 1 bloque desde 8 hasta 4 bloques
command tp @s 217.0 101 215.0 90 0
sleep 0.5
command tp @s 216.0 101 215.0 90 0
sleep 0.5
command tp @s 215.0 101 215.0 90 0
sleep 0.5

# Distancia 4 bloques (X = 214.0: relieve al 100 %) con giros de 15° y 30°
command tp @s 214.0 101 215.0 90 0
sleep 2
screenshot relieve-pared-04
look 75 0
sleep 1
screenshot relieve-pared-04-g15
look 60 0
sleep 1
screenshot relieve-pared-04-g30
look 105 0
sleep 1
screenshot relieve-pared-04-gn15
look 120 0
sleep 1
screenshot relieve-pared-04-gn30
look 90 0
sleep 0.5

# Avance de 1 en 1 bloque: a 3 bloques (X = 213.0)
command tp @s 213.0 101 215.0 90 0
sleep 1
screenshot relieve-pared-03

# Distancia 2 bloques (X = 212.0) con giros de 15° y 30°
command tp @s 212.0 101 215.0 90 0
sleep 2
screenshot relieve-pared-02
look 75 0
sleep 1
screenshot relieve-pared-02-g15
look 60 0
sleep 1
screenshot relieve-pared-02-g30
look 105 0
sleep 1
screenshot relieve-pared-02-gn15
look 120 0
sleep 1
screenshot relieve-pared-02-gn30
look 90 0
sleep 0.5

# Distancia 1 bloque (X = 211.0, pegado a la cara X = 210) con giros de 15° y 30°
command tp @s 211.0 101 215.0 90 0
sleep 2
screenshot relieve-pared-01
look 75 0
sleep 1
screenshot relieve-pared-01-g15
look 60 0
sleep 1
screenshot relieve-pared-01-g30
look 105 0
sleep 1
screenshot relieve-pared-01-gn15
look 120 0
sleep 1
screenshot relieve-pared-01-gn30
look 90 0
sleep 0.5

# ==============================================================================
# 2. Recorrido sobre el suelo cruzando de 1 en 1 bloque (Y = 101, pitch 45°)
# ==============================================================================

# Cruce de 1 en 1 bloque mirando al suelo y a la base de la pared (X = 216 -> 212)
command tp @s 216.0 101 215.0 90 45
sleep 2
screenshot relieve-suelo-x216
command tp @s 215.0 101 215.0 90 45
sleep 1
screenshot relieve-suelo-x215
command tp @s 214.0 101 215.0 90 45
sleep 1
screenshot relieve-suelo-x214
look 60 45
sleep 1
screenshot relieve-suelo-x214-g30
look 120 45
sleep 1
screenshot relieve-suelo-x214-gn30
look 90 45
sleep 0.5
command tp @s 213.0 101 215.0 90 45
sleep 1
screenshot relieve-suelo-x213
command tp @s 212.0 101 215.0 90 45
sleep 2
screenshot relieve-suelo-x212
look 60 45
sleep 1
screenshot relieve-suelo-x212-g30
look 120 45
sleep 1
screenshot relieve-suelo-x212-gn30
look 90 45
sleep 0.5

# Limpieza al terminar
command fill 198 99 198 232 115 232 air
