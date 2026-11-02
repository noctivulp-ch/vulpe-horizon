#!/usr/bin/env python3
"""Genera las texturas de ruido en mosaico del pack (texturas/ruido2d.png y texturas/ruido3d.png).

Por qué existe: las nubes y la niebla en manchas evalúan ruido cientos de veces por píxel; leído de una
textura cuesta una lectura en vez de decenas de hashes. Ver docs/efectos/niebla-y-nubes.md §Ruido.

- ruido2d.png, 256×256 RGBA, repite en los dos ejes:
    R  fBm de ruido de gradiente, 4 octavas desde 4 celdas (dónde hay nubes: escala grande)
    G  fBm de gradiente, 4 octavas desde 16 celdas (forma de los cúmulos)
    B  fBm de gradiente deformado, 3 octavas desde 2 celdas (altoestratos)
    A  ruido de Worley invertido de 8 celdas (detalle)
- ruido3d.png, atlas de 32 cortes de 32×32 en fila (1024×32) de un volumen 32³ que repite en los tres ejes:
    R  Perlin-Worley (gradiente remapeado por Worley), 4 celdas
    G  Worley invertido, 8 celdas
    B  Worley invertido, 16 celdas
    A  fBm de gradiente, 3 octavas desde 4 celdas (niebla en manchas)
Técnica de la combinación Perlin-Worley: Schneider y Vos, SIGGRAPH 2015.

Uso: tools/ruido/generar_ruido.py  (numpy, Pillow). Determinista (semilla fija).
"""
from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]
RNG = np.random.default_rng(20261101)


def gradiente(n, celdas, dims):
    """Ruido de gradiente (Perlin) que repite cada `celdas`, muestreado en una rejilla de n por eje."""
    ang = RNG.normal(size=(celdas,) * dims + (dims,))
    ang /= np.linalg.norm(ang, axis=-1, keepdims=True)
    coords = np.meshgrid(*[np.arange(n) / n * celdas] * dims, indexing="ij")
    p = np.stack(coords, -1)
    i0 = np.floor(p).astype(int)
    f = p - i0
    u = f * f * f * (f * (f * 6 - 15) + 10)
    total = 0.0
    for esquina in range(2 ** dims):
        o = np.array([(esquina >> k) & 1 for k in range(dims)])
        idx = tuple(((i0 + o) % celdas)[..., k] for k in range(dims))
        g = ang[idx]
        d = f - o
        w = np.prod(np.where(o == 1, u, 1 - u), axis=-1)
        total = total + w * np.sum(g * d, -1)
    return total


def fbm(n, celdas, dims, octavas):
    s = 0.0
    amp = 1.0
    tot = 0.0
    for o in range(octavas):
        s = s + amp * gradiente(n, celdas * 2 ** o, dims)
        tot += amp
        amp *= 0.5
    v = s / tot
    return np.clip(v * 0.9 + 0.5, 0, 1)


def worley(n, celdas, dims):
    """Distancia al punto más cercano (normalizada), que repite cada `celdas`."""
    puntos = RNG.random((celdas,) * dims + (dims,))
    coords = np.meshgrid(*[np.arange(n) / n * celdas] * dims, indexing="ij")
    p = np.stack(coords, -1)
    i0 = np.floor(p).astype(int)
    mejor = np.full(p.shape[:-1], 9.0)
    for desp in np.ndindex(*(3,) * dims):
        o = np.array(desp) - 1
        celda = i0 + o
        idx = tuple((celda % celdas)[..., k] for k in range(dims))
        q = celda + puntos[idx]
        mejor = np.minimum(mejor, np.linalg.norm(p - q, axis=-1))
    return np.clip(1.0 - mejor / 0.9, 0, 1)


def a8(x):
    return np.clip(np.round(x * 255), 0, 255).astype(np.uint8)


def main():
    salida = RAIZ / "texturas"
    salida.mkdir(exist_ok=True)
    n = 256
    r = fbm(n, 4, 2, 4)
    g = fbm(n, 16, 2, 4)
    b = fbm(n, 2, 2, 3)
    a = worley(n, 8, 2)
    Image.fromarray(np.stack([a8(r), a8(g), a8(b), a8(a)], -1), "RGBA").save(salida / "ruido2d.png")

    m = 32
    perlin = fbm(m, 4, 3, 3)
    w4 = worley(m, 4, 3)
    pw = np.clip((perlin - (1 - w4)) / max(1e-3, 1.0) * 0.5 + 0.5 * perlin + 0.25 * w4, 0, 1)
    w8 = worley(m, 8, 3)
    w16 = worley(m, 16, 3)
    niebla = fbm(m, 4, 3, 3)
    vol = np.stack([a8(pw), a8(w8), a8(w16), a8(niebla)], -1)   # (x, y, z, 4)
    # Atlas: el corte z va en la columna de tiles z; dentro del tile, x a lo ancho e y a lo alto.
    atlas = np.concatenate([vol[:, :, z, :].transpose(1, 0, 2) for z in range(m)], axis=1)
    Image.fromarray(atlas, "RGBA").save(salida / "ruido3d.png")
    print("escritos texturas/ruido2d.png y texturas/ruido3d.png")


if __name__ == "__main__":
    main()
