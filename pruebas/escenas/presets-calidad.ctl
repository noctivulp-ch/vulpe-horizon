# Recorrido de prueba para los presets de calidad (§2.1 de mapa-de-ajustes.md).
# El gestor ejecuta este guion con cada nivel de calidad (Baja, Media, Alta, Ultra).
# Contiene recorridos en movimiento (giros de 15–30°, aproximaciones de 16, 8, 4, 2 y 1 bloques):
# 1. Día (hora 3000): niebla volumétrica, nubes por capas, sombras y oclusión ambiental.
# 2. Noche (hora 18000): cielo fractal, iteraciones del dibujo y cortinas de la aurora.

close
command weather clear

# ==============================================================================
# PARTE 1: DÍA — Niebla, nubes, sombras y AO
# ==============================================================================
command tp @s 170.5 77 166.5
time 3000
wait-ready
sleep 3

# 1.1 Giro panorámico en pasos de 30° (horizonte con niebla y nubes bajas)
look 0 -15
sleep 1
screenshot calidad-dia-rumbo-000
look 30 -15
sleep 0.5
look 60 -15
sleep 1
screenshot calidad-dia-rumbo-060
look 90 -15
sleep 0.5
look 120 -15
sleep 1
screenshot calidad-dia-rumbo-120
look 150 -15
sleep 0.5
look 180 -15
sleep 1
screenshot calidad-dia-rumbo-180
look -150 -15
sleep 0.5
look -120 -15
sleep 1
screenshot calidad-dia-rumbo-240
look -90 -15
sleep 0.5
look -60 -15
sleep 1
screenshot calidad-dia-rumbo-300

# 1.2 Inclinación hacia las nubes en pasos de 15°
look 0 -30
sleep 0.5
look 0 -45
sleep 1
screenshot calidad-dia-nubes-45
look 0 -60
sleep 0.5
look 0 -75
sleep 0.5
look 0 -90
sleep 1
screenshot calidad-dia-nubes-cenit

# 1.3 Acercamiento hacia el suelo y pared de 16, 8, 4, 2 y 1 bloques (sombras y AO en movimiento)
look 0 35
command tp @s 170.5 77 150.5
sleep 1
screenshot calidad-dia-dist-16
command tp @s 170.5 77 158.5
sleep 1
screenshot calidad-dia-dist-08
command tp @s 170.5 77 162.5
sleep 1
screenshot calidad-dia-dist-04
command tp @s 170.5 77 164.5
sleep 1
screenshot calidad-dia-dist-02
command tp @s 170.5 77 165.5
sleep 1
screenshot calidad-dia-dist-01

# 1.4 Subida en altitud cruzando la capa de niebla
command tp @s 170.5 120 166.5
look 0 -10
sleep 1
screenshot calidad-dia-altura-120
command tp @s 170.5 220 166.5
look 0 -10
sleep 1
screenshot calidad-dia-altura-220
command tp @s 170.5 320 166.5
look 0 0
sleep 1
screenshot calidad-dia-altura-320

# ==============================================================================
# PARTE 2: NOCHE — Cielo fractal y aurora
# ==============================================================================
command tp @s 170.5 77 166.5
time 18000
wait-ready
sleep 3

# 2.1 Vista al cenit del cielo fractal
look 0 -90
sleep 2
screenshot calidad-noche-fractal-cenit

# 2.2 Giro mirando al cielo fractal y horizonte con aurora en pasos de 30°
look 0 -45
sleep 1
screenshot calidad-noche-rumbo-000
look 30 -45
sleep 0.5
look 60 -45
sleep 1
screenshot calidad-noche-rumbo-060
look 90 -45
sleep 0.5
look 120 -45
sleep 1
screenshot calidad-noche-rumbo-120
look 150 -45
sleep 0.5
look 180 -45
sleep 1
screenshot calidad-noche-rumbo-180
look -150 -45
sleep 0.5
look -120 -45
sleep 1
screenshot calidad-noche-rumbo-240
look -90 -45
sleep 0.5
look -60 -45
sleep 1
screenshot calidad-noche-rumbo-300

# 2.3 Ajuste de inclinación de 15 en 15° hacia el horizonte de la aurora
look 0 -75
sleep 0.5
look 0 -60
sleep 0.5
look 0 -45
sleep 0.5
screenshot calidad-noche-aurora-45
look 0 -30
sleep 0.5
look 0 -15
sleep 1
screenshot calidad-noche-aurora-15
look 0 0
sleep 1
screenshot calidad-noche-aurora-00

command tp @s 170.5 77 166.5
wait-ready
