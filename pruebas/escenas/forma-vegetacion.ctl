# Forma del movimiento de la vegetación (formas/vegetacion.md §5): prado de (413, 277), cámara a 10 bloques mirando
# abajo, mediodía con la hora corriendo (frame.time sigue al reloj del mundo); dos capturas a 0,4 s para ver la diferencia (frentes de ola).
close
command weather clear
command gamerule advance_time true
time 6000
command fill 403 66 267 423 66 287 minecraft:grass_block
command fill 403 67 267 423 67 287 minecraft:short_grass
command tp @s 413.5 77 277.5 0 70
sleep 10
screenshot vegetacion-a
sleep 0.4
screenshot vegetacion-b
