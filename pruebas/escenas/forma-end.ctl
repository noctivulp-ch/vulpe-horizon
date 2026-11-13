# Tormenta del End (observación del dueño 6.2): con OPC_DEPURACION_VISTA_DEFECTO = 15 (planta a Y 60) o 16 (corte por
# z = 0) la densidad aislada; con 0, desde (60, 75, 0) mirando a la isla, y desde (250, 90, 0) hacia fuera.
close
command execute in minecraft:the_end run tp @s 60.5 75 0.5 90 10
sleep 12
screenshot forma-end
command execute in minecraft:the_end run tp @s 250.5 90 0.5 -90 5
sleep 6
screenshot forma-end-fuera
command execute in minecraft:overworld run tp @s 150.5 80 230.5 -150 25
