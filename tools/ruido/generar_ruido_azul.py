#!/usr/bin/env python3
"""Genera texturas/ruido_azul.png: 64×64, cuatro canales de ruido azul independientes, en mosaico.

Por qué existe: el tramado de los raymarch y los muestreos estocásticos (volumen, sombras, reflejos, jitter
del cielo) los limpia el TAA, y el ruido azul tiene su energía en las altas frecuencias, que es lo que el
recorte por varianza y la mezcla quitan mejor; el ruido blanco se ve como grano grueso. Ver
docs/efectos/taa.md §Ruido azul y la especificación 09.

Método de vacío y cúmulo (Ulichney, «The void-and-cluster method for dither array generation», SPIE 1993),
con la energía medida por un núcleo gaussiano en un toro (para que repita), sigma 1,5.

Uso: tools/ruido/generar_ruido_azul.py  (numpy, Pillow). Determinista.
"""
from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]
N = 64
SIGMA = 1.5


def nucleo():
    d = np.minimum(np.arange(N), N - np.arange(N))
    dx, dy = np.meshgrid(d, d, indexing="ij")
    return np.exp(-(dx * dx + dy * dy) / (2 * SIGMA * SIGMA))


def energia(mascara, k_f):
    return np.real(np.fft.ifft2(np.fft.fft2(mascara.astype(float)) * k_f))


def vacio_y_cumulo(semilla):
    rng = np.random.default_rng(semilla)
    k_f = np.fft.fft2(nucleo())
    total = N * N
    inicial = total // 10
    m = np.zeros((N, N), bool)
    m.flat[rng.choice(total, inicial, replace=False)] = True
    # Fase 0: repartir los puntos iniciales (mover el del cúmulo más denso al vacío más grande).
    while True:
        e = energia(m, k_f)
        cum = np.argmax(np.where(m, e, -np.inf))
        m.flat[cum] = False
        e = energia(m, k_f)
        vac = np.argmin(np.where(m, np.inf, e))
        if vac == cum:
            m.flat[cum] = True
            break
        m.flat[vac] = True
    rango = np.zeros((N, N), int)
    # Fase 1: quitar puntos del cúmulo más denso, rangos descendentes.
    prot = m.copy()
    e = energia(prot, k_f)
    for r in range(inicial - 1, -1, -1):
        cum = np.argmax(np.where(prot, e, -np.inf))
        prot.flat[cum] = False
        rango.flat[cum] = r
        e -= np.roll(np.roll(np.real(np.fft.ifft2(k_f)), cum // N, 0), cum % N, 1)
    # Fases 2 y 3: llenar el vacío más grande, rangos ascendentes.
    prot = m.copy()
    e = energia(prot, k_f)
    k_esp = np.real(np.fft.ifft2(k_f))
    for r in range(inicial, total):
        vac = np.argmin(np.where(prot, np.inf, e))
        prot.flat[vac] = True
        rango.flat[vac] = r
        e += np.roll(np.roll(k_esp, vac // N, 0), vac % N, 1)
    return (rango + 0.5) / total


def main():
    canales = [vacio_y_cumulo(s) for s in (11, 23, 37, 41)]
    img = np.stack([np.clip(np.round(c * 255.0 - 0.5), 0, 255).astype(np.uint8) for c in canales], -1)
    salida = RAIZ / "texturas/ruido_azul.png"
    Image.fromarray(img, "RGBA").save(salida)
    print(f"escrito {salida.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
