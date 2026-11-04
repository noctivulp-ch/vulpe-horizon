# Lluvia (paridad 16): de día mirando al horizonte y a 30° hacia abajo, para ver cuánto aclaran las gotas lo de detrás.
close
command weather rain
command tp @s 170.5 77 166.5 0 0
time 6000
sleep 12
screenshot lluvia-aclarado-horizonte
look 0 30
sleep 3
screenshot lluvia-aclarado-suelo
command weather clear
