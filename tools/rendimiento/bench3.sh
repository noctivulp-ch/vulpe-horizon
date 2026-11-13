#!/usr/bin/env bash
# Mide 10 s en Overworld, Nether y End en vistas fijas, con el foco en la ventana de Horizon (niri). Uso: bench3.sh ETIQUETA
# bench3.sh <etiqueta>: mide 10 s en Overworld, Nether y End (vistas fijas), con el foco; imprime fps y GPU ms
C=$HOME/.local/share/horizon-launcher/versions/native-fdc87ae-4cd701a43bfe/horizon-ctl
export HORIZON_HOME=$HOME/.local/share/horizon/instances/vulpe-pruebas
id=$(niri msg -j windows | python3 -c "import json,sys;print([w['id'] for w in json.load(sys.stdin) if w.get('app_id')=='horizon'][0])")
medir() { for intento in 1 2 3; do niri msg action focus-window --id $id; sleep 2; r=$($C bench 10 | python3 -c "import json,sys;d=json.load(sys.stdin);print('$1 $2', 'fps %.1f'%d['avg_fps'], 'gpu %.2f ms'%d['gpu']['avg_ms'], 'cpu %.2f ms'%d['cpu']['avg_ms'])"); case "$r" in *"fps 10."*|*"fps 9."*) continue;; esac; break; done; echo "$r"; }
$C command "execute in minecraft:overworld run tp @s 170.5 90 166.5 0 10" >/dev/null; sleep 8; $C look 0 10 >/dev/null; sleep 2; medir "$1" overworld
$C command "execute in minecraft:the_nether run tp @s 0.5 100 0.5 0 20" >/dev/null; sleep 12; $C look 0 20 >/dev/null; sleep 2; medir "$1" nether
$C command "execute in minecraft:the_end run tp @s 0.5 90 120.5 180 -10" >/dev/null; sleep 12; $C look 180 -10 >/dev/null; sleep 2; medir "$1" end
$C command "execute in minecraft:overworld run tp @s 170.5 90 166.5 0 10" >/dev/null
