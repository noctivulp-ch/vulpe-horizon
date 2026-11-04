#!/usr/bin/env python3
"""Réplica en numpy de `luz_ao` (nucleo/luz/oclusion.wgsl) sobre el rincón sintético de paridad/08 §(b): suelo y pared
que forman una arista, cámara a 1,62 bloques del suelo, campo vertical de 70°, 1920×1080, columna central, ruido promediado
en 16 giros (lo que hace el TAA). Imprime la AO cruda por distancia a la arista para comparar con las tablas de A.
Uso: tools/paridad/ao_rincon.py [--radio-k K] [--radio-min A] [--radio-max B] [--escala E] [--sesgo S] [--muestras N]
"""
import argparse
import math
import numpy as np

ANCHO, ALTO, FOV = 1920, 1080, math.radians(70.0)
OJO = 1.62


def camara(pared):
    paso = math.atan2(OJO, pared)          # la arista en el centro de la pantalla
    adelante = np.array([0.0, -math.sin(paso), math.cos(paso)])
    derecha = np.array([1.0, 0.0, 0.0])
    arriba = np.cross(adelante, derecha) * -1.0
    return adelante, derecha, arriba


def rayo(uv, cam):
    adelante, derecha, arriba = cam
    t = math.tan(FOV / 2)
    x = (uv[0] * 2 - 1) * t * ANCHO / ALTO
    y = (1 - uv[1] * 2) * t
    d = adelante + derecha * x + arriba * y
    return d / np.linalg.norm(d)


def golpe(d, pared):
    """Punto (relativo a la cámara) y normal donde el rayo d toca suelo (y = −OJO) o pared (z = pared)."""
    mejor = None
    if d[1] < 0:
        t = -OJO / d[1]
        p = d * t
        if p[2] <= pared:
            mejor = (t, p, np.array([0.0, 1.0, 0.0]))
    if d[2] > 0:
        t = pared / d[2]
        p = d * t
        if p[1] >= -OJO and (mejor is None or t < mejor[0]):
            mejor = (t, p, np.array([0.0, 0.0, -1.0]))
    return mejor


def proyectar(p, cam):
    adelante, derecha, arriba = cam
    z = p @ adelante
    t = math.tan(FOV / 2)
    x = (p @ derecha) / z / (t * ANCHO / ALTO)
    y = (p @ arriba) / z / t
    return np.array([(x + 1) / 2, (1 - y) / 2])


def ao(p, n, cam, pared, a):
    dist = np.linalg.norm(p)
    radio = min(max(dist * a.radio_k, a.radio_min), a.radio_max)
    centro = proyectar(p, cam)
    tang = np.cross(n, np.array([0.37, 0.71, 0.6]))
    tang /= np.linalg.norm(tang)
    borde = proyectar(p + tang * radio, cam)
    # (ndc → uv: la mitad de la distancia en ndc)
    lejos = min(max((dist - 10.0) / 40.0, 0.0), 1.0); lejos = lejos * lejos * (3 - 2 * lejos)
    radio_uv = min(max(np.linalg.norm(borde - centro), 2.0 / ALTO), a.tope_uv) * (1.0 - 0.5 * lejos * a.lejos)
    aspecto = ALTO / ANCHO
    total = 0.0
    for g in range(16):
        giro = (g + 0.5) / 16
        suma = 0.0
        for i in range(a.muestras):
            r = math.sqrt((i + 0.5) / a.muestras)
            ang = i * 2.39996 + giro * 2 * math.pi
            uv = centro + np.array([math.cos(ang) * aspecto, math.sin(ang)]) * r * radio_uv
            h = golpe(rayo(uv, cam), pared)
            if h is None:
                continue
            v = h[1] - p
            l2 = v @ v
            coseno = (v / math.sqrt(max(l2, 1e-6))) @ n
            peso = max(0.0, 1.0 - l2 / (radio * radio * 4.0))
            suma += max(0.0, coseno - a.sesgo) * peso
        total += max(1.0 - suma / a.muestras * a.escala, 0.0)
    return total / 16


REF = {3: [(0.764, 0.770), (0.794, 0.807), (0.825, 0.845), (0.886, 0.907), (0.926, 0.948), (0.979, 0.993), (1, 1), (1, 1), (1, 1), (1, 1)],
       8: [(None, 0.835), (0.750, 0.846), (0.772, 0.870), (0.805, 0.899), (0.831, 0.922), (0.877, 0.954), (0.921, 0.979), (0.958, 0.997), (0.999, 1), (1, 1)],
       20: [(None, 0.885), (None, 0.900), (None, 0.903), (None, 0.930), (None, 0.927), (0.799, 0.946), (0.840, 0.972), (0.873, 0.972), (0.923, 0.989), (0.942, 1)]}


def main():
    q = argparse.ArgumentParser()
    q.add_argument('--radio-k', type=float, default=0.19)
    q.add_argument('--radio-min', type=float, default=0.4)
    q.add_argument('--radio-max', type=float, default=2.0)
    q.add_argument('--tope-uv', type=float, default=0.08)
    q.add_argument('--lejos', type=float, default=1.0)
    q.add_argument('--escala', type=float, default=2.5)
    q.add_argument('--sesgo', type=float, default=0.15)
    q.add_argument('--muestras', type=int, default=7)
    a = q.parse_args()
    distancias = [0.02, 0.05, 0.1, 0.2, 0.3, 0.5, 0.75, 1, 1.5, 2]
    for pared in (3, 8, 20):
        cam = camara(pared)
        print(f'pared a {pared}: distancia  suelo  pared')
        for e in distancias:
            fila = []
            for sup in ('suelo', 'pared'):
                if sup == 'suelo':
                    pm = np.array([0.0, -OJO, pared - e]); n = np.array([0.0, 1.0, 0.0])
                else:
                    pm = np.array([0.0, -OJO + e, pared]); n = np.array([0.0, 0.0, -1.0])
                # solo si el punto se ve desde la cámara
                h = golpe(pm / np.linalg.norm(pm), pared)
                if h is None or np.linalg.norm(h[1] - pm) > 1e-3:
                    fila.append('  —  ')
                else:
                    fila.append(f'{ao(pm + n * 0.02, n, cam, pared, a):.3f}')
            ref = REF[pared][distancias.index(e)]
            print(f'  {e:5}  {fila[0]}  {fila[1]}    original {ref[0] or "  —  "}  {ref[1]}')


if __name__ == '__main__':
    main()
