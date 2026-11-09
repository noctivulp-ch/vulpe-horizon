# Recorrido de prueba para luz directa y halo solar a baja elevación (B-16.1)
# Atardecer (hora 12000) y amanecer (hora 300) girando en pasos de 15-30° y acercándose al bloque/suelo.
close
command weather clear
sleep 1

# Atardecer hacia el oeste (sol en el horizonte, elevación 0°)
time 12000
command tp @s 170.5 77 166.5
look 90 0
sleep 1
screenshot sol-bajo-atardecer-00

# Giro de cámara en pasos de 15° hacia el norte para evaluar atenuación del halo
look 75 0
sleep 0.5
screenshot sol-bajo-atardecer-g15
look 60 0
sleep 0.5
screenshot sol-bajo-atardecer-g30
look 45 0
sleep 0.5
screenshot sol-bajo-atardecer-g45

# Recorrido vertical mirando al suelo: no debe haber franja anaranjada de sol directo
look 90 15
sleep 0.5
screenshot sol-bajo-atardecer-suelo-15
look 90 30
sleep 0.5
screenshot sol-bajo-atardecer-suelo-30
look 90 60
sleep 0.5
screenshot sol-bajo-atardecer-suelo-60

# Amanecer hacia el este (hora 300, elevación solar ~4.5°)
time 300
look -90 -10
sleep 1
screenshot sol-bajo-amanecer-sol

# Giro de cámara en pasos de 15-30° alejándose del disco solar
look -75 -10
sleep 0.5
screenshot sol-bajo-amanecer-g15
look -60 -10
sleep 0.5
screenshot sol-bajo-amanecer-g30

# Acercamiento a la superficie de 16, 8, 4, 2 y 1 bloques para evaluar tinte cálido y sombra de follaje
command tp @s 170.5 77 150.5
look -90 15
sleep 0.5
screenshot sol-bajo-amanecer-d16
command tp @s 170.5 77 158.5
look -90 15
sleep 0.5
screenshot sol-bajo-amanecer-d08
command tp @s 170.5 77 162.5
look -90 15
sleep 0.5
screenshot sol-bajo-amanecer-d04
command tp @s 170.5 77 164.5
look -90 15
sleep 0.5
screenshot sol-bajo-amanecer-d02
command tp @s 170.5 77 165.5
look -90 15
sleep 0.5
screenshot sol-bajo-amanecer-d01
