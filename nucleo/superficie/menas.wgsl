// Menas brillantes: qué téxeles de un bloque son mineral, comparando su color con la roca mayoritaria de la
// propia textura. PROPIO de Vulpe (especificación 12). Las muestras llegan por parámetro.
// Porqué: docs/efectos/menas-brillantes.md

struct SupMena {
    mascara: f32,       // 0..1 de mineral
    oscuro: f32,        // cuánto viene de la regla del carbón
}

fn sup_croma(c: vec3<f32>) -> vec3<f32> {
    return c - vec3<f32>(col_luminancia(c));
}

// `color`: el téxel del punto; `m`: 16 muestras del mismo sprite (rejilla de 4×4), sRGB como la textura;
// `umbral`: sensibilidad (0,06); `carbon`: aplicar la regla del carbón.
fn sup_mena(color: vec3<f32>, m: array<vec3<f32>, 16>, umbral: f32, carbon: bool) -> SupMena {
    var media = vec3<f32>(0.0);
    for (var k = 0; k < 16; k++) {
        media += m[k] / 16.0;
    }
    // 1. Partir de la roca conocida con más muestras parecidas en croma.
    let rocas = array<vec3<f32>, 6>(vec3<f32>(0.49, 0.49, 0.49), vec3<f32>(0.38, 0.17, 0.17), vec3<f32>(0.17, 0.14, 0.18),
                                    vec3<f32>(0.86, 0.87, 0.63), vec3<f32>(0.55, 0.40, 0.30), vec3<f32>(0.85, 0.80, 0.62));
    var mejor = 0;
    var mejor_cuenta = -1;
    for (var r = 0; r < 6; r++) {
        var cuenta = 0;
        for (var k = 0; k < 16; k++) {
            if length(sup_croma(m[k]) - sup_croma(rocas[r])) < 0.04 {
                cuenta++;
            }
        }
        if cuenta > mejor_cuenta {
            mejor_cuenta = cuenta;
            mejor = r;
        }
    }
    if mejor_cuenta >= 4 {
        var suma = vec3<f32>(0.0);
        var n = 0.0;
        for (var k = 0; k < 16; k++) {
            if length(sup_croma(m[k]) - sup_croma(rocas[mejor])) < 0.04 {
                suma += m[k];
                n += 1.0;
            }
        }
        media = suma / n;
    }
    // 2. La roca es el color mayoritario: dos pasadas de media ponderada (pesos de Cauchy) que quitan peso a lo
    // que se aleja.
    for (var paso = 0; paso < 2; paso++) {
        var suma = vec3<f32>(0.0);
        var pesos = 0.0;
        for (var k = 0; k < 16; k++) {
            let e = length(sup_croma(m[k]) - sup_croma(media)) / 0.04;
            let w = 1.0 / (1.0 + e * e);
            suma += m[k] * w;
            pesos += w;
        }
        media = suma / pesos;
    }
    // 3. Diferencia de color, casi sin la de brillo.
    let d = length(sup_croma(color) - sup_croma(media)) + 0.1 * abs(col_luminancia(color) - col_luminancia(media));
    var mascara = smoothstep(umbral, umbral + 0.08, d);
    // 4. Carbón: solo sobre roca gris, lo mucho más oscuro que la roca también es mineral.
    var oscuro = 0.0;
    if carbon && mejor == 0 && mejor_cuenta >= 4 {
        oscuro = smoothstep(0.55, 0.42, col_luminancia(color) / max(col_luminancia(media), 1e-3));
        mascara = max(mascara, oscuro);
    }
    return SupMena(mascara, oscuro);
}

// Luz de las menas (25): caída cuadrática hasta el alcance, y color pleno del matiz del mineral (lineal).
fn sup_mena_luz_caida(d: f32, alcance: f32) -> f32 {
    let x = clamp(1.0 - d / alcance, 0.0, 1.0);
    return x * x;
}

fn sup_color_matiz(h: f32, s: f32, v: f32) -> vec3<f32> {
    let k = fract(vec3<f32>(h) + vec3<f32>(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0;
    return v * mix(vec3<f32>(1.0), clamp(abs(k) - 1.0, vec3<f32>(0.0), vec3<f32>(1.0)), s);
}
