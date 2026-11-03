# Bloom de una fuente en la niebla de noche (observación del dueño: la dispersión salía «como palitos»): piedra luminosa
# al aire libre de noche, vista a 16, 8, 4, 2 y 1 bloques, y la luna saliendo por el este.
close
command weather clear
time 18000
command setblock 170 77 182 glowstone
sleep 1
command tp @s 170.5 77 166.5
look 0 0
sleep 8
screenshot bloom-niebla-16
command tp @s 170.5 77 174.5
sleep 4
screenshot bloom-niebla-08
command tp @s 170.5 77 178.5
sleep 4
screenshot bloom-niebla-04
command tp @s 170.5 77 180.5
sleep 4
screenshot bloom-niebla-02
command tp @s 170.5 77 181.3
sleep 4
screenshot bloom-niebla-01
command setblock 170 77 182 air
time 12950
command tp @s 170.5 120 166.5
look -90 -5
sleep 8
screenshot bloom-luna
# De día, para medir cuánto aclara el bloom la imagen entera (paridad 10: peso 0,45 en el centro).
time 6000
command tp @s 170.5 90 166.5
look 0 10
sleep 8
screenshot bloom-dia
