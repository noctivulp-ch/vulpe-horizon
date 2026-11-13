# Tormentas en 10 niveles (B-23 §8): desierto y pradera, lluvia (niveles 1–5) y tormenta eléctrica (6–10), tres días cada una.
close
command gamemode spectator
command gamerule advance_time false
command time set 6000
command weather clear
command tp @s -9871.5 90 -2199.5 0 5
sleep 12
command weather rain
sleep 9
screenshot niveles-desierto-rain-0
command time add 24000
sleep 9
screenshot niveles-desierto-rain-1
command time add 24000
sleep 9
screenshot niveles-desierto-rain-2
command time add 24000
command weather thunder
sleep 9
screenshot niveles-desierto-thunder-0
command time add 24000
sleep 9
screenshot niveles-desierto-thunder-1
command time add 24000
sleep 9
screenshot niveles-desierto-thunder-2
command time add 24000
command weather clear
command tp @s 170.5 90 166.5 0 5
sleep 12
command weather rain
sleep 9
screenshot niveles-pradera-rain-0
command time add 24000
sleep 9
screenshot niveles-pradera-rain-1
command time add 24000
sleep 9
screenshot niveles-pradera-rain-2
command time add 24000
command weather thunder
sleep 9
screenshot niveles-pradera-thunder-0
command time add 24000
sleep 9
screenshot niveles-pradera-thunder-1
command time add 24000
sleep 9
screenshot niveles-pradera-thunder-2
command time add 24000
command weather clear
command time set 6000
