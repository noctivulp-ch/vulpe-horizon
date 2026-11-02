// Conjuntos de Julia y ampliaciones del Mandelbrot por tiempo de escape. Porqué: docs/efectos/cielo-fractal.md §Conjunto

const CIE_DIBUJO_ORIGINAL: u32 = 0u;
const CIE_DIBUJO_SUAVE: u32 = 1u;

struct CieConjunto {
    c: vec2<f32>,           // parámetro de la Julia, o centro de la ampliación
    es_zoom: bool,
    zoom: f32,
    iteraciones: i32,
    dibujo: u32,
}

fn cie_complejo_cuadrado(z: vec2<f32>) -> vec2<f32> {
    return vec2<f32>(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y);
}

// Dentro del cardioide principal o del bulbo de periodo 2: nunca escapa (Wikipedia, «Plotting algorithms
// for the Mandelbrot set», §Cardioid / bulb checking).
fn cie_dentro_de_bulbos(c: vec2<f32>) -> bool {
    let x = c.x - 0.25;
    let q = x * x + c.y * c.y;
    let cardioide = q * (q + x) <= 0.25 * c.y * c.y;
    let bulbo = (c.x + 1.0) * (c.x + 1.0) + c.y * c.y <= 0.0625;
    return cardioide || bulbo;
}

// Valor de iteración t en [0, 1]; 0 si no escapa (el interior queda oscuro).
//  Original: cuenta entera n/N con radio 2 (sus escalones son las «líneas» que se ven: no suavizar).
//  Suave: n + 1 − log2(log2|z|) con radio 16.
fn cie_tiempo_de_escape(p: vec2<f32>, k: CieConjunto) -> f32 {
    var c = k.c;
    var z = p;
    if k.es_zoom {
        c = k.c + p * k.zoom;
        if cie_dentro_de_bulbos(c) {
            return 0.0;
        }
        z = c;
    }
    let suave = k.dibujo == CIE_DIBUJO_SUAVE;
    let radio2 = select(4.0, 256.0, suave);
    for (var n = 0; n < k.iteraciones; n++) {
        z = cie_complejo_cuadrado(z) + c;
        let m2 = dot(z, z);
        if m2 > radio2 {
            var cuenta = f32(n);
            if suave {
                cuenta = f32(n) + 1.0 - log2(log2(m2) * 0.5);
            }
            return clamp(cuenta / f32(k.iteraciones), 0.0, 1.0);
        }
    }
    return 0.0;
}
