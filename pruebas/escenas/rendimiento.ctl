# Rendimiento (B-23 lote 2): solo carga el mundo; las medidas las hace tools/rendimiento/medir.sh con horizon-ctl bench.
close
command gamemode spectator
command weather clear
command gamerule advance_time false
command time set 6000
command tp @s 170.5 90 166.5 0 10
sleep 10
