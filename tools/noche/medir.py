"""Mide la escena pruebas/escenas/noche-suelo.ctl: luma media (0-255) y RGB de la arena, el pasto y la piedra.

Uso: python3 -I tools/noche/medir.py pruebas/capturas
Zonas en fracción de la imagen (cámara a 5 bloques mirando 40° abajo hacia el sur: el este queda a la izquierda).
"""
import sys
from pathlib import Path
from PIL import Image

ZONAS = {"arena": (0.50, 0.53), "pasto": (0.33, 0.53), "piedra": (0.50, 0.85)}
CUEVA = {"pasto": (0.48, 0.80), "piedra": (0.50, 0.95), "pared": (0.50, 0.30)}


def media(im, cx, cy, r=0.025):
    w, h = im.size
    caja = (int((cx - r) * w), int((cy - r) * h), int((cx + r) * w), int((cy + r) * h))
    px = list(im.crop(caja).getdata())
    n = len(px)
    rgb = tuple(round(sum(p[i] for p in px) / n) for i in range(3))
    luma = round(0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2], 1)
    return rgb, luma


def main():
    d = Path(sys.argv[1] if len(sys.argv) > 1 else "pruebas/capturas")
    for n in ("llena", "cuarto", "nueva", "cueva"):
        f = d / f"noche-suelo-{n}.png"
        if not f.exists():
            continue
        im = Image.open(f).convert("RGB")
        zonas = CUEVA if n == "cueva" else ZONAS
        partes = [f"{z} {media(im, *c)[0]} L{media(im, *c)[1]}" for z, c in zonas.items()]
        print(f"{n:7} | " + " | ".join(partes))


if __name__ == "__main__":
    main()
