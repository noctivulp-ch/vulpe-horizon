# Cielo fractal (subsistema 02): cenit y dos alturas de noche con campo de visión amplio, y su aparición en
# el crepúsculo. Deja el campo de visión como estaba (70).
close
command tp @s 170.5 77 166.5
command weather clear
options-set fov 110
time 18000
look 0 -90
sleep 3
screenshot fractal-cenit
look 120 -30
sleep 1
screenshot fractal-norte
look -60 -30
sleep 1
screenshot fractal-este
time 13600
look 0 -90
sleep 2
screenshot fractal-crepusculo
options-set fov 70
