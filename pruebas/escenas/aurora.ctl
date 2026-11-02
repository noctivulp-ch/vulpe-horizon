# Aurora (subsistema 06): de noche con la niebla, mirando hacia la figura de la semilla por defecto (al sur)
# a dos alturas, al cenit, y al norte sin figura. Campo de visión 110.
close
tp 170.5 77 166.5
command weather clear
options-set fov 110
time 18000
look 0 -15
sleep 4
screenshot aurora-sur
look 0 -45
sleep 1
screenshot aurora-sur-alto
look 0 -89
sleep 1
screenshot aurora-cenit
look 180 -20
sleep 1
screenshot aurora-norte
options-set fov 70
