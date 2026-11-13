# Reflejos de nubes y niebla en el agua (observación del dueño 4.1): mar de (125, 245) a mediodía, desde 3 bloques
# sobre el agua mirando al horizonte y 25° abajo. Para tener nubes, poner a mano TIEMPO_ALEATORIO = false.
close
command weather clear
command gamerule advance_time false
time 4000
command tp @s 125.5 66 245.5 0 3
sleep 10
screenshot agua-reflejo-horizonte
look 0 25
sleep 3
screenshot agua-reflejo-abajo
