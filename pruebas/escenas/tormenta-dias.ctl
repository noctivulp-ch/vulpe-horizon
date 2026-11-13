# Tormentas por día (B-23 §8): desierto de (-9872, -2200), lluvia puesta, mediodía, seis días seguidos.
close
command gamemode spectator
command gamerule advance_time false
command weather clear
command time set 6000
command tp @s -9871.5 90 -2199.5 0 5
sleep 14
command weather rain
sleep 10
screenshot tormenta-dia-0
command time add 24000
sleep 10
screenshot tormenta-dia-1
command time add 24000
sleep 10
screenshot tormenta-dia-2
command time add 24000
sleep 10
screenshot tormenta-dia-3
command time add 24000
sleep 10
screenshot tormenta-dia-4
command time add 24000
sleep 10
screenshot tormenta-dia-5
command time add 24000
command weather clear
command time set 6000
