// Escarcha sutil en biomas nevados: velo claro y frío y motas cristalinas con destellos
// especulares en la rejilla de 32 texeles por bloque.
// Porqué: docs/efectos/suelo-clima.md §Escarcha

struct SupParamEscarcha {
    rejilla: f32,           // texeles por bloque (32)
    color: vec3<f32>,       // tinte claro y frío de la escarcha (lineal)
    velo: f32,              // fuerza del aclarado superficial
    mota_umbral: f32,       // umbral de hash para motas cristalinas (0..1)
    mota_albedo: f32,       // cuánto blanquea la mota al albedo
    mota_suavidad: f32,     // suavidad PBR de la mota
    mota_f0: f32,           // reflectancia base del cristal
    inclinacion: f32,       // inclinación máxima de las microfacetas
    exponente: f32,         // nitidez del destello especular
    destello: f32,          // intensidad del destello con la luz recibida
    dist_inicio: f32,       // bloques desde donde se atenúan los destellos
    dist_fin: f32,          // bloques donde se apagan los destellos
}

struct SupEscarcha {
    velo: f32,              // 0..1: cobertura del velo frío
    mota: f32,              // 0..1: presencia de mota cristalina en la rejilla de 32
    destello: f32,          // 0..1: intensidad del destello especular hacia la cámara
}

fn sup_escarcha(
    mundo: vec3<f32>,
    cielo: f32,
    arriba: f32,
    vista: vec3<f32>,
    luz_dir: vec3<f32>,
    distancia: f32,
    peso: f32,
    p: SupParamEscarcha,
) -> SupEscarcha {
    if arriba <= 0.9 || peso <= 0.0 {
        return SupEscarcha(0.0, 0.0, 0.0);
    }
    let borde = rui_valor2(mundo.xz * 0.7) * 0.06;
    let expuesto = smoothstep(0.82, 0.92, cielo + borde);
    let base = peso * expuesto;
    if base <= 0.0 {
        return SupEscarcha(0.0, 0.0, 0.0);
    }

    // Variación orgánica del velo de escarcha sobre la superficie.
    let mancha = 0.65 + 0.35 * rui_valor2(mundo.xz * 0.45);
    let velo = base * mancha;

    // Motas cristalinas en la rejilla de 32 texeles por bloque en coordenadas del mundo.
    let lejos = 1.0 - smoothstep(p.dist_inicio, p.dist_fin, distancia);
    if lejos <= 0.0 {
        return SupEscarcha(velo, 0.0, 0.0);
    }
    let celda = vec2<i32>(floor(mundo.xz * p.rejilla));
    let h = rui_hash33(vec3<i32>(celda.x, i32(floor(mundo.y * 2.0)), celda.y));
    let mota_bruta = smoothstep(p.mota_umbral, 1.0, h.x);
    let mota = mota_bruta * base * lejos;
    if mota <= 0.0 {
        return SupEscarcha(velo, 0.0, 0.0);
    }

    // Microfaceta con inclinación propia: brilla tanto con el astro directo como con el cielo
    // cenital (en nevadas cubiertas), cambiando de motas al mover o girar la cámara.
    let rx = (h.y * 2.0 - 1.0) * p.inclinacion;
    let rz = (h.z * 2.0 - 1.0) * p.inclinacion;
    let n_cristal = normalize(vec3<f32>(rx, 1.0, rz));
    let h_sol = normalize(vista + normalize(vec3<f32>(luz_dir.x, max(luz_dir.y, 0.15), luz_dir.z)));
    let h_cielo = normalize(vista + vec3<f32>(0.0, 1.0, 0.0));
    let pico_sol = pow(max(dot(n_cristal, h_sol), 0.0), p.exponente);
    let pico_cielo = pow(max(dot(n_cristal, h_cielo), 0.0), p.exponente);
    let destello = max(pico_sol, pico_cielo * 0.85) * mota * p.destello;
    return SupEscarcha(velo, mota, destello);
}

// Albedo con escarcha: un poco más claro y frío, y blanco en las motas cristalinas.
fn sup_albedo_escarcha(albedo: vec3<f32>, e: SupEscarcha, p: SupParamEscarcha) -> vec3<f32> {
    let claro = mix(albedo, p.color, e.velo * p.velo);
    return mix(claro, vec3<f32>(0.96, 0.98, 1.0), e.mota * p.mota_albedo);
}
