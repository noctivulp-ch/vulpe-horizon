#!/usr/bin/env bash
# Valida, abre Horizon con el pack, recorre una escena y guarda sus capturas.
# Uso: tools/probar.sh ESCENA [--dejar-abierto]
#   ESCENA: nombre de pruebas/escenas/<nombre>.ctl (una orden de horizon-ctl por línea; `#` comenta;
#   `screenshot NOMBRE` guarda en pruebas/capturas/NOMBRE.png).
# Si ya hay un Horizon abierto se reutiliza (la recarga en caliente ya tiene el pack al día) solo si
# lo abrió este script; si no, se aborta para no pisar la partida de nadie.
set -euo pipefail
raiz="$(cd "$(dirname "$0")/.." && pwd)"
ctl="${HORIZON_CTL:-$HOME/.local/share/horizon-launcher/versions/nightly-2026-11-01-c9d474d/horizon-ctl}"
escena="${1:?uso: tools/probar.sh ESCENA [--dejar-abierto]}"
dejar="${2:-}"
guion="$raiz/pruebas/escenas/$escena.ctl"
capturas="$raiz/pruebas/capturas"
marca="$raiz/build/.juego-propio"
[[ -f "$guion" ]] || { echo "no existe $guion" >&2; exit 2; }
mkdir -p "$capturas"

"$raiz/tools/validar.sh"
pack="$raiz/build/vulpe"

if pgrep -x horizon-client >/dev/null; then
    if [[ ! -f "$marca" ]]; then
        echo "Hay un Horizon abierto que no abrió este script; ciérralo antes (horizon-ctl quit)." >&2
        exit 3
    fi
    echo "Reutilizo el Horizon abierto (recarga en caliente)."
else
    HORIZON_SHADER_PACK="$pack" "$ctl" launch --world VulpePrueba --seed 1 --creative --wait
    touch "$marca"
fi

while IFS= read -r linea || [[ -n "$linea" ]]; do
    linea="${linea%%#*}"
    read -r -a args <<<"$linea"
    (( ${#args[@]} )) || continue
    if [[ "${args[0]}" == screenshot ]]; then
        args[1]="$capturas/${args[1]}.png"
    fi
    echo "> ${args[*]}"
    "$ctl" "${args[@]}"
done <"$guion"

"$ctl" logs | grep -iE 'shader|error|warn' | tail -n 20 || true

if [[ "$dejar" != --dejar-abierto ]]; then
    "$ctl" quit || true
    rm -f "$marca"
fi
