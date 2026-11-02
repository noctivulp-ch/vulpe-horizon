// Rayos del fractal: desenfoque radial en pantalla desde el centro de la figura (Mitchell, GPU Gems 3 cap. 13),
// con la caída por distancia, sin cortar en el borde, oclusión de nubes, núcleo con codo y concentración. PROPIO
// de Vulpe (especificación 14). La imagen llega por parámetro. Porqué: docs/efectos/rayos-del-fractal.md

struct ImgRayos {
    origen: vec2<f32>,      // uv del polo
    convergente: bool,      // el polo es la antípoda (fuente detrás): se camina alejándose
    intensidad: f32,
    foco: f32,
    longitud: f32,          // fracción de pantalla
    caida: f32,             // 0..1 por cada 24 muestras
    umbral: f32,            // luminancia (mapeada)
    nucleo: f32,
    muestras: i32,
    oclusion: f32,
    exposicion: f32,
    ruido: f32,
}

fn img_rayos_muestra(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, e: f32) -> vec3<f32> {
    let c = textureSampleLevel(t, s, uv, 0.0).rgb * e;
    return c / (1.0 + c);
}

fn img_rayos(uv: vec2<f32>, t: texture_2d<f32>, s: sampler, r: ImgRayos) -> vec3<f32> {
    let hacia = uv - r.origen;
    let dist = max(length(hacia), 1e-4);
    let recorrido = min(dist, 1.2) * r.longitud;
    var delta = hacia / dist * recorrido / f32(r.muestras);
    if r.convergente {
        delta = -delta;
    }
    var coord = uv - delta * r.ruido;
    let paso = pow(r.caida, 24.0 / f32(r.muestras));
    var decaimiento = 1.0;
    var transmitancia = 1.0;
    var acc = vec3<f32>(0.0);
    for (var i = 0; i < r.muestras; i++) {
        coord -= delta;
        let dentro = clamp(coord, vec2<f32>(0.0), vec2<f32>(1.0));
        let fuera = abs(coord - dentro);
        let margen = exp2(-max(fuera.x, fuera.y) * 6.0);
        let m = img_rayos_muestra(t, s, dentro, r.exposicion);
        let l = col_luminancia(m);
        acc += m * smoothstep(r.umbral, r.umbral * 2.0 + 0.001, l) * decaimiento * transmitancia * margen;
        transmitancia *= mix(1.0, 0.55 + 0.45 * smoothstep(0.0, r.umbral * 2.0, l), r.oclusion);
        decaimiento *= paso;
    }
    acc *= (1.0 - paso) * 1.4;
    let borde = 1.0 - smoothstep(2.5, 4.5, length(r.origen - 0.5));
    let pico = max(acc.r, max(acc.g, acc.b));
    if pico > r.nucleo {
        let exceso = pico - r.nucleo;
        acc *= (r.nucleo + exceso / (1.0 + exceso / (r.nucleo * 0.6 + 1e-4))) / pico;
    }
    // Concentración relativa al núcleo: la potencia se aplica al rayo normalizado por el nivel del núcleo (en la
    // escala de Vulpe el rayo rondaba 1; aquí ~0,05 y la potencia lo apagaba). Porqué: docs/efectos/rayos-del-fractal.md
    let escala = max(r.nucleo, 1e-3);
    acc = pow(max(acc / escala, vec3<f32>(0.0)), vec3<f32>(1.0 + r.foco * 3.0)) * escala * (1.0 + r.foco * 4.0);
    return acc * r.intensidad * borde;
}
