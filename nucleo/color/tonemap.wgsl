// Operadores de mapeo de tonos, intercambiables: misma firma (lineal HDR -> lineal 0..1).
// Porqué: docs/efectos/nucleo.md §Color

const COL_TONEMAP_NINGUNO: u32 = 0u;
const COL_TONEMAP_REINHARD: u32 = 1u;
const COL_TONEMAP_ACES: u32 = 2u;

// Reinhard extendido sobre la luminancia (Reinhard et al. 2002, ec. 4); `blanco` es el
// valor que llega a 1.
fn col_tonemap_reinhard(c: vec3<f32>, blanco: f32) -> vec3<f32> {
    let l = col_luminancia(c);
    let l_salida = l * (1.0 + l / (blanco * blanco)) / (1.0 + l);
    return c * (l_salida / max(l, MAT_EPSILON));
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
        case COL_TONEMAP_REINHARD: { return col_tonemap_reinhard(c, blanco); }
        case COL_TONEMAP_ACES: { return col_tonemap_aces(c); }
        default: { return mat_saturar3(c); }
    }
}
