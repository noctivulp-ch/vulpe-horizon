#!/usr/bin/env python3
"""Cobertura areal de los cúmulos de `vol_cobertura` (nucleo/volumen/capas.wgsl) frente a la tabla medida de fino/05 P6:
fracción del plano con nube (forma > 0,001), con nube densa (> 0,5) y forma media, para el parámetro de cobertura
0,5 / 1 / 1,5 / 1,9, sin erosión. Lee texturas/ruido2d.png (bilineal, repetida) como el shader.
Uso: tools/paridad/cobertura.py [--umbral A B] [--rampa R] [--exponente E]
"""
import argparse
from pathlib import Path
import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]
# fino/05 P6: capa -> {parámetro: (con nube, densa, media)}
ORIGINAL = {
    0: {0.5: (0.123, 0.000, 0.015), 1.0: (0.821, 0.124, 0.252), 1.5: (0.999, 0.696, 0.595), 1.9: (1.000, 0.962, 0.809)},
    1: {0.5: (0.054, 0.000, 0.007), 1.0: (0.740, 0.054, 0.182), 1.5: (0.999, 0.567, 0.528), 1.9: (1.000, 0.944, 0.755)},
}
ESCALA_ZONAS = 5000.0
ESCALA_FORMA = (900.0, 1800.0)


def muestra(tex, uv):
    h, w, _ = tex.shape
    x = uv[..., 0] * w - 0.5
    y = uv[..., 1] * h - 0.5
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int)
    fx = (x - x0)[..., None]; fy = (y - y0)[..., None]
    def t(a, b): return tex[b % h, a % w]
    return (t(x0, y0) * (1 - fx) + t(x0 + 1, y0) * fx) * (1 - fy) + (t(x0, y0 + 1) * (1 - fx) + t(x0 + 1, y0 + 1) * fx) * fy


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def cobertura(tex, xz, i, cob, umbral, rampa, exponente):
    zonas = muestra(tex, xz / ESCALA_ZONAS)[..., 2]
    m = muestra(tex, xz / ESCALA_FORMA[i] + i * 0.37)
    forma = m[..., 0] * 0.75 + m[..., 3] * 0.25
    u = (forma * 0.7 + zonas * 0.3 - 0.36) * 3.2
    um = umbral[0] - cob * umbral[1]
    return smoothstep(um, um + rampa, u) ** exponente


def estadistica(tex, i, cob, umbral, rampa, exponente):
    paso = (20.0, 40.0)[i]
    r = []
    for k in range(6):
        g = (np.arange(512) * paso)
        x, z = np.meshgrid(g + k * 13777.0, g - k * 9241.0)
        c = cobertura(tex, np.stack([x, z], -1), i, cob, umbral, rampa, exponente)
        r.append(((c > 0.001).mean(), (c > 0.5).mean(), c.mean()))
    return np.mean(r, axis=0)


def main():
    q = argparse.ArgumentParser()
    q.add_argument('--umbral', type=float, nargs=2, default=None)
    q.add_argument('--rampa', type=float, default=None)
    q.add_argument('--exponente', type=float, default=None)
    a = q.parse_args()
    import re
    src = (RAIZ / 'opciones/volumen.wgsl').read_text()
    m = re.search(r'OPC_NUBES_UMBRAL:[^=]*= vec2<f32>\(([-0-9.]+), ([-0-9.]+)\)', src)
    umbral = a.umbral or (float(m.group(1)), float(m.group(2)))
    rampa = a.rampa or float(re.search(r'OPC_NUBES_RAMPA:[^=]*= ([-0-9.]+)', src).group(1))
    m = re.search(r'OPC_NUBES_EXPONENTE:[^=]*= ([-0-9.]+)', src)
    exponente = a.exponente or (float(m.group(1)) if m else 0.5)
    tex = np.asarray(Image.open(RAIZ / 'texturas/ruido2d.png').convert('RGBA'), dtype=float) / 255
    print(f'umbral {umbral}, rampa {rampa}, exponente {exponente}')
    error = []
    for i in (0, 1):
        for cob, o in ORIGINAL[i].items():
            n = estadistica(tex, i, cob, umbral, rampa, exponente)
            error.append(np.abs(n - np.array(o)))
            print(f'capa {i} cob {cob}: con nube {n[0]:.3f} ({o[0]})  densa {n[1]:.3f} ({o[1]})  media {n[2]:.3f} ({o[2]})')
    print('error medio', np.round(np.mean(error, axis=0), 3))
    return float(np.mean(error))


if __name__ == '__main__':
    main()
