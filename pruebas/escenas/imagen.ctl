# Exposición, tonemap, gradación y bloom (subsistemas 10 y 11): día, atardecer al sol (bloom) y noche.
# Pendiente: una escena de cueva (el tp bajo tierra devuelve a la superficie).
close
tp 170.5 77 166.5
command weather clear
time 6000
look 0 15
sleep 6
screenshot imagen-dia
time 12300
look 90 -5
sleep 6
screenshot imagen-atardecer
time 18000
look 0 -15
sleep 8
screenshot imagen-noche
