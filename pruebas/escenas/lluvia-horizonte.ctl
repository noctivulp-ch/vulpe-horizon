# Capa blanquecina en el horizonte con lluvia (observación del dueño 1.3): mediodía, mirando horizontal al terreno
# lejano; sin lluvia y a 2, 5 y 10 s de empezar a llover (la niebla de lluvia aún tenue). Hora congelada.
close
command gamerule advance_time false
time 6000
command weather clear
command tp @s 150.5 85 230.5 -150 0
sleep 12
screenshot lluvia-horizonte-sin
command weather rain
sleep 2
screenshot lluvia-horizonte-02
sleep 3
screenshot lluvia-horizonte-05
sleep 5
screenshot lluvia-horizonte-10
command weather clear
