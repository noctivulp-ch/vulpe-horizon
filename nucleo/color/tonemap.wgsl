// Operadores de mapeo de tonos, intercambiables: misma firma (lineal HDR -> lineal 0..1).
// Porqué: docs/efectos/nucleo.md §Color y docs/decisiones/0004-codificacion-del-picture.md

// Para el mapeo final (opción «Mapeo de tonos»). El de la codificación del «picture» es
// col_tonemap_reinhard_maximo, aparte (ADR 0004).
const COL_TONEMAP_FILMICO: u32 = 0u;
const COL_TONEMAP_ACES: u32 = 1u;
const COL_TONEMAP_REINHARD_LUMINANCIA: u32 = 2u;

// Reinhard extendido (Reinhard et al. 2002, ec. 4) por canal; `blanco` es el valor que llega a 1.
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

// Reinhard extendido sobre el canal máximo: los tres canales se escalan por igual (conserva tono y
// saturación) y ninguno pasa de 1. Es el de la codificación del «picture» (ADR 0004).
fn col_tonemap_reinhard_maximo(c: vec3<f32>, blanco: f32) -> vec3<f32> {
    let x = max(c, vec3<f32>(0.0));
    let m = max(x.r, max(x.g, x.b));
    let y = m * (1.0 + m / (blanco * blanco)) / (1.0 + m);
    return mat_saturar3(x * (y / max(m, 1e-9)));
}

// Inversa exacta: el canal máximo de la salida es el mapeo del de la entrada.
fn col_tonemap_reinhard_maximo_inversa(y_entrada: vec3<f32>, blanco: f32) -> vec3<f32> {
    let y = mat_saturar3(y_entrada);
    let my = max(y.r, max(y.g, y.b));
    let m = col_tonemap_reinhard_canal_inversa(vec3<f32>(my), blanco).x;
    return y * (m / max(my, 1e-9));
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

// Curva fílmica de Hejl (2015), la racional con punto blanco `blanco`, por canal; devuelve luz lineal. Con blanco 3,1
// reproduce el fílmico por defecto del original (paridad/11: error ≤ 0,009 en pantalla desde 0,01 de entrada).
fn col_hejl2015_parcial(x: vec4<f32>) -> vec4<f32> {
    let a = 1.425 * x + 0.05;
    return (x * a + 0.004) / (x * (a + 0.55) + 0.0491) - 0.0821;
}

fn col_tonemap_filmico(c: vec3<f32>, blanco: f32) -> vec3<f32> {
    let v = col_hejl2015_parcial(vec4<f32>(max(c, vec3<f32>(0.0)), blanco));
    return mat_saturar3(v.rgb / v.w);
}

// Elige operador; el resto del pack solo llama a esta.
fn col_tonemap(c: vec3<f32>, operador: u32, blanco: f32, blanco_filmico: f32) -> vec3<f32> {
    switch operador {
        case COL_TONEMAP_ACES: { return col_tonemap_aces(c); }
        case COL_TONEMAP_REINHARD_LUMINANCIA: { return col_tonemap_reinhard_luminancia(c, blanco); }
        default: { return col_tonemap_filmico(c, blanco_filmico); }
    }
}
