# Forma del agua (formas/agua.md §6): con OPC_DEPURACION_VISTA_DEFECTO = 14 la normal en color; mar de (125, 245),
# desde 20 bloques mirando abajo y rasante. Mediodía congelado.
close
command weather clear
command gamerule advance_time false
time 6000
command tp @s 125.5 83 245.5 0 90
sleep 8
screenshot forma-agua-abajo
command tp @s 125.5 66 245.5 0 8
sleep 3
screenshot forma-agua-rasante
