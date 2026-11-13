"""Saturación (HSV) y matiz de la fila de hormigón de aislamiento-colores.ctl, con y sin aislamiento.

Uso: python3 -I tools/aislamiento/medir.py <captura_sin> <captura_con>
"""
import colorsys
import sys
from PIL import Image

# Centros de cada parche en fracción de la imagen (cámara mirando al sur: el este a la izquierda).
ZONAS = {"marron": 0.285, "azul": 0.365, "lima": 0.445, "amarillo": 0.53, "naranja": 0.61, "rojo": 0.69}
FILA_Y = 0.535


def hsv(im, cx, cy, r=0.012):
    w, h = im.size
    px = list(im.crop((int((cx - r) * w), int((cy - r) * h), int((cx + r) * w), int((cy + r) * h))).getdata())
    rgb = [sum(p[i] for p in px) / len(px) / 255 for i in range(3)]
    hh, s, v = colorsys.rgb_to_hsv(*rgb)
    return round(hh * 360), round(s, 3), round(v, 3)


a = Image.open(sys.argv[1]).convert("RGB")
b = Image.open(sys.argv[2]).convert("RGB")
for z, x in ZONAS.items():
    ha, sa, va = hsv(a, x, FILA_Y)
    hb, sb, vb = hsv(b, x, FILA_Y)
    print(f"{z:9} sin: matiz {ha:3} sat {sa:.3f} | con: matiz {hb:3} sat {sb:.3f} | sat con/sin {sb / max(sa, 1e-3):.2f}")
