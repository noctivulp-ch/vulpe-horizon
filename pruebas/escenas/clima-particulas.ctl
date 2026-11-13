# Clima con partículas del mod (26, etapa 1): lluvia y tormenta en el bosque de (150, 198) del mundo de la instancia
# vulpe-pruebas, mediodía congelado, mirando horizontal. Necesita esa instancia (HORIZON_HOME y HORIZON_CTL de su versión).
close
command gamerule advance_time false
time 6000
command weather clear
command tp @s 150.5 75 198.5 -150 10
sleep 10
screenshot clima-sin
command weather rain
sleep 8
screenshot clima-lluvia
command weather thunder
sleep 6
screenshot clima-tormenta
