# Recorrido de prueba para los 17 presets de estilo (§2.2 de mapa-de-ajustes.md).
# El gestor ejecuta este guion con varios niveles de los presets de estilo.
# Contiene recorridos en movimiento (giros de 15–30°, aproximaciones de 16, 8, 4, 2 y 1 bloques,
# y cruce de superficies bloque a bloque):
# 1. Día (hora 6000): atmósfera, sol, nubes, niebla horaria, vegetación y AO.
# 2. Atardecer (hora 12000): sol en horizonte oeste, cinturón de Venus, color del cielo y aerosoles.
# 3. Noche con fractal (hora 18000): constelaciones del cielo fractal, cortinas de aurora y rayos.
# 4. Bajo el agua: cruce bloque a bloque, claridad, absorción por canal y cáusticas.
# 5. Cueva con antorcha: luz de bloque cálida/neutra/fría/vela y niveles de luz mínima subterránea.

close
command weather clear

# ==============================================================================
# 1. VISTA DE DÍA (atmósfera, niebla, nubes y vegetación)
# ==============================================================================
command tp @s 170.5 77 166.5
time 6000
wait-ready
sleep 3

# 1.1 Giro panorámico en pasos de 30°
look 0 -15
sleep 1
screenshot estilo-dia-rumbo-000
look 30 -15
sleep 0.5
look 60 -15
sleep 1
screenshot estilo-dia-rumbo-060
look 90 -15
sleep 0.5
look 120 -15
sleep 1
screenshot estilo-dia-rumbo-120
look 150 -15
sleep 0.5
look 180 -15
sleep 1
screenshot estilo-dia-rumbo-180
look -150 -15
sleep 0.5
look -120 -15
sleep 1
screenshot estilo-dia-rumbo-240
look -90 -15
sleep 0.5
look -60 -15
sleep 1
screenshot estilo-dia-rumbo-300

# 1.2 Inclinación hacia el cielo y nubes en pasos de 15°
look 0 -30
sleep 0.5
look 0 -45
sleep 1
screenshot estilo-dia-cielo-45
look 0 -60
sleep 0.5
look 0 -75
sleep 0.5
look 0 -90
sleep 1
screenshot estilo-dia-cielo-cenit

# 1.3 Acercamiento al suelo y vegetación (16, 8, 4, 2 y 1 bloques)
look 0 30
command tp @s 170.5 77 150.5
sleep 1
screenshot estilo-dia-dist-16
command tp @s 170.5 77 158.5
sleep 1
screenshot estilo-dia-dist-08
command tp @s 170.5 77 162.5
sleep 1
screenshot estilo-dia-dist-04
command tp @s 170.5 77 164.5
sleep 1
screenshot estilo-dia-dist-02
command tp @s 170.5 77 165.5
sleep 1
screenshot estilo-dia-dist-01

# ==============================================================================
# 2. VISTA DE ATARDECER (color del cielo, halo solar, aerosoles y cinturón de Venus)
# ==============================================================================
command tp @s 170.5 78 166.5
time 12000
wait-ready
sleep 3

# 2.1 Vista frontal al sol en el oeste
look 90 0
sleep 1
screenshot estilo-atardecer-sol-oeste
look 90 -15
sleep 0.5
look 90 -30
sleep 1
screenshot estilo-atardecer-halo-alto

# 2.2 Giro mirando al horizonte en pasos de 30° (cinturón de Venus en el este opuesto)
look 120 -5
sleep 0.5
look 150 -5
sleep 1
screenshot estilo-atardecer-rumbo-150
look 180 -5
sleep 0.5
look -150 -5
sleep 1
screenshot estilo-atardecer-este-venus
look -120 -5
sleep 0.5
look -90 -5
sleep 1
screenshot estilo-atardecer-rumbo-270

# ==============================================================================
# 3. VISTA DE NOCHE CON FRACTAL (cielo fractal, aurora y rayos)
# ==============================================================================
command tp @s 170.5 77 166.5
time 18000
wait-ready
sleep 3

# 3.1 Cenit hacia el fractal
look 0 -90
sleep 2
screenshot estilo-noche-fractal-cenit

# 3.2 Giro hacia el horizonte en pasos de 30° con cielo fractal y aurora
look 0 -45
sleep 1
screenshot estilo-noche-rumbo-000
look 30 -45
sleep 0.5
look 60 -45
sleep 1
screenshot estilo-noche-rumbo-060
look 90 -45
sleep 0.5
look 120 -45
sleep 1
screenshot estilo-noche-rumbo-120
look 150 -45
sleep 0.5
look 180 -45
sleep 1
screenshot estilo-noche-rumbo-180
look -150 -45
sleep 0.5
look -120 -45
sleep 1
screenshot estilo-noche-rumbo-240
look -90 -45
sleep 0.5
look -60 -45
sleep 1
screenshot estilo-noche-rumbo-300

# 3.3 Inclinación de 15 en 15° hacia el horizonte de la aurora
look 0 -60
sleep 0.5
look 0 -45
sleep 0.5
screenshot estilo-noche-aurora-45
look 0 -30
sleep 0.5
look 0 -15
sleep 1
screenshot estilo-noche-aurora-15
look 0 0
sleep 1
screenshot estilo-noche-aurora-00

# ==============================================================================
# 4. VISTA BAJO EL AGUA (claridad, absorción RGB, cáusticas y cruce)
# ==============================================================================
time 6000
command tp @s 125.5 64.0 245.5 0 20
wait-ready
sleep 2

# 4.1 Cruce de la superficie bloque a bloque (y = 64, 63, 62, 61, 60)
screenshot estilo-agua-cruce-y64
command tp @s 125.5 63.0 245.5 0 20
sleep 1
screenshot estilo-agua-cruce-y63
command tp @s 125.5 62.0 245.5 0 20
sleep 1
screenshot estilo-agua-cruce-y62
command tp @s 125.5 61.0 245.5 0 20
sleep 1
screenshot estilo-agua-cruce-y61
command tp @s 125.5 60.0 245.5 0 20
sleep 1
screenshot estilo-agua-cruce-y60

# 4.2 Mirada arriba a la superficie (cáusticas y ondas)
look 0 -60
sleep 1
screenshot estilo-agua-superficie-arriba

# 4.3 Acercamiento al fondo marino (16, 8, 4, 2 y 1 bloques)
look 0 45
command tp @s 125.5 56.0 230.5
sleep 1
screenshot estilo-agua-fondo-dist-16
command tp @s 125.5 56.0 238.5
sleep 1
screenshot estilo-agua-fondo-dist-08
command tp @s 125.5 56.0 242.5
sleep 1
screenshot estilo-agua-fondo-dist-04
command tp @s 125.5 56.0 244.5
sleep 1
screenshot estilo-agua-fondo-dist-02
command tp @s 125.5 56.0 245.5
sleep 1
screenshot estilo-agua-fondo-dist-01

# ==============================================================================
# 5. VISTA EN CUEVA CON ANTORCHA (luz de bloque cálida/neutra/fría/vela y luz mínima)
# ==============================================================================
command fill 230 118 230 262 126 242 stone
sleep 1
command fill 231 119 231 261 125 241 air
sleep 1
command setblock 232 119 236 torch
sleep 1

# 5.1 Acercamiento a la antorcha (16, 8, 4, 2 y 1 bloques)
command tp @s 248.5 119 236.5 90 10
sleep 2
screenshot estilo-cueva-antorcha-dist-16
command tp @s 240.5 119 236.5 90 10
sleep 1
screenshot estilo-cueva-antorcha-dist-08
command tp @s 236.5 119 236.5 90 15
sleep 1
screenshot estilo-cueva-antorcha-dist-04
command tp @s 234.5 119 236.5 90 25
sleep 1
screenshot estilo-cueva-antorcha-dist-02
command tp @s 233.5 119 236.5 90 40
sleep 1
screenshot estilo-cueva-antorcha-dist-01

# 5.2 Giro de 30 en 30° alrededor de la antorcha
command tp @s 236.5 119 236.5
look 90 0
sleep 1
screenshot estilo-cueva-giro-090
look 120 0
sleep 0.5
look 150 0
sleep 1
screenshot estilo-cueva-giro-150
look 180 0
sleep 0.5
look -150 0
sleep 1
screenshot estilo-cueva-giro-210
look -120 0
sleep 0.5
look -90 0
sleep 1
screenshot estilo-cueva-giro-270

# 5.3 Cueva sin antorcha (evaluación de luz mínima subterránea: abiertas vs oscuras vs muy oscuras)
command setblock 232 119 236 air
sleep 2
screenshot estilo-cueva-oscuridad-minima

# Restaurar antorcha y posición
command setblock 232 119 236 torch
command tp @s 170.5 77 166.5 0 0
wait-ready
