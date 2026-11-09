# Comprobación de los datos del mod nativo (formato v1) y vista de depuración.
#
# Cómo probar las dos modalidades (el gestor):
# 1. Modo normal (`OPC_DEPURACION_VISTA_DEFECTO = 0u` en `opciones/depuracion.wgsl`):
#    - Muestra el mundo con iluminación normal.
#    - De noche (/time set 18000): la luz lunar sigue la fase (Luna Llena en día 0, Luna Nueva en día 4 con noche oscura).
#    - Estaciones en el follaje: día 0 (Primavera fresca), día 24 (Verano natural), día 48 (Otoño ocre/anaranjado), día 72 (Invierno desaturado).
# 2. Vista de depuración («Mod nativo», `OPC_DEPURACION_VISTA_DEFECTO = 8u` en `opciones/depuracion.wgsl`):
#    - Franja superior: verde esmeralda con firma 1001.0 y banderas (tiempo, estación, etc.). Rojo si no hay mod.
#    - Franja central: 8 casillas de fase lunar (0..7). La casilla actual brilla en dorado/blanco con disco lunar.
#    - Franja inferior: 4 cuadrantes estacionales (Primavera, Verano, Otoño, Invierno) con progreso y aguja blanca en estacion/4.
#    - Esquina superior izquierda (4% x 4%): píxeles exactos R = activo (1.0), G = fase/7, B = estacion/4.
#
# Recorridos en movimiento: acercamiento a 16, 8, 4, 2 y 1 bloques, giros de 15–30° y avance paso a paso.

close
command weather clear

# Plataforma de prueba con césped y hojas de roble en Y = 100
command fill 190 99 190 230 115 230 air
sleep 1
command fill 195 100 195 225 100 225 grass_block
sleep 1
command fill 205 101 205 215 105 215 oak_leaves
sleep 1
command clear @s
sleep 1

# ==============================================================================
# 1. Recorrido frente al follaje (acercamiento 16, 8, 4, 2 y 1 bloques)
# ==============================================================================

# Día 0, amanecer (/time set 0) -> Luna Llena (0), Primavera (0.000)
command time set 0
sleep 1

# Distancia 16 bloques (X = 205, Y = 102, Z = 189, mirando al sur 0°)
command tp @s 210.0 102 189.0 0 0
sleep 2
screenshot mod-nativo-d0-16

# Distancia 8 bloques
command tp @s 210.0 102 197.0 0 0
sleep 1
screenshot mod-nativo-d0-08

# Avance de 1 en 1 bloque (7, 6, 5)
command tp @s 210.0 102 198.0 0 0
sleep 0.5
command tp @s 210.0 102 199.0 0 0
sleep 0.5
command tp @s 210.0 102 200.0 0 0
sleep 0.5

# Distancia 4 bloques
command tp @s 210.0 102 201.0 0 0
sleep 1
screenshot mod-nativo-d0-04

# Giros en pasos de 15° y 30° a 4 bloques
command tp @s 210.0 102 201.0 15 0
sleep 0.5
screenshot mod-nativo-d0-g15
command tp @s 210.0 102 201.0 30 0
sleep 0.5
screenshot mod-nativo-d0-g30
command tp @s 210.0 102 201.0 -15 0
sleep 0.5
screenshot mod-nativo-d0-gn15
command tp @s 210.0 102 201.0 -30 0
sleep 0.5
screenshot mod-nativo-d0-gn30
command tp @s 210.0 102 201.0 0 0
sleep 0.5

# Distancia 2 bloques
command tp @s 210.0 102 203.0 0 0
sleep 1
screenshot mod-nativo-d0-02

# Distancia 1 bloque (frente a la superficie de hojas)
command tp @s 210.0 102 204.0 0 0
sleep 1
screenshot mod-nativo-d0-01

# ==============================================================================
# 2. Noche y fases lunares
# ==============================================================================

# Día 0, noche (/time set 18000) -> Luna Llena (fase 0, factor 1.0)
command time set 18000
sleep 2
command tp @s 210.0 102 201.0 0 45
sleep 1
screenshot mod-nativo-noche-fase0

# Día 1, noche (/time set 42000) -> Gibosa Menguante (fase 1, factor 0.75)
command time set 42000
sleep 2
screenshot mod-nativo-noche-fase1

# Día 4, noche (/time set 114000) -> Luna Nueva (fase 4, factor 0.0, noche oscura)
command time set 114000
sleep 2
screenshot mod-nativo-noche-fase4

# ==============================================================================
# 3. Ciclo de estaciones a mediodía (time 6000)
# ==============================================================================

# Día 0: Primavera (estación 0.0)
command time set 6000
command tp @s 210.0 102 201.0 0 0
sleep 2
screenshot mod-nativo-estacion-primavera

# Día 24: Verano (estación 1.0) -> /time set 582000
command time set 582000
sleep 2
screenshot mod-nativo-estacion-verano

# Día 48: Otoño (estación 2.0) -> /time set 1158000
command time set 1158000
sleep 2
screenshot mod-nativo-estacion-otono

# Día 72: Invierno (estación 3.0) -> /time set 1734000
command time set 1734000
sleep 2
screenshot mod-nativo-estacion-invierno
