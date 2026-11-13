"""Luma de la piedra y la arena de la plataforma de noche-suelo en la escena ocaso-noche (B-23 §1: sin escalones).

Uso: python3 -I tools/noche/ocaso.py pruebas/capturas
"""
import sys
from pathlib import Path
from PIL import Image

HORAS = (12000, 12500, 12800, 13100, 13500, 14000, 15000, 16500, 18000)


def luma(im, cx, cy, r=0.025):
    w, h = im.size
    px = list(im.crop((int((cx - r) * w), int((cy - r) * h), int((cx + r) * w), int((cy + r) * h))).getdata())
    rgb = [sum(p[i] for p in px) / len(px) for i in range(3)]
    return round(0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2], 1)


d = Path(sys.argv[1] if len(sys.argv) > 1 else "pruebas/capturas")
for t in HORAS:
    f = d / f"ocaso-noche-{t}.png"
    if f.exists():
        im = Image.open(f).convert("RGB")
        print(t, "arena", luma(im, 0.5, 0.53), "piedra", luma(im, 0.5, 0.85), "pasto", luma(im, 0.33, 0.53))
