#!/usr/bin/env python3
"""Compara la extinción por bloque de la perspectiva aérea (`vol_aire` en nucleo/volumen/medios.wgsl) con la tabla
de paridad/05 §«Perspectiva aérea: extinción del aire por bloque según la altura» (Y 62..662), y la fase del aire
(`atm_fase_elek` y `vol_fase_aire_mie`) con las columnas «aire Rayleigh» y «aire Mie» de la tabla de fases.
Lee las constantes VOL_AIRE_* del propio archivo WGSL. Uso: tools/paridad/aire.py
"""
import math
import re
from pathlib import Path

import numpy as np

RAIZ = Path(__file__).resolve().parents[2]
MEDIOS = RAIZ / "nucleo/volumen/medios.wgsl"
FASE = RAIZ / "nucleo/volumen/fase.wgsl"

# paridad/05: Y → (molecular R, G, B, aerosoles)
EXTINCION = {
    62: (0.000145, 0.0003375, 0.0008275, 7.8e-05), 112: (0.0001413, 0.0003288, 0.0008063, 6.427e-05),
    162: (0.0001377, 0.0003204, 0.0007856, 5.306e-05), 212: (0.0001341, 0.0003122, 0.0007654, 4.389e-05),
    262: (0.0001307, 0.0003042, 0.0007458, 3.641e-05), 312: (0.0001273, 0.0002964, 0.0007266, 3.029e-05),
    362: (0.0001241, 0.0002888, 0.000708, 2.53e-05), 412: (0.0001209, 0.0002814, 0.0006898, 2.122e-05),
    462: (0.0001178, 0.0002741, 0.0006721, 1.788e-05), 512: (0.0001148, 0.0002671, 0.0006549, 1.516e-05),
    562: (0.0001118, 0.0002602, 0.0006381, 1.293e-05), 612: (0.0001089, 0.0002536, 0.0006217, 1.111e-05),
    662: (0.0001061, 0.0002471, 0.0006058, 9.629e-06),
}
# paridad/05: ángulo → (aire Mie, aire Rayleigh)
FASES = {0: (12.5, 0.121), 10: (4.105, 0.1205), 20: (2.554, 0.119), 30: (1.703, 0.1167), 40: (1.168, 0.1135),
         50: (0.8166, 0.1096), 60: (0.581, 0.105), 70: (0.4211, 0.1), 80: (0.3113, 0.09465), 90: (0.2353, 0.08913),
         120: (0.1179, 0.07321), 150: (0.07643, 0.06156), 180: (0.06592, 0.0573)}


def constantes(texto, prefijo):
    out = {}
    for m in re.finditer(r"const (" + prefijo + r"\w+): (?:f32|vec3<f32>) = ([^;]+);", texto):
        v = [float(x) for x in re.findall(r"-?[0-9.]+(?:e-?[0-9]+)?", m.group(2).replace("vec3<f32>", ""))]
        out[m.group(1)] = v[0] if len(v) == 1 else np.array(v)
    return out


def hg(c, g):
    g2 = g * g
    den = max(1.0 + g2 - 2.0 * g * c, 1e-4)
    return (1.0 - g2) / (4.0 * math.pi * den * math.sqrt(den))


# fino/05 «Halo solar de la perspectiva aérea», Y = 62: ángulo → (R, G, B) dispersión del sol por bloque
HALO_62 = {0: (0.01241, 0.0127, 0.01344), 1: (0.006352, 0.006559, 0.007088), 2: (0.004682, 0.00486, 0.005312),
           4: (0.003076, 0.00322, 0.003585), 10: (0.001386, 0.001481, 0.001723), 30: (0.0002551, 0.0002933, 0.0003907),
           45: (8.985e-05, 0.0001108, 0.0001641), 60: (3.518e-05, 4.693e-05, 7.683e-05), 90: (7.358e-06, 1.139e-05, 2.167e-05),
           120: (2.336e-06, 3.998e-06, 8.229e-06), 180: (8.867e-07, 1.614e-06, 3.465e-06)}


def main():
    k = constantes(MEDIOS.read_text(), "VOL_AIRE_")
    print("extinción por bloque (nuestra / tabla):")
    err = []
    for y, (r, g, b, m) in EXTINCION.items():
        h = max(y - k["VOL_AIRE_Y0"], 0.0)
        ray = k["VOL_AIRE_RAYLEIGH"] * math.exp(-h / k["VOL_AIRE_ALTURA_RAYLEIGH"])
        mie = k["VOL_AIRE_MIE"] * math.exp(-h / k["VOL_AIRE_ALTURA_MIE"]) + k["VOL_AIRE_MIE_SUELO"]
        razones = [ray[0] / r, ray[1] / g, ray[2] / b, mie / m]
        err += [abs(math.log2(x)) for x in razones]
        print(f"  Y {y:4d}: molecular {ray.round(7)} tabla ({r}, {g}, {b})  ×{razones[0]:.3f} {razones[1]:.3f} {razones[2]:.3f}; "
              f"aerosoles {mie:.3e} tabla {m:.3e} ×{razones[3]:.3f}")
    print(f"  error medio {np.mean(err):.3f} EV, máximo {np.max(err):.3f} EV")

    # Fase de aerosoles del aire: los dos lóbulos de vol_fase_aire_mie, leídos del WGSL.
    texto = FASE.read_text()
    cuerpo = texto[texto.index("fn vol_fase_aire_mie"):]
    cuerpo = cuerpo[:cuerpo.index("}")]
    lobulos = re.findall(r"vol_hg\(c, ([0-9.]+)\) \* ([0-9.]+)", cuerpo)
    print("\nfase del aire (nuestra / tabla):")
    err = []
    for ang, (mie_t, ray_t) in FASES.items():
        c = math.cos(math.radians(ang))
        mie = sum(hg(c, float(g)) * float(w) for g, w in lobulos)
        ray = (2.8 + c) / (10.0 * math.pi)
        err += [abs(math.log2(mie / mie_t)), abs(math.log2(ray / ray_t))]
        print(f"  {ang:3d}°: Mie {mie:7.3f} tabla {mie_t:7.3f} ×{mie / mie_t:.2f}; Rayleigh {ray:.4f} tabla {ray_t:.4f} ×{ray / ray_t:.3f}")
    print(f"  error medio {np.mean(err):.3f} EV, máximo {np.max(err):.3f} EV")

    # Dispersión del sol por bloque a Y = 62: (σ_r·Elek + σ_m·Mie) × Mie, como en vol_tramo_niebla (F-5).
    print("\nhalo solar del aire a Y = 62 (nuestro / tabla):")
    err = []
    ray0 = k["VOL_AIRE_RAYLEIGH"]
    mie0 = k["VOL_AIRE_MIE"] + k["VOL_AIRE_MIE_SUELO"]
    for ang, tabla in HALO_62.items():
        c = math.cos(math.radians(ang))
        fm = sum(hg(c, float(g)) * float(w) for g, w in lobulos)
        fr = (2.8 + c) / (10.0 * math.pi)
        n = (ray0 * fr + mie0 * fm) * fm
        razon = n / np.array(tabla)
        err += [abs(math.log2(x)) for x in razon]
        print(f"  {ang:3d}°: {n.round(7)} tabla {tabla}  ×{razon.round(2)}")
    print(f"  error medio {np.mean(err):.3f} EV, máximo {np.max(err):.3f} EV")


if __name__ == "__main__":
    main()
