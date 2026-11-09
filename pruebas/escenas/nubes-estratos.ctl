# Recorrido de prueba para nubes con bordes rotos, capas y sombras inter-capa (B-16.5)
# Hora 6000 (mediodía): inspección hacia arriba (pitch -70° y -55°) girando 360° en pasos de 30°
# y aproximación vertical cruzando capas de 1 en 1 bloque para evaluar bordes rotos y sombreado mutuo.
close
command weather clear
time 6000
sleep 1

# 1. Mirando 70° hacia arriba (escena nubes-dia del banco): bordes rotos y claros entre cúmulos
command tp @s 170.5 80 166.5
look 0 -70
sleep 1
screenshot nubes-dia-p70-y00

# Giros en pasos de 30° alrededor de la bóveda
look 30 -70
sleep 0.5
screenshot nubes-dia-p70-y30

look 60 -70
sleep 0.5
screenshot nubes-dia-p70-y60

look 90 -70
sleep 0.5
screenshot nubes-dia-p70-y90

look 120 -70
sleep 0.5
screenshot nubes-dia-p70-y120

look 180 -70
sleep 0.5
screenshot nubes-dia-p70-y180

# 2. Mirando 55° hacia arriba (escena cielo-dia del banco): aureola del sol y fragmentación de cúmulos
look 0 -55
sleep 0.5
screenshot cielo-nubes-p55-y00

look 45 -55
sleep 0.5
screenshot cielo-nubes-p55-y45

look 90 -55
sleep 0.5
screenshot cielo-nubes-p55-y90

# 3. Elevación de la cámara para cruzar la base de los cúmulos bajos (Y=245 a Y=255 en pasos de 2 y 1 bloques)
command tp @s 170.5 240 166.5
look 0 -45
sleep 0.5
screenshot nubes-subida-y240

command tp @s 170.5 248 166.5
look 0 -45
sleep 0.5
screenshot nubes-subida-y248

command tp @s 170.5 250 166.5
look 0 -45
sleep 0.5
screenshot nubes-subida-y250

command tp @s 170.5 251 166.5
look 0 -45
sleep 0.5
screenshot nubes-subida-y251

command tp @s 170.5 252 166.5
look 0 -45
sleep 0.5
screenshot nubes-subida-y252

command tp @s 170.5 254 166.5
look 0 -45
sleep 0.5
screenshot nubes-subida-y254

# 4. Vista hacia el horizonte desde el interior de la capa para verificar neblina atmosférica interna
look 0 -5
sleep 0.5
screenshot nubes-horizonte-inmerso
