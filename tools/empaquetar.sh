#!/usr/bin/env bash
# Empaqueta el shader pack de Vulpe para Horizon como archivo .hshader.
# Uso: tools/empaquetar.sh
set -euo pipefail

raiz="$(cd "$(dirname "$0")/.." && pwd)"
herramienta="${HORIZON_SHADER:-$raiz/../trabajo/horizon-shader-build/target/release/horizon-shader}"

if [[ ! -x "$herramienta" ]]; then
    echo "Error: no se encontró el ejecutable de horizon-shader en: $herramienta" >&2
    exit 1
fi

echo "==> Montando el pack..."
pack="$("$raiz/tools/montar.sh")"

echo "==> Validando el pack..."
"$raiz/tools/validar.sh"

echo "==> Empaquetando pack en .hshader..."
dist="$raiz/dist"
mkdir -p "$dist"

# Limpieza de empaquetados previos en build
rm -f "$raiz/build"/*.hshader

# horizon-shader pack escribe <id>-<versión>.hshader junto a la carpeta indicada (en build/)
"$herramienta" pack "$pack"

# Mover el archivo resultante a dist/
mv "$raiz/build"/*.hshader "$dist/"

echo "==> Empaquetado completado en dist/:"
ls -lh "$dist"/*.hshader
