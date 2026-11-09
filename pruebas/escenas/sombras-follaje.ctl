# Recorrido de prueba para paridad de sombras de follaje (punto 8 del banco, niebla-amanecer):
# Penumbra suave y continua bajo las copas sin escalones ni bordes dentados.
# Pedido del dueño: acercarse/alejarse (16, 8, 4, 2, 1 bloques), girar 15–30° y cruzar de 1 en 1.
close
command weather clear
time 300

# 1. Acercarse al borde de la sombra del follaje (16, 8, 4, 2, 1 bloques)
command tp @s -48.5 71 88.5
look -90 15
sleep 2
screenshot sombra-follaje-16b

command tp @s -44.5 71 88.5
look -90 15
sleep 2
screenshot sombra-follaje-08b

command tp @s -42.5 71 88.5
look -90 15
sleep 2
screenshot sombra-follaje-04b

command tp @s -41.5 71 88.5
look -90 15
sleep 2
screenshot sombra-follaje-02b

command tp @s -40.5 71 88.5
look -90 15
sleep 2
screenshot sombra-follaje-01b

# 2. Girar la cámara en pasos de 15°–30° observando la transición de penumbra y hojas a contraluz
look -120 15
sleep 1
screenshot sombra-giro-n120

look -105 15
sleep 1
screenshot sombra-giro-n105

look -90 15
sleep 1
screenshot sombra-giro-n90

look -75 15
sleep 1
screenshot sombra-giro-n75

look -60 15
sleep 1
screenshot sombra-giro-n60

# 3. Recorrido a ras de suelo cruzando la penumbra de 1 en 1 bloque
command tp @s -43.5 71 88.5
look -90 30
sleep 1
screenshot sombra-paso-1

command tp @s -42.5 71 88.5
look -90 30
sleep 1
screenshot sombra-paso-2

command tp @s -41.5 71 88.5
look -90 30
sleep 1
screenshot sombra-paso-3

command tp @s -40.5 71 88.5
look -90 30
sleep 1
screenshot sombra-paso-4
