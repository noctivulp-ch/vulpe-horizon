#!/usr/bin/env python3
"""Atlas 3D con margen: texturas/ruido3d_borde.png a partir de texturas/ruido3d.png.

Por qué existe (B-23 lote 2, F-66): `vol_ruido3d` leía 8 téxeles a mano (trilineal con textureLoad) para que el
atlas de 32 cortes de 32×32 repitiera sin sangrar entre cortes. Con un téxel de margen por corte (el borde
opuesto del mismo corte), el filtrado bilineal del hardware hace el xy y solo quedan 2 lecturas (dos cortes) y una
mezcla en z. Los valores son los mismos téxeles: no se vuelve a generar el ruido. Ver docs/rendimiento.md.

Uso: python3 -I tools/ruido/margen3d.py   (Pillow, numpy)
"""
from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]


def main():
    a = np.asarray(Image.open(RAIZ / "texturas" / "ruido3d.png").convert("RGBA"))
    n = a.shape[0]
    cortes = a.shape[1] // n
    salida = np.zeros((n + 2, (n + 2) * cortes, 4), dtype=np.uint8)
    for z in range(cortes):
        c = a[:, z * n:(z + 1) * n]
        c = np.pad(c, ((1, 1), (1, 1), (0, 0)), mode="wrap")
        salida[:, z * (n + 2):(z + 1) * (n + 2)] = c
    Image.fromarray(salida, "RGBA").save(RAIZ / "texturas" / "ruido3d_borde.png")
    print("escrito texturas/ruido3d_borde.png", salida.shape)


if __name__ == "__main__":
    main()
