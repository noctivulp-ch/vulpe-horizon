# Niebla local (21) en el mundo VulpePrueba (semilla 1): sabana (zona caliente) y llanura nevada con lluvia, jungla y
# pantano despejados; mediodía con la hora congelada. Sin el mod el día es 0: solo sale el primer perfil del sorteo.
close
command gamerule advance_time false
time 6000
command tp @s -1270 90 1574 0 5
command weather rain
sleep 12
screenshot niebla-local-sabana
command tp @s -502 90 -762 0 5
sleep 12
screenshot niebla-local-nieve
command weather clear
command tp @s 170 90 1766 0 5
sleep 12
screenshot niebla-local-jungla
command tp @s 1514 90 2886 0 5
sleep 12
screenshot niebla-local-pantano
