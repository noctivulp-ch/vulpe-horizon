# Vista de forma aislada (formas/README.md): pon OPC_DEPURACION_VISTA_DEFECTO en opciones/depuracion.wgsl (9..13) y
# lanza; mediodía despejado congelado, la cámara en (0, 100, 0).
close
command weather clear
command gamerule advance_time false
time 6000
command tp @s 0.5 100 0.5 0 0
sleep 12
screenshot forma-actual
