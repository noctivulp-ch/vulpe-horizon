// Olas del agua: altura por octavas anisótropas con oleaje en parches, normal por diferencias finitas y
// cáusticas (material del agua y terreno bajo el agua; el struct AguOlas está en optica.wgsl). La textura de ruido llega por parámetro.
// Porqué: docs/efectos/agua.md §Olas

// Rota 137,5° (ángulo irracional) entre octavas para que no se alineen.
fn agu_rotar(p: vec2<f32>, k: f32) -> vec2<f32> {
    let a = 2.3999632 * k;
    return vec2<f32>(cos(a) * p.x - sin(a) * p.y, sin(a) * p.x + cos(a) * p.y);
}

// Curva que realza las crestas del oleaje amplio, medida en paridad/07 §2 (21 puntos de 0 a 1).
const AGU_CURVA_CRESTAS = array<f32, 21>(0.0, 0.0001, 0.0014, 0.0072, 0.0219, 0.0495, 0.0931, 0.1535, 0.2297, 0.3188,
    0.4167, 0.5184, 0.6187, 0.7128, 0.7965, 0.8669, 0.9220, 0.9614, 0.9858, 0.9975, 1.0);

fn agu_curva_crestas(x: f32) -> f32 {
    let f = clamp(x, 0.0, 1.0) * 20.0;
    let i = min(i32(f), 19);
    return mix(AGU_CURVA_CRESTAS[i], AGU_CURVA_CRESTAS[i + 1], f - f32(i));
}

// Parches de calma y mar picada (formas/agua.md §1): ruido «medio» con una onda cada ~90 bloques, fijo al mundo, por la
// curva medida que lo aplasta hacia los extremos. Devuelve el nivel de parche 0..1. Porqué: docs/efectos/agua.md §«Forma (F-37)»
const AGU_PARCHE_X = array<f32, 8>(0.0, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95, 1.0);
const AGU_PARCHE_Y = array<f32, 8>(0.0, 0.02, 0.15, 0.42, 0.71, 0.92, 1.0, 1.0);
const AGU_PARCHE_MOSAICO: f32 = 200.0;      // bloques por mosaico del canal R (semiancho 20 px de 256 → onda ~90 bloques)

fn agu_nivel_parche(xz: vec2<f32>, t: texture_2d<f32>, s: sampler) -> f32 {
    let n = clamp(0.49 + (textureSampleLevel(t, s, xz / AGU_PARCHE_MOSAICO, 0.0).r - 0.49) * 1.54, 0.0, 1.0);
    for (var k = 1; k < 8; k++) {
        if n <= AGU_PARCHE_X[k] {
            let f = (n - AGU_PARCHE_X[k - 1]) / (AGU_PARCHE_X[k] - AGU_PARCHE_X[k - 1]);
            return mix(AGU_PARCHE_Y[k - 1], AGU_PARCHE_Y[k], f);
        }
    }
    return 1.0;
}

// Amplitud del oleaje por el parche, con el mínimo de la calma (30 %).
fn agu_parches(xz: vec2<f32>, minimo: f32, t: texture_2d<f32>, s: sampler) -> f32 {
    return max(agu_nivel_parche(xz, t, s), minimo);
}

// Las tres capas de olas (formas/agua.md §2): longitudes de onda 7,4 × 1,8, 1,8 × 7,4 y 5 bloques con el canal G
// (16 celdas por mosaico: mosaico = 16 × onda), giradas 137,5° entre sí, deslizándose en bloques por segundo.
const AGU_CAPAS_MOSAICO = array<vec2<f32>, 3>(vec2<f32>(118.0, 29.0), vec2<f32>(29.0, 118.0), vec2<f32>(80.0, 80.0));
const AGU_CAPAS_VELOCIDAD = array<vec2<f32>, 3>(vec2<f32>(1.7, 0.4), vec2<f32>(0.4, 1.7), vec2<f32>(1.1, 1.1));
const AGU_CAPAS_AMPLITUD = array<f32, 3>(0.12, 0.07, 0.035);
const AGU_DESFASE_PARCHE: f32 = 4.0;        // bloques que se desplaza la lectura con el nivel de parche (costura)

fn agu_capa(xz: vec2<f32>, k: i32, o: AguOlas, nivel: f32, t: texture_2d<f32>, s: sampler) -> f32 {
    let q = (agu_rotar(xz, f32(k)) + AGU_CAPAS_VELOCIDAD[k] * o.tiempo + vec2<f32>(nivel * AGU_DESFASE_PARCHE)) / AGU_CAPAS_MOSAICO[k];
    return textureSampleLevel(t, s, q, 0.0).g;
}

// Altura (bloques) en el punto horizontal `xz` del mundo; `octavas` 2 o 3.
fn agu_altura(xz: vec2<f32>, o: AguOlas, octavas: i32, t: texture_2d<f32>, s: sampler) -> f32 {
    let nivel = agu_nivel_parche(xz, t, s);
    var h = 0.0;
    for (var k = 0; k < octavas; k++) {
        h += (agu_capa(xz, k, o, nivel, t, s) - 0.5) * AGU_CAPAS_AMPLITUD[k];
    }
    return h * o.fuerza * max(nivel, o.calma);
}

// Normal de las olas en superficies horizontales y caras verticales/cascadas (fino/07 §1).
fn agu_normal(mundo: vec3<f32>, normal_geom: vec3<f32>, distancia: f32, o: AguOlas, t: texture_2d<f32>, s: sampler) -> vec3<f32> {
    // Distancia al vecino (formas/agua.md §3): 1 bloque en calma, 0,15 en picada, más distancia ÷ 384, hasta 3.
    let paso = min(mix(1.0, 0.15, agu_nivel_parche(mundo.xz, t, s)) + distancia / 384.0, 3.0);
    let octavas = select(3, 2, distancia > 128.0);
    let es_vertical = abs(normal_geom.y) < 0.75;
    if es_vertical {
        // Cascada / corriente vertical (fino/07 §1): flujo descendente y proyección lateral dominante
        let usa_yz = abs(normal_geom.x) > abs(normal_geom.z);
        let u_lat = select(mundo.x, mundo.z, usa_yz);
        let v_lat = mundo.y * 0.45 + o.tiempo * OPC_AGUA_VELOCIDAD_CASCADA;
        let coord0 = vec2<f32>(u_lat, v_lat);
        let h0 = agu_altura(coord0, o, 2, t, s);
        let hu = agu_altura(coord0 + vec2<f32>(paso, 0.0), o, 2, t, s);
        let hv = agu_altura(coord0 + vec2<f32>(0.0, paso), o, 2, t, s);
        let du = (h0 - hu) / paso;
        let dv = (h0 - hv) / paso;
        var pert = vec3<f32>(0.0);
        if usa_yz {
            pert = vec3<f32>(0.0, dv, du);
        } else {
            pert = vec3<f32>(du, dv, 0.0);
        }
        return normalize(normal_geom + pert * 0.6);
    }
    let xz = mundo.xz;
    let h0 = agu_altura(xz, o, octavas, t, s);
    let hx = agu_altura(xz + vec2<f32>(paso, 0.0), o, octavas, t, s);
    let hz = agu_altura(xz + vec2<f32>(0.0, paso), o, octavas, t, s);
    let n = normalize(vec3<f32>(h0 - hx, paso, h0 - hz));
    return select(n, -n, normal_geom.y < 0.0);
}

// Cáusticas (formas/agua.md §4): las mismas tres capas, cada una plegada dos veces (líneas finas), promediadas y
// concentradas; en calma manchas suaves, en picada una red de líneas brillantes.
fn agu_causticas(xz: vec2<f32>, o: AguOlas, t: texture_2d<f32>, s: sampler) -> f32 {
    let nivel = agu_nivel_parche(xz, t, s);
    var c = 0.0;
    for (var k = 0; k < 3; k++) {
        let n = agu_capa(xz, k, o, nivel, t, s);
        let linea = abs(abs(2.0 * n - 1.0) * 2.0 - 1.0);
        c += exp(-linea * 7.5 * o.agudeza);
    }
    let red = pow(c, 1.4) * 1.8;
    return mix(1.0, red, max(nivel, o.calma));
}
