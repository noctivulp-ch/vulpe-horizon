# Aurora en las condiciones de captura de referencias/ruidov_noche.png (dato del gestor): hora 14000, mirando al sur
# (yaw 0) y al horizonte (pitch 0), campo de visión 110; y dos vistas más altas.
close
command weather clear
command tp @s 170.5 77 166.5
sleep 3
options-set fov 110
time 14000
look 0 0
sleep 10
screenshot aurora-14000-horizonte
look 0 -40
sleep 2
screenshot aurora-14000-40
look 0 -55
sleep 2
screenshot aurora-14000-55
options-set fov 70
