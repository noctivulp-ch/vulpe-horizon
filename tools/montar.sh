#!/usr/bin/env bash
# Monta en build/vulpe/ la carpeta que Horizon acepta como pack: solo el manifiesto, el README y
# las carpetas de WGSL, como enlaces simbólicos (la recarga en caliente sigue viendo cada cambio).
# Porqué: docs/decisiones/0003-pack-montado-en-build.md
set -euo pipefail
raiz="$(cd "$(dirname "$0")/.." && pwd)"
destino="$raiz/build/vulpe"
mkdir -p "$destino"
for f in horizon-shaders.toml README.md LICENSE nucleo adaptadores opciones etapas texturas; do
    ln -sfn "../../$f" "$destino/$f"
done
echo "$destino"
