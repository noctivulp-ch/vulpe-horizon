# TAA (subsistema 09): nubes con la cámara quieta, terreno con sombras, noche con la aurora y girando.
close
tp 170.5 77 166.5
command weather clear
time 3000
look 0 -30
sleep 4
screenshot taa-nubes
time 6000
look 0 30
sleep 3
screenshot taa-sombras
options-set fov 110
time 18000
look 0 -15
sleep 4
screenshot taa-aurora
options-set fov 70
