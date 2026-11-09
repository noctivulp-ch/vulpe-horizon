# Recorrido de prueba para color y gradiente del cielo calibrados con la tabla de paridad (B-16.4)
# Hora 6000 (mediodía): barrido desde el cenit hasta el horizonte en pasos de 15-30° y azimuts de 0° (hacia el sol), 45° y 90°.
close
command weather clear
time 6000
sleep 1

# 1. Mirando directo al cenit (pitch -90°) a mediodía (azul profundo calibrado: R~0.018, G~0.039, B~0.094)
command tp @s 170.5 80 166.5
look 0 -90
sleep 1
screenshot cielo-cenit-90

# 2. Descenso de inclinación hacia el sol (sur: yaw 0) en pasos de 15°
look 0 -75
sleep 0.5
screenshot cielo-sol-p75

look 0 -60
sleep 0.5
screenshot cielo-sol-p60

look 0 -45
sleep 0.5
screenshot cielo-sol-p45

look 0 -30
sleep 0.5
screenshot cielo-sol-p30

look 0 -15
sleep 0.5
screenshot cielo-sol-p15

look 0 0
sleep 0.5
screenshot cielo-sol-p00

# 3. Giro azimutal a 45° de elevación: pasos de 30° alrededor de la bóveda celeste
look 0 -45
sleep 0.5
screenshot cielo-giro-y00-p45

look 30 -45
sleep 0.5
screenshot cielo-giro-y30-p45

look 60 -45
sleep 0.5
screenshot cielo-giro-y60-p45

look 90 -45
sleep 0.5
screenshot cielo-giro-y90-p45

look 120 -45
sleep 0.5
screenshot cielo-giro-y120-p45

look 180 -45
sleep 0.5
screenshot cielo-giro-y180-p45

# 4. Horizonte a 2° de elevación (hacia el sol y antisolar)
look 0 -2
sleep 0.5
screenshot cielo-horiz-sol-p2

look 180 -2
sleep 0.5
screenshot cielo-horiz-anti-p2
