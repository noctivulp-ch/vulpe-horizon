#!/usr/bin/env python3
"""Compara el cielo dibujado de nuestro modelo atmosférico con las tablas de radiancia del original
(paridad/01 §(b): cenit, horizonte hacia el sol y opuesto, 10° opuesto, 30° a 90° del sol), por elevación del sol.

Reproduce lo que hace la etapa `sky` con el sol alto (sin cinturón de Venus ni luna): el modelo de
tools/atmosfera/generar_tabla.py con la fase molecular de Elek del núcleo (atm_fase_elek), el término de dispersión
múltiple que lee la tabla (0,5·(cielo + suelo)·ATM_MULTIPLE) y el color del sol de 6000 K (atm_cuerpo_negro).

Uso: tools/paridad/cielo.py [--elevaciones 0,2,10,30,55,90] [--bruma 1.0] [--g 0.6] [--mie 11.99e-6]
Imprime, por dirección y elevación, nuestro rgb, el del original y la razón de luminancias (nuestra / original).
"""
import argparse
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "atmosfera"))
import generar_tabla as gt  # noqa: E402

# paridad/01 §(b), cielo dibujado por elevación del sol: {elev: (cenit, horizonte_sol, horizonte_opuesto, venus10, lado30)}
ORIGINAL = {
    -2: [(0.001542, 0.002036, 0.002937), (0.02651, 0.01272, 0.006036), (0.002481, 0.003932, 0.005611), (0.003483, 0.003642, 0.005118), (0.002934, 0.00363, 0.004676)],
    0: [(0.005221, 0.006244, 0.008933), (0.1984, 0.05577, 0.01847), (0.02348, 0.01502, 0.01684), (0.01529, 0.01497, 0.0166), (0.009956, 0.01124, 0.0142)],
    2: [(0.008476, 0.01335, 0.01955), (0.3969, 0.1839, 0.05247), (0.04948, 0.0473, 0.03933), (0.02602, 0.036, 0.03974), (0.01613, 0.02425, 0.03154)],
    4: [(0.01049, 0.01978, 0.03578), (0.5019, 0.3087, 0.1268), (0.06501, 0.08011, 0.08041), (0.03245, 0.0552, 0.07798), (0.01986, 0.03597, 0.05863)],
    6: [(0.01173, 0.02438, 0.05283), (0.5289, 0.3809, 0.2107), (0.0742, 0.104, 0.1272), (0.03634, 0.06882, 0.1191), (0.02212, 0.04424, 0.08717)],
    10: [(0.01291, 0.02816, 0.06428), (0.4629, 0.3946, 0.2749), (0.08085, 0.1202, 0.1526), (0.03923, 0.07773, 0.1406), (0.02408, 0.0507, 0.1058)],
    15: [(0.01335, 0.02859, 0.0599), (0.3431, 0.3322, 0.2534), (0.08064, 0.1157, 0.1284), (0.03924, 0.07479, 0.1192), (0.02454, 0.05075, 0.09731)],
    20: [(0.01411, 0.03081, 0.068), (0.2688, 0.2957, 0.2656), (0.08466, 0.125, 0.1487), (0.04125, 0.08045, 0.1363), (0.0256, 0.0541, 0.1097)],
    30: [(0.01535, 0.03406, 0.07888), (0.204, 0.2621, 0.2788), (0.09159, 0.1386, 0.1759), (0.04482, 0.08917, 0.1595), (0.02715, 0.05855, 0.1254)],
    55: [(0.01801, 0.03936, 0.09363), (0.1619, 0.2348, 0.2856), (0.1069, 0.1641, 0.217), (0.05278, 0.1061, 0.1962), (0.02921, 0.06404, 0.1439)],
    90: [(0.04742, 0.06768, 0.122), (0.1331, 0.2013, 0.2606), (0.1331, 0.2013, 0.2606), (0.06548, 0.1296, 0.235), (0.03028, 0.06659, 0.1515)],
}
DIRECCIONES = ["cenit", "hor. sol 2°", "hor. opuesto 2°", "10° opuesto", "30° a 90°"]
LUMA = np.array([0.2126, 0.7152, 0.0722])


def srgb_a_lineal(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def cuerpo_negro(kelvin):
    """atm_cuerpo_negro (Tanner Helland 2012), normalizado a luminancia 1."""
    t = kelvin / 100.0
    if t <= 66:
        r = 255.0
        g = 99.4708025861 * math.log(t) - 161.1195681661
        b = 0.0 if t <= 19 else 138.5177312231 * math.log(t - 10.0) - 305.0447927307
    else:
        r = 329.698727446 * (t - 60.0) ** -0.1332047592
        g = 288.1221695283 * (t - 60.0) ** -0.0755148492
        b = 255.0
    lin = srgb_a_lineal(np.clip(np.array([r, g, b]) / 255.0, 0, 1))
    return lin / float(lin @ LUMA)


def fase_elek(c):
    return (2.8 + c) / (10.0 * math.pi)


def direcciones(sol_elev):
    """Las cinco direcciones de las tablas; el sol en el azimut +x."""
    def d(elev, azim):
        e, a = math.radians(elev), math.radians(azim)
        return [math.cos(e) * math.cos(a), math.sin(e), math.cos(e) * math.sin(a)]
    return np.array([d(90, 0), d(2, 0), d(2, 180), d(10, 180), d(30, 90)])


def main():
    q = argparse.ArgumentParser()
    q.add_argument("--elevaciones", default="0,2,4,10,30,55,90")
    q.add_argument("--bruma", type=float, default=1.0, help="multiplicador de aerosoles (CIELO_BRUMA)")
    q.add_argument("--g", type=float, default=None)
    q.add_argument("--mie", type=float, default=None)
    q.add_argument("--rayleigh", default=None, help="tres coeficientes separados por comas")
    q.add_argument("--multiple", type=float, default=None, help="ATM_MULTIPLE")
    q.add_argument("--rayleigh-fase", choices=["elek", "rayleigh"], default="elek")
    a = q.parse_args()

    p, k, _ = gt.leer_parametros()
    if a.g is not None:
        p["g"] = a.g
    if a.mie is not None:
        p["mie"] = a.mie
    if a.rayleigh is not None:
        p["rayleigh"] = np.array([float(x) for x in a.rayleigh.split(",")])
    if a.multiple is not None:
        k["ATM_MULTIPLE"] = a.multiple
    p["mie"] *= a.bruma
    p["mie_abs"] *= a.bruma
    if a.rayleigh_fase == "elek":
        gt.fase_rayleigh = fase_elek

    o = np.array([0.0, p["radio_planeta"] + k["ATM_ALTURA_OBSERVADOR"], 0.0])
    t_mediodia = gt.transmitancia(o[None], np.array([0.0, 1.0, 0.0]), p, 64)[0]
    irradiancia = math.pi / float(t_mediodia @ LUMA)
    color_sol = cuerpo_negro(6000.0)
    d_hemi, peso = gt.direcciones_hemisferio()

    print(f"irradiancia en lo alto {irradiancia:.4f}; color del sol {color_sol.round(3)}; g {p['g']}; mie {p['mie']:.3e}; "
          f"rayleigh {p['rayleigh']}; múltiple {k['ATM_MULTIPLE']}")
    errores = []
    for elev in [int(x) for x in a.elevaciones.split(",")]:
        el = math.radians(elev)
        luz = np.array([math.cos(el), math.sin(el), 0.0])
        # El término múltiple como lo lee el shader: media de las filas cielo y suelo de la tabla, iterado.
        multiple = np.zeros(3)
        for _ in range(gt.ITERACIONES_MULTIPLE):
            L = gt.cielo(o, d_hemi, luz, irradiancia, multiple, p)
            e_cielo = np.sum(L * peso[:, None], 0)
            t_sol = gt.transmitancia(o[None], luz, p, 64)[0]
            suelo = k["ATM_ALBEDO_SUELO"] / math.pi * (irradiancia * t_sol * max(math.sin(el), 0.0) + e_cielo)
            multiple = k["ATM_MULTIPLE"] * 0.5 * (e_cielo / math.pi + suelo)
        nuestro = gt.cielo(o, direcciones(elev), luz, irradiancia, multiple, p) * color_sol
        print(f"\nsol a {elev:3d}°")
        for nombre, n, orig in zip(DIRECCIONES, nuestro, ORIGINAL[elev]):
            orig = np.array(orig)
            razon = float(n @ LUMA) / max(float(orig @ LUMA), 1e-9)
            errores.append(abs(math.log2(max(razon, 1e-9))))
            tono_n = n / max(n.max(), 1e-9)
            tono_o = orig / max(orig.max(), 1e-9)
            print(f"  {nombre:16s} nuestro {n.round(4)}  original {orig.round(4)}  luma ×{razon:5.2f}  "
                  f"tono nuestro {tono_n.round(2)} orig {tono_o.round(2)}")
    print(f"\nerror medio en EV (|log2 razón|): {np.mean(errores):.2f}; máximo {np.max(errores):.2f}")


if __name__ == "__main__":
    main()
