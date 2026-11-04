#!/usr/bin/env python3
"""Réplica en numpy del PCF de `luz_sombra` (nucleo/luz/sombras.wgsl) sobre el borde recto de paridad/04 §(b): un
voladizo a altura h que cubre x < 0, sol en el cenit. Mide la anchura de la penumbra 10–90 % en bloques con 16 giros
promediados (el TAA), y la compara con la del original. Uso: tools/paridad/penumbra.py [--min M] [--k K] [--tpb T]
"""
import argparse
import math
import numpy as np

ORIGINAL = {0.5: 0.075, 1: 0.1, 2: 0.125, 4: 0.2, 8: 0.325, 16: 0.5}


def vogel(i, n, giro):
    r = math.sqrt((i + 0.5) / n)
    a = i * 2.39996323 + giro
    return r * math.cos(a), r * math.sin(a)


def sombra(x, radio_bloques, tpb, muestras=8):
    total = 0.0
    for g in range(16):
        giro = (g + 0.5) / 16 * 2 * math.pi
        luz = 0.0
        for i in range(muestras):
            dx, _ = vogel(i, muestras, giro)
            px = x + dx * radio_bloques
            # comparación bilineal 2×2: el borde del mapa queda repartido en un texel
            t = px * tpb
            luz += min(max(t + 0.5, 0.0), 1.0)
        total += luz / muestras
    return total / 16


def anchura(radio_bloques, tpb):
    xs = np.linspace(-1.5, 1.5, 3001)
    s = np.array([sombra(x, radio_bloques, tpb) for x in xs])
    return xs[np.argmax(s >= 0.9)] - xs[np.argmax(s >= 0.1)]


def main():
    q = argparse.ArgumentParser()
    q.add_argument('--min', type=float, default=0.051)
    q.add_argument('--k', type=float, default=0.0197)
    q.add_argument('--tpb', type=float, nargs='+', default=[53.0, 15.0])
    q.add_argument('--max-texeles', type=float, default=30.0)
    a = q.parse_args()
    for tpb in a.tpb:
        print(f'{tpb} texels por bloque: h  nuestra  original')
        for h, w in ORIGINAL.items():
            radio = min(max((a.min + h * a.k) * tpb, 1.0), a.max_texeles) / tpb
            print(f'  {h:4}  {anchura(radio, tpb):.3f}  {w}')


if __name__ == '__main__':
    main()
