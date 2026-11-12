# Formato 2 del mod (bioma en mods[1].w): pantano en (1501, 3189), mediodía despejado; captura al llegar y a los 6 s
# (el peso sube en 4 s), y la vista de depuración del mod no se usa (lee solo el formato 1). Necesita el cliente nativo.
close
command weather clear
command gamerule advance_time false
time 6000
command tp @s 1501.5 75 3189.5 0 5
sleep 1
screenshot bioma-pantano-1s
sleep 6
screenshot bioma-pantano-7s
command tp @s 1501.5 75 3600.5 0 5
sleep 8
screenshot bioma-fuera
