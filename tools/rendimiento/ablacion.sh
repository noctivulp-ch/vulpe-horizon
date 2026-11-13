#!/usr/bin/env bash
# Ablación por etapas (B-23 lote 2): mide con tools/rendimiento/bench3.sh cada bit de OPC_DEPURACION_QUITAR. Necesita
# Horizon abierto (tools/probar.sh rendimiento --dejar-abierto) con el foco; si sale a 10 fps, la medida no vale.
cd /media/sotano/Media/Documentos/ClaudeCode/Minecraft/Shaders/vulpe-horizon
S=${S:-build}
out=$S/ablacion.txt; : > $out
for b in 0 1 2 4 8 16 32 128 256 511; do
  sed -i "s/^const OPC_DEPURACION_QUITAR: u32 = [0-9]*u;/const OPC_DEPURACION_QUITAR: u32 = ${b}u;/" opciones/depuracion.wgsl
  tools/validar.sh >/dev/null 2>&1; sleep 16
  tools/rendimiento/bench3.sh "quitar=$b" >> $out 2>&1
done
sed -i "s/^const OPC_DEPURACION_QUITAR: u32 = [0-9]*u;/const OPC_DEPURACION_QUITAR: u32 = 0u;/" opciones/depuracion.wgsl; tools/validar.sh >/dev/null 2>&1
echo hecho >> $out
