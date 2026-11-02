#!/usr/bin/env bash
# Valida el pack con el comprobador oficial de Horizon (naga, firmas, opciones, presupuestos,
# traducción a SPIR-V/Metal/HLSL). Uso: tools/validar.sh [--json]
set -euo pipefail
raiz="$(cd "$(dirname "$0")/.." && pwd)"
herramienta="${HORIZON_SHADER:-$raiz/../trabajo/horizon-shader-build/target/release/horizon-shader}"
pack="$("$raiz/tools/montar.sh")"
exec "$herramienta" check "$@" "$pack"
