#!/usr/bin/env python3
"""Comprueba un hash candidato para el sorteo del fractal contra la tabla de paridad/02 §«Sorteo del modo automático»:
número de conjuntos (n) y desfase de paleta de cada uno, con la semilla de la especificación 02 §3
(s = semilla·7,13 + 1 + día·13,71, sin mod), todo en coma flotante de 32 bits. Para «mismas salidas» hace falta la
combinación exacta de semilla e índice dentro del `fract(sin(·)·43758,5…)`, que la especificación no da (duda para A).
Uso: tools/paridad/sorteo_fractal.py
"""
import numpy as np

f32 = np.float32
TABLA = {  # (semilla, día): (n, desfase de paleta de cada conjunto)
    (0, 0): (1, [0.057]), (0, 1): (6, [0.759, 0.885, 0.109, 0.387, 0.410, 0.324]),
    (0, 2): (5, [0.145, 0.180, 0.238, 0.246, 0.717]), (3, 0): (1, [0.617]), (3, 1): (2, [0.293, 0.602]),
    (3, 2): (5, [0.706, 0.394, 0.666, 0.922, 0.406]), (8, 0): (3, [0.806, 0.977, 0.311]), (8, 1): (2, [0.090, 0.430]),
    (8, 2): (3, [0.547, 0.375, 0.949]), (11, 0): (4, [0.254, 0.102, 0.629, 0.969]),
    (11, 1): (6, [0.080, 0.009, 0.367, 0.044, 0.688, 0.551]), (11, 2): (1, [0.517]),
}


def fr(x):
    return x - np.floor(x)


def seno(x):
    return fr(f32(np.sin(f32(x))) * f32(43758.5453))


# Combinaciones públicas habituales de un hash escalar de dos argumentos; ninguna reproduce la tabla (2026-11-04).
CANDIDATOS = {
    'sin(s·12,9898 + k·78,233)': lambda s, k: seno(s * f32(12.9898) + k * f32(78.233)),
    'sin(s + k·12,9898)': lambda s, k: seno(s + k * f32(12.9898)),
    'sin(s·k)': lambda s, k: seno(s * k),
    'sin(s·12,9898 + k·4,1414)': lambda s, k: seno(s * f32(12.9898) + k * f32(4.1414)),
    'sin(s + k)': lambda s, k: seno(s + k),
    'sin(s·78,233 + k·12,9898)': lambda s, k: seno(s * f32(78.233) + k * f32(12.9898)),
    'sin(s + k·17)': lambda s, k: seno(s + k * f32(17.0)),
}


def probar(azar):
    ok_n = ok_d = total = 0
    for (semilla, dia), (n, desfases) in TABLA.items():
        s = f32(f32(semilla) * f32(7.13) + f32(1.0)) + f32(dia) * f32(13.71)
        ok_n += 1 + int(np.floor(azar(s, f32(1.0)) * f32(6) * f32(0.999))) == n
        for i, d in enumerate(desfases):
            total += 1
            ok_d += abs(azar(s, f32(40 + i)) - d) < 0.0015
    return ok_n, ok_d, total


if __name__ == '__main__':
    for nombre, azar in CANDIDATOS.items():
        n, d, t = probar(azar)
        print(f'{nombre:28s} n {n}/12  desfase {d}/{t}')
