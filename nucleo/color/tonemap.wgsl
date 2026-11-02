// Operadores de mapeo de tonos, intercambiables: misma firma (lineal HDR -> lineal 0..1).
// Porqué: docs/efectos/nucleo.md §Color y docs/decisiones/0004-codificacion-del-picture.md

const COL_TONEMAP_VULPE: u32 = 0u;
const COL_TONEMAP_REINHARD_LUMINANCIA: u32 = 1u;
const COL_TONEMAP_ACES: u32 = 2u;

// Reinhard extendido (Reinhard et al. 2002, ec. 4) por canal; `blanco` es el valor que llega a 1.
// Es el de la codificación del «picture» (ADR 0004).
fn col_tonemap_reinhard_canal(c: vec3<f32>, blanco: f32) -> vec3<f32> {
    let x = max(c, vec3<f32>(0.0));
    return mat_saturar3(x * (1.0 + x / (blanco * blanco)) / (1.0 + x));
}

// Inversa exacta de la anterior en [0, 1]: raíz positiva de x²/W² + x(1 − y) − y = 0, en la forma que no
// cancela cifras.
fn col_tonemap_reinhard_canal_inversa(y_entrada: vec3<f32>, blanco: f32) -> vec3<f32> {
    let y = mat_saturar3(y_entrada);
    let uno_menos = 1.0 - y;
    let w2 = blanco * blanco;
    return 2.0 * y / (uno_menos + sqrt(uno_menos * uno_menos + 4.0 * y / w2));
}

// Reinhard extendido sobre la luminancia, reescalando el color para no desaturar.
fn col_tonemap_reinhard_luminancia(c: vec3<f32>, blanco: f32) -> vec3<f32> {
    let l = col_luminancia(c);
    let l_salida = l * (1.0 + l / (blanco * blanco)) / (1.0 + l);
    return mat_saturar3(c * (l_salida / max(l, MAT_EPSILON)));
}

// Aproximación racional de la curva ACES de Narkowicz (2015).
fn col_tonemap_aces(c: vec3<f32>) -> vec3<f32> {
    let a = 2.51;
    let b = 0.03;
    let cc = 2.43;
    let d = 0.59;
    let e = 0.14;
    return mat_saturar3((c * (a * c + b)) / (c * (cc * c + d) + e));
}

// Elige operador; el resto del pack solo llama a esta.
fn col_tonemap(c: vec3<f32>, operador: u32, blanco: f32) -> vec3<f32> {
    switch operador {
        case COL_TONEMAP_REINHARD_LUMINANCIA: { return col_tonemap_reinhard_luminancia(c, blanco); }
        case COL_TONEMAP_ACES: { return col_tonemap_aces(c); }
        default: { return col_tonemap_reinhard_canal(c, blanco); }
    }
}
