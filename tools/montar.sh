#!/usr/bin/env bash
# Monta en build/vulpe/ la carpeta que Horizon acepta como pack: el manifiesto, README, LICENSE y solo los .wgsl y
# PNG que el manifiesto nombra (un .wgsl sin usar hace fallar el comprobador), como enlaces simbólicos por archivo:
# la recarga en caliente sigue viendo cada cambio. Porqué: docs/decisiones/0003-pack-montado-en-build.md
set -euo pipefail
raiz="$(cd "$(dirname "$0")/.." && pwd)"
destino="$raiz/build/vulpe"
mkdir -p "$destino"
# Las rutas entre comillas que acaban en .wgsl o .png de las líneas no comentadas del manifiesto.
lista="$( (printf '%s\n' horizon-shaders.toml README.md LICENSE
           grep -v '^[[:space:]]*#' "$raiz/horizon-shaders.toml" | grep -oE '"[^"]+\.(wgsl|png)"' | tr -d '"') | sort -u)"
# Sin borrar la carpeta (el juego la vigila mientras está abierto): se añade lo que falta y se quita lo que sobra.
while read -r f; do
    mkdir -p "$destino/$(dirname "$f")"
    [[ -L "$destino/$f" ]] || ln -sfn "$raiz/$f" "$destino/$f"
done <<<"$lista"
(cd "$destino" && find . -type l | sed 's|^\./||') | while read -r f; do
    grep -qxF "$f" <<<"$lista" || rm -f "$destino/$f"
done
find "$destino" -mindepth 1 -type d -empty -delete
echo "$destino"
