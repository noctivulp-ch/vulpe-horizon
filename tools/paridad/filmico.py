#!/usr/bin/env python3
"""Compara nuestro fílmico (Hejl 2015 con punto blanco W, `col_tonemap_filmico` en nucleo/color/tonemap.wgsl) con la tabla
del fílmico por defecto del original (paridad/11 §(b), gris): entrada lineal ya expuesta → salida sRGB.
Uso: tools/paridad/filmico.py [--blanco W]
"""
import argparse
import numpy as np

ENTRADA = [0.005, 0.01, 0.02, 0.05, 0.1, 0.18, 0.25, 0.35, 0.5, 0.7, 1, 1.5, 2, 3, 4]
ORIGINAL = [0.01028, 0.03635, 0.09878, 0.2379, 0.3905, 0.5398, 0.6234, 0.7038, 0.7799, 0.841, 0.8938, 0.9401, 0.9652,
            0.9917, 1]


def hejl(x):
    a = 1.425 * x + 0.05
    return (x * a + 0.004) / (x * (a + 0.55) + 0.0491) - 0.0821


def srgb(l):
    l = np.clip(l, 0, 1)
    return np.where(l <= 0.0031308, 12.92 * l, 1.055 * l ** (1 / 2.4) - 0.055)


def main():
    q = argparse.ArgumentParser()
    q.add_argument('--blanco', type=float, default=3.1)
    a = q.parse_args()
    x = np.array(ENTRADA)
    nuestra = srgb(hejl(x) / hejl(a.blanco))
    for e, n, o in zip(ENTRADA, nuestra, ORIGINAL):
        print(f'{e:6}  {n:.4f}  original {o}')
    print('error máximo', round(float(np.abs(nuestra - np.array(ORIGINAL)).max()), 4))


if __name__ == '__main__':
    main()
