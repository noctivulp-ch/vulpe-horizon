# Absorción por canal bajo el agua (07.1): lana roja y blanca a 2, 5 y 10 bloques de la cámara, dentro del mar.
close
command weather clear
time 6000
command tp @s 125.5 56 245.5
sleep 4
command setblock 125 56 247 red_wool
sleep 1
command setblock 126 56 247 white_wool
sleep 1
command setblock 125 56 250 red_wool
sleep 1
command setblock 126 56 250 white_wool
sleep 1
command setblock 125 56 255 red_wool
sleep 1
command setblock 126 56 255 white_wool
sleep 1
command tp @s 125.5 56 245.5
look 0 0
sleep 5
screenshot agua-color
command setblock 125 56 247 water
command setblock 126 56 247 water
command setblock 125 56 250 water
command setblock 126 56 250 water
command setblock 125 56 255 water
command setblock 126 56 255 water
