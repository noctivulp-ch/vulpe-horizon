# Recorrido de prueba para paridad de agua (punto 6 del banco):
# Olas, destello solar en movimiento, cáusticas proyectadas oblicuamente en la orilla
# y color azul profundo con la profundidad y distancia.
# Pedido del dueño: acercarse/alejarse (16, 8, 4, 2, 1 bloques), girar 15–30° y cruzar de 1 en 1.
close
command weather clear
time 6000

# 1. Acercarse a la orilla del mar (16, 8, 4, 2, 1 bloques) observando olas y cáusticas
command tp @s 150.5 68 209.5
look 0 25
sleep 2
screenshot agua-recorrido-16b

command tp @s 150.5 68 217.5
look 0 25
sleep 2
screenshot agua-recorrido-08b

command tp @s 150.5 68 221.5
look 0 25
sleep 2
screenshot agua-recorrido-04b

command tp @s 150.5 68 223.5
look 0 25
sleep 2
screenshot agua-recorrido-02b

command tp @s 150.5 68 224.5
look 0 25
sleep 2
screenshot agua-recorrido-01b

# 2. Giro de cámara en pasos de 15°–30° barriendo el destello solar y el relieve de olas
look -30 25
sleep 1
screenshot agua-giro-n30

look -15 25
sleep 1
screenshot agua-giro-n15

look 0 25
sleep 1
screenshot agua-giro-00

look 15 25
sleep 1
screenshot agua-giro-15

look 30 25
sleep 1
screenshot agua-giro-30

# 3. Cruzar la superficie del agua de 1 en 1 bloque (Y = 65 -> 64 -> 63 -> 62 -> 61)
command tp @s 150.5 65 228.5
look 0 35
sleep 1
screenshot agua-cruce-y65

command tp @s 150.5 64 228.5
look 0 35
sleep 1
screenshot agua-cruce-y64

command tp @s 150.5 63 228.5
look 0 35
sleep 1
screenshot agua-cruce-y63

command tp @s 150.5 62 228.5
look 0 35
sleep 1
screenshot agua-cruce-y62

command tp @s 150.5 61 228.5
look 0 35
sleep 1
screenshot agua-cruce-y61
