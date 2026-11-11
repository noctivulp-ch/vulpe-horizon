# Destello del sol a mediodía (B-19): desde un sitio despejado, mirando al sol (cenit en Horizon) y a 35°, 55° y 70° de él,
# para comparar la aureola con la del panel cielo-dia del original (allí el sol está en el centro, a 55° de elevación).
close
command weather clear
time 6000
command tp @s 200.5 110 150.5 0 -90
sleep 8
screenshot destello-sol-00
look 0 -55
sleep 2
screenshot destello-sol-35
look 0 -35
sleep 2
screenshot destello-sol-55
