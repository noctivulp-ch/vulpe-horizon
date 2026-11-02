#!/usr/bin/env python3
"""Precalcula la tabla de la atmósfera (texturas/atmosfera.png) con el mismo modelo que el núcleo WGSL.

Por qué existe: la etapa `material` no puede leer el resultado del `sky`, y la luz de las superficies, la
niebla y el propio cielo necesitan el color del sol tras la atmósfera y el color medio del cielo. Ver
docs/efectos/cielo-y-atmosfera.md §Tabla.

Lee los parámetros de nucleo/atmosfera/parametros.wgsl (única fuente de verdad), integra la dispersión
simple con la aproximación de dispersión múltiple iterada, y escribe:
  fila 0  irradiancia del astro tras la atmósfera, perpendicular a él
  fila 1  radiancia media del cielo = irradiancia sobre un plano horizontal / π
  fila 2  radiancia del suelo de albedo medio bajo esa luz
  fila 3  radiancia media del cielo junto al horizonte (2–6° de elevación)
y texturas/transmitancia.png, la transmitancia hasta el borde de la atmósfera por altura y ángulo
para 64 elevaciones del astro de −20° a 90°, codificado en log2 por canal. Además reescribe
ATM_IRRADIANCIA_SOL en parametros.wgsl para que el sol de mediodía deje π en un plano perpendicular.

Uso: tools/atmosfera/generar_tabla.py  (numpy, Pillow)
"""
import math
import re
from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parents[2]
PARAMETROS = RAIZ / "nucleo/atmosfera/parametros.wgsl"
TABLA = RAIZ / "nucleo/atmosfera/tabla.wgsl"
SALIDA = RAIZ / "texturas/atmosfera.png"
SALIDA_TRANS = RAIZ / "texturas/transmitancia.png"

PASOS_VISTA = 24
PASOS_LUZ = 12
ITERACIONES_MULTIPLE = 4


def leer_constantes(texto):
    numero = r"(-?[0-9.]+(?:e-?[0-9]+)?)"
    return {m.group(1): float(m.group(2)) for m in re.finditer(r"const (ATM_\w+): f32 = " + numero, texto)}


def leer_parametros():
    texto = PARAMETROS.read_text()
    cuerpo = texto[texto.index("fn atm_tierra()"):]
    cuerpo = cuerpo[cuerpo.index("AtmParametros(") + len("AtmParametros("):cuerpo.index(");")]
    n = [float(x) for x in re.findall(r"-?[0-9]+\.?[0-9]*(?:e-?[0-9]+)?", cuerpo.replace("vec3<f32>", ""))]
    p = dict(
        radio_planeta=n[0], radio_atmosfera=n[1],
        rayleigh=np.array(n[2:5]), rayleigh_h=n[5],
        mie=n[6], mie_abs=n[7], mie_h=n[8], g=n[9],
        ozono=np.array(n[10:13]), ozono_c=n[13], ozono_w=n[14],
    )
    return p, leer_constantes(texto), texto


def esfera(o, d, r):
    b = np.sum(o * d, -1)
    c = np.sum(o * o, -1) - r * r
    disc = b * b - c
    s = np.sqrt(np.maximum(disc, 0.0))
    t0 = np.where(disc < 0, -1.0, -b - s)
    t1 = np.where(disc < 0, -1.0, -b + s)
    return t0, t1


def medio(h, p):
    h = np.maximum(h, 0.0)[..., None]
    d_r = np.exp(-h / p["rayleigh_h"])
    d_m = np.exp(-h / p["mie_h"])
    d_o = np.maximum(0.0, 1.0 - np.abs(h - p["ozono_c"]) / p["ozono_w"])
    r = p["rayleigh"] * d_r
    m = p["mie"] * d_m
    ext = r + (m + p["mie_abs"] * d_m) + p["ozono"] * d_o
    return r, m[..., 0], ext


def transmitancia(o, d, p, pasos):
    """o: (..., 3), d: (3,) o (..., 3)."""
    d = np.broadcast_to(d, o.shape)
    suelo0, _ = esfera(o, d, p["radio_planeta"])
    _, largo = esfera(o, d, p["radio_atmosfera"])
    largo = np.maximum(largo, 0.0)
    paso = largo / pasos
    prof = np.zeros(o.shape[:-1] + (3,))
    for i in range(pasos):
        pos = o + d * (paso * (i + 0.5))[..., None]
        prof += medio(np.linalg.norm(pos, axis=-1) - p["radio_planeta"], p)[2] * paso[..., None]
    t = np.exp(-prof)
    return np.where((suelo0 > 0)[..., None], 0.0, t)


def fase_rayleigh(c):
    return 3.0 / (16.0 * math.pi) * (1.0 + c * c)


def fase_cs(c, g):
    g2 = g * g
    k = 3.0 / (8.0 * math.pi) * (1.0 - g2) / (2.0 + g2)
    den = np.maximum(1.0 + g2 - 2.0 * g * c, 1e-4)
    return k * (1.0 + c * c) / (den * np.sqrt(den))


def cielo(o, dirs, luz, irradiancia, multiple, p):
    """Radiancia dispersada hacia o por cada dirección de dirs (N, 3)."""
    oo = np.broadcast_to(o, dirs.shape)
    t0, t1 = esfera(oo, dirs, p["radio_atmosfera"])
    s0, _ = esfera(oo, dirs, p["radio_planeta"])
    fin = np.where(s0 > 0, s0, t1)
    inicio = np.maximum(t0, 0.0)
    paso = (fin - inicio) / PASOS_VISTA
    cos_v = dirs @ luz
    trans = np.ones((len(dirs), 3))
    total = np.zeros((len(dirs), 3))
    for i in range(PASOS_VISTA):
        pos = oo + dirs * (inicio + paso * (i + 0.5))[:, None]
        r, m, ext = medio(np.linalg.norm(pos, axis=-1) - p["radio_planeta"], p)
        hacia = transmitancia(pos, luz, p, PASOS_LUZ)
        fuente = (r * fase_rayleigh(cos_v)[:, None] + (m * fase_cs(cos_v, p["g"]))[:, None]) * hacia * irradiancia
        fuente += (r + m[:, None]) * multiple
        ext = np.maximum(ext, 1e-12)
        tt = np.exp(-ext * paso[:, None])
        total += trans * fuente * (1.0 - tt) / ext
        trans *= tt
    return total


def direcciones_hemisferio(n_theta=20, n_phi=40):
    th = (np.arange(n_theta) + 0.5) / n_theta * (math.pi / 2)
    ph = (np.arange(n_phi) + 0.5) / n_phi * 2 * math.pi
    T, P = np.meshgrid(th, ph, indexing="ij")
    d = np.stack([np.sin(T) * np.cos(P), np.cos(T), np.sin(T) * np.sin(P)], -1).reshape(-1, 3)
    peso = (np.cos(T) * np.sin(T)).reshape(-1) * (math.pi / 2 / n_theta) * (2 * math.pi / n_phi)
    return d, peso


def direcciones_horizonte(n_phi=32):
    ph = (np.arange(n_phi) + 0.5) / n_phi * 2 * math.pi
    out = []
    for e in (2.0, 4.0, 6.0):
        el = math.radians(e)
        out.append(np.stack([math.cos(el) * np.cos(ph), np.full_like(ph, math.sin(el)), math.cos(el) * np.sin(ph)], -1))
    return np.concatenate(out)


def calcular(p, k, irradiancia_toa):
    ancho = 64
    elevs = np.linspace(-20.0, 90.0, ancho)
    o = np.array([0.0, p["radio_planeta"] + k["ATM_ALTURA_OBSERVADOR"], 0.0])
    d_hemi, peso = direcciones_hemisferio()
    d_hor = direcciones_horizonte()
    multiple = np.zeros((ancho, 3))
    for _ in range(ITERACIONES_MULTIPLE):
        sol = np.zeros((ancho, 3))
        cielo_medio = np.zeros((ancho, 3))
        suelo = np.zeros((ancho, 3))
        horizonte = np.zeros((ancho, 3))
        for i, e in enumerate(elevs):
            el = math.radians(e)
            luz = np.array([math.cos(el), math.sin(el), 0.0])
            t_sol = transmitancia(o[None], luz, p, 64)[0]
            sol[i] = irradiancia_toa * t_sol
            L = cielo(o, d_hemi, luz, irradiancia_toa, multiple[i], p)
            e_cielo = np.sum(L * peso[:, None], 0)
            cielo_medio[i] = e_cielo / math.pi
            suelo[i] = k["ATM_ALBEDO_SUELO"] / math.pi * (sol[i] * max(math.sin(el), 0.0) + e_cielo)
            horizonte[i] = cielo(o, d_hor, luz, irradiancia_toa, multiple[i], p).mean(0)
        multiple = 0.5 * (cielo_medio + suelo)
    return elevs, sol, cielo_medio, suelo, horizonte


def tabla_transmitancia(p, ancho, alto):
    """Parametrización de Bruneton 2017 (ver atm_transmitancia_uv en nucleo/atmosfera/tabla.wgsl).
    Sin bruma extra: la opción de bruma no cambia la transmitancia hacia los astros (aproximación)."""
    rb, rt = p["radio_planeta"], p["radio_atmosfera"]
    h = math.sqrt(rt * rt - rb * rb)
    x_mu = (np.arange(ancho) + 0.5 - 0.5) / (ancho - 1)
    x_r = (np.arange(alto) + 0.5 - 0.5) / (alto - 1)
    XM, XR = np.meshgrid(np.clip(x_mu, 0, 1), np.clip(x_r, 0, 1))
    rho = h * XR
    r = np.sqrt(rho * rho + rb * rb)
    d_min = rt - r
    d_max = rho + h
    d = d_min + XM * (d_max - d_min)
    mu = np.where(d == 0, 1.0, (h * h - rho * rho - d * d) / np.maximum(2.0 * r * d, 1e-6))
    mu = np.clip(mu, -1.0, 1.0)
    o = np.stack([np.zeros_like(r), r, np.zeros_like(r)], -1)
    dirs = np.stack([np.sqrt(1.0 - mu * mu), mu, np.zeros_like(mu)], -1)
    # Sin prueba de suelo: la parametrización solo cubre rayos que no lo tocan (la tapa el shader).
    largo = esfera(o, dirs, rt)[1]
    largo = np.maximum(largo, 0.0)
    pasos = 64
    paso = largo / pasos
    prof = np.zeros(r.shape + (3,))
    for i in range(pasos):
        pos = o + dirs * (paso * (i + 0.5))[..., None]
        prof += medio(np.linalg.norm(pos, axis=-1) - rb, p)[2] * paso[..., None]
    return np.exp(-prof)


def codificar(x, log_min, log_rango):
    x = np.maximum(x, 0.0)
    v = (np.log2(np.maximum(x, 2.0 ** log_min)) - log_min) / log_rango
    v = np.where(x < 2.0 ** log_min, 0.0, v)
    return np.clip(np.round(v * 255.0), 0, 255).astype(np.uint8)


def main():
    p, k, texto = leer_parametros()
    kt = leer_constantes(TABLA.read_text())
    # Irradiancia en lo alto que deja π al sol de mediodía (90°) en el observador.
    o = np.array([[0.0, p["radio_planeta"] + k["ATM_ALTURA_OBSERVADOR"], 0.0]])
    t_mediodia = transmitancia(o, np.array([0.0, 1.0, 0.0]), p, 64)[0]
    irradiancia = math.pi / float(np.dot(t_mediodia, [0.2126, 0.7152, 0.0722]))
    elevs, sol, cielo_medio, suelo, horizonte = calcular(p, k, irradiancia)
    filas = np.stack([sol, cielo_medio, suelo, horizonte])
    rgb = codificar(filas, kt["ATM_TABLA_LOG_MIN"], kt["ATM_TABLA_LOG_RANGO"])
    rgba = np.concatenate([rgb, np.full(rgb.shape[:2] + (1,), 255, np.uint8)], -1)
    SALIDA.parent.mkdir(exist_ok=True)
    Image.fromarray(rgba, "RGBA").save(SALIDA)
    kt2 = leer_constantes(TABLA.read_text())
    t = tabla_transmitancia(p, int(kt2["ATM_TRANS_ANCHO"]), int(kt2["ATM_TRANS_ALTO"]))
    t8 = np.clip(np.round(np.cbrt(t) * 255.0), 0, 255).astype(np.uint8)
    t8 = np.concatenate([t8, np.full(t8.shape[:2] + (1,), 255, np.uint8)], -1)
    Image.fromarray(t8, "RGBA").save(SALIDA_TRANS)
    nuevo = re.sub(r"const ATM_IRRADIANCIA_SOL: f32 = [0-9.]+;", f"const ATM_IRRADIANCIA_SOL: f32 = {irradiancia:.4f};", texto)
    PARAMETROS.write_text(nuevo)
    lum = lambda c: float(np.dot(c, [0.2126, 0.7152, 0.0722]))
    print(f"irradiancia en lo alto: {irradiancia:.4f}")
    for e in (90.0, 30.0, 10.0, 0.0, -6.0):
        i = int(np.argmin(np.abs(elevs - e)))
        print(f"  elev {elevs[i]:6.1f}°  sol {sol[i].round(3)}  cielo {cielo_medio[i].round(4)} "
              f"(cielo/sol {lum(cielo_medio[i]) * math.pi / max(lum(sol[i]), 1e-9):.3f})  "
              f"suelo {suelo[i].round(4)}  horizonte {horizonte[i].round(4)}")
    print(f"escritos {SALIDA.relative_to(RAIZ)} y {SALIDA_TRANS.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
