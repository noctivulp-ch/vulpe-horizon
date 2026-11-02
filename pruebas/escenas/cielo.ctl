# Cielo y atmósfera (subsistema 01): mediodía, atardecer hacia el oeste y hacia el este, crepúsculo,
# noche con la luna, mirada hacia abajo desde lo alto, y lluvia.
close
command tp @s 170.5 77 166.5
command weather clear
sleep 3
time 6000
look 0 -20
sleep 2
screenshot cielo-mediodia
look 90 -60
sleep 1
screenshot cielo-mediodia-sol
time 12000
look 90 -8
sleep 2
screenshot cielo-atardecer-oeste
look -90 -8
sleep 1
screenshot cielo-atardecer-este
time 13000
look 90 -8
sleep 2
screenshot cielo-crepusculo
time 18000
look 0 -60
sleep 2
screenshot cielo-noche
look 90 -10
sleep 1
screenshot cielo-noche-horizonte
time 6000
command tp @s 170.5 250 166.5
look 0 30
sleep 0.5
screenshot cielo-alto-abajo
command tp @s 170.5 77 166.5
command weather rain
sleep 6
look 0 -10
screenshot cielo-lluvia
command weather clear
