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

// Oleaje en parches: ruido de muy baja frecuencia por la curva de crestas, con un mínimo (zonas movidas y en calma).
fn agu_parches(xz: vec2<f32>, minimo: f32, t: texture_2d<f32>, s: sampler) -> f32 {
    let n = textureSampleLevel(t, s, xz / 1800.0, 0.0).r;
    return max(agu_curva_crestas(n), minimo);
}

// Altura (bloques) en el punto horizontal `xz` del mundo; `octavas` 2 o 3.
fn agu_altura(xz: vec2<f32>, o: AguOlas, octavas: i32, t: texture_2d<f32>, s: sampler) -> f32 {
    // Escalas anisótropas en decenas de bloques (paridad/07 §a y subsistemas/07 §1):
    // alargada en x, alargada en z, e isótropa.
    let escalas = array<vec2<f32>, 3>(vec2<f32>(22.0, 9.0), vec2<f32>(7.0, 16.0), vec2<f32>(6.0, 6.0));
    let viento = array<vec2<f32>, 3>(vec2<f32>(1.1, 0.4), vec2<f32>(-0.5, 0.9), vec2<f32>(0.7, -0.6));
    let amplitud = array<f32, 3>(0.12, 0.07, 0.035);
    var h = 0.0;
    for (var k = 0; k < octavas; k++) {
        let q = agu_rotar(xz, f32(k)) / escalas[k] + viento[k] * o.tiempo * 0.02;
        h += (textureSampleLevel(t, s, q, 0.0).g - 0.5) * amplitud[k];
    }
    return h * o.fuerza * agu_parches(xz, o.calma, t, s);
}

// Normal de las olas en superficies horizontales y caras verticales/cascadas (fino/07 §1).
fn agu_normal(mundo: vec3<f32>, normal_geom: vec3<f32>, distancia: f32, o: AguOlas, t: texture_2d<f32>, s: sampler) -> vec3<f32> {
    let paso = clamp(distancia * 0.005, 0.08, 1.5);
    let octavas = select(3, 2, distancia > 48.0);
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

// Cáusticas: las mismas octavas con el valor absoluto plegado (líneas finas) y concentración exponencial
// en redes nítidas de luz proyectadas (fino/07 §4).
fn agu_causticas(xz: vec2<f32>, o: AguOlas, t: texture_2d<f32>, s: sampler) -> f32 {
    var c = 0.0;
    for (var k = 0; k < 2; k++) {
        let q = agu_rotar(xz, f32(k)) / (18.0 + 10.0 * f32(k)) + vec2<f32>(0.8, -0.5) * o.tiempo * 0.02 * (1.0 + f32(k));
        let n = textureSampleLevel(t, s, q, 0.0).g;
        let linea = abs(abs(2.0 * n - 1.0) * 2.0 - 1.0);
        c += exp(-linea * 7.5 * o.agudeza);
    }
    let red = pow(c * 1.5, 1.4) * 1.8;
    return mix(1.0, red, agu_parches(xz, o.calma, t, s));
}
