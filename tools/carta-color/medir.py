#!/usr/bin/env python3
"""Mide la carta de color (subsistemas/28) en las capturas del pack y la compara con la tabla del original.

Uso: tools/carta-color/medir.py [carpeta de capturas]  (por defecto pruebas/capturas)
Las capturas salen de pruebas/escenas/carta-color.ctl: carta-<hora del original>.png y cielo-<hora>.png (1830×1040).
Zonas (media sRGB de un cuadrado): cara de arriba, cara este, cara norte (sombra), cielo alto (35°, centro de la
captura del cielo) y cielo junto al horizonte. Imprime pack, original y diferencia, y la relación sombra/arriba.
"""
import sys, pathlib
from PIL import Image

TABLA = {  # hora del original: arriba, este, norte, cielo alto, horizonte (sRGB 0-255)
    22000: [(16,31,56),(5,15,28),(5,15,28),(69,89,120),(17,32,53)],
    22500: [(10,23,41),(3,9,18),(3,9,18),(63,83,114),(28,44,67)],
    23000: [(30,45,67),(11,22,36),(11,22,36),(46,62,88),(52,68,95)],
    23500: [(152,149,168),(160,109,106),(89,89,107),(127,128,152),(107,129,163)],
    0: [(129,146,180),(174,144,126),(61,81,118),(183,179,187),(161,167,187)],
    500: [(198,190,183),(245,234,191),(81,94,113),(201,195,189),(149,153,169)],
    1000: [(234,226,210),(251,245,220),(106,113,126),(199,198,199),(151,160,179)],
    1500: [(229,224,214),(232,224,200),(121,128,138),(194,196,204),(154,165,187)],
    2000: [(243,239,228),(247,242,225),(137,142,145),(157,174,196),(153,167,190)],
    3000: [(247,245,237),(244,240,226),(107,120,141),(93,140,185),(152,167,193)],
    6000: [(249,246,240),(98,112,136),(98,112,136),(95,142,188),(138,159,187)],
    9000: [(245,242,233),(104,116,135),(104,116,135),(146,171,199),(143,160,188)],
    11000: [(228,221,206),(116,120,126),(117,121,127),(252,250,243),(196,195,196)],
    11500: [(212,202,187),(111,113,116),(112,114,116),(251,247,238),(225,220,207)],
    12000: [(188,179,182),(99,103,119),(100,104,119),(254,253,239),(248,242,223)],
    12500: [(155,150,166),(92,89,105),(92,89,105),(178,158,159),(235,212,175)],
    13000: [(33,47,71),(13,24,38),(13,24,39),(29,42,62),(29,42,63)],
    13500: [(10,23,40),(3,8,17),(3,8,17),(11,22,37),(5,15,28)],
    14000: [(14,28,51),(4,12,24),(4,12,24),(16,28,44),(6,17,33)],
    15000: [(11,25,45),(3,10,20),(3,10,20),(14,23,33),(3,9,20)],
    18000: [(64,88,122),(31,48,73),(31,48,73),(11,24,43),(10,22,41)],
    21000: [(40,60,91),(17,31,51),(17,31,51),(71,90,122),(32,48,74)],
}
ZONAS = {"arriba": ("carta", 790, 550), "este": ("carta", 680, 660), "norte": ("carta", 820, 690),
         "cielo": ("cielo", 915, 520), "horizonte": ("carta", 250, 318)}
LADO = 16


def media(img, x, y):
    c = img.crop((x - LADO // 2, y - LADO // 2, x + LADO // 2, y + LADO // 2)).convert("RGB")
    px = list(c.getdata())
    return tuple(round(sum(p[i] for p in px) / len(px)) for i in range(3))


def luma(c):
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def main():
    d = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "pruebas/capturas")
    print("hora  | zona      | pack          | original      | dif")
    for hora, ref in TABLA.items():
        imgs = {}
        for k in ("carta", "cielo"):
            p = d / f"{k}-{hora:05d}.png"
            if p.exists():
                imgs[k] = Image.open(p)
        if not imgs:
            continue
        med = {}
        for (zona, (k, x, y)), r in zip(ZONAS.items(), ref):
            if k not in imgs:
                continue
            m = media(imgs[k], x, y)
            med[zona] = m
            dif = tuple(a - b for a, b in zip(m, r))
            print(f"{hora:5d} | {zona:9s} | {str(m):13s} | {str(r):13s} | {dif}")
        if "arriba" in med and "norte" in med:
            print(f"      | sombra/arriba pack {luma(med['norte']) / max(luma(med['arriba']), 1):.2f}  original "
                  f"{luma(ref[2]) / max(luma(ref[0]), 1):.2f}")


if __name__ == "__main__":
    main()
