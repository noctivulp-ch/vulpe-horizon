# Recorrido del suelo en bioma nevado (N-02): llanura nevada en (-499, ~70, -761).
# Compara despejado vs nieve: escarcha sutil (aclarado frío y motas cristalinas en rejilla de 32),
# sin charcos ni oscurecimiento. Acercamiento 16/8/4/2/1 bloques, giro en pasos de 20° y cruce de 1 en 1.
close
command gamemode spectator
command gamerule advance_time false
command time set 6000
command weather clear
command tp @s -499.5 74 -761.5 0 45
sleep 8
screenshot suelo-nieve-despejado
command weather rain
sleep 9
# Acercamiento 16, 8, 4, 2 y 1 bloques sobre el suelo (~70)
command tp @s -499.5 86 -761.5 0 55
sleep 1
screenshot suelo-nieve-d16
command tp @s -499.5 78 -761.5 0 50
sleep 1
screenshot suelo-nieve-d08
command tp @s -499.5 74 -761.5 0 45
sleep 1
screenshot suelo-nieve-d04
command tp @s -499.5 72 -761.5 0 45
sleep 1
screenshot suelo-nieve-d02
command tp @s -499.5 71.2 -761.5 0 40
sleep 1
screenshot suelo-nieve-d01
# Giro de cámara en pasos de 20° para juzgar los destellos especulares en movimiento
command tp @s -499.5 72 -761.5 20 45
sleep 1
screenshot suelo-nieve-giro-20
command tp @s -499.5 72 -761.5 40 45
sleep 1
screenshot suelo-nieve-giro-40
command tp @s -499.5 72 -761.5 60 45
sleep 1
screenshot suelo-nieve-giro-60
# Cruce de la superficie de 1 en 1 bloque
command tp @s -498.5 72 -761.5 0 45
sleep 1
screenshot suelo-nieve-paso-1
command tp @s -497.5 72 -761.5 0 45
sleep 1
screenshot suelo-nieve-paso-2
command weather clear
sleep 3
screenshot suelo-nieve-fundido
sleep 5
