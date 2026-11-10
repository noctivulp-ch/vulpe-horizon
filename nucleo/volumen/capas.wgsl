// Las capas de nubes: alturas, cobertura 2D y la sombra que dejan en el suelo. Compartido: lo usan el
// cielo (lluvia por encima de las nubes), el material (sombras de nubes) y el volumen.
// Porqué: docs/efectos/niebla-y-nubes.md §Nubes

const VOL_MAR: f32 = 63.0;
// Base y espesor (bloques sobre el mar): cúmulos pequeños (Y 250..350), grandes (Y 500..700), altoestratos (Y 2000).
const VOL_BASE: vec3<f32> = vec3<f32>(187.0, 437.0, 1937.0);
const VOL_ESPESOR: vec3<f32> = vec3<f32>(100.0, 200.0, 12.0);

struct VolFormaNubes {
    escala_zonas: f32,
    escala_forma: vec2<f32>,
    escala_alto: f32,
    escala_erosion: vec2<f32>,
    inclinacion: f32,
    base_redondeo: f32,
    caida_altura: f32,
    cupula_desde: f32,
    cupula_potencia: f32,
    erosion_fuerza: f32,
    erosion_base: f32,
    escala_detalle: f32,
    detalle_fuerza: f32,
    sigma: vec3<f32>,
    tramo_max: f32,
    sombra_tau: f32,
    sombra_alto: f32,       // multiplicador del espesor óptico oblicuo de los altoestratos sobre el suelo
    umbral_cobertura: vec2<f32>, // umbral de la cobertura 2D de los cúmulos: x − cob·y (F-4)
    rampa_cobertura: f32,   // anchura de la rampa sobre el umbral
}

struct VolNubes {
    perfil: VolPerfil,
    viento: vec2<f32>,      // desplazamiento acumulado, bloques
    direccion: vec2<f32>,   // dirección del viento, unitaria (inclinación de los cúmulos)
    forma: VolFormaNubes,
}

// Cobertura 0..1 de la capa `i` (0, 1, 2) en el punto horizontal `xz` (mundo).
fn vol_cobertura(xz_entrada: vec2<f32>, i: i32, n: VolNubes, t: texture_2d<f32>, s: sampler) -> f32 {
    let xz = xz_entrada + n.viento * select(1.0, 1.6, i == 2);
    let cob = n.perfil.cobertura[i];
    if cob <= 0.0 {
        return 0.0;
    }
    if i == 2 {
        let b = vol_ruido2d(t, s, xz / n.forma.escala_alto + vol_ruido2d(t, s, xz / (n.forma.escala_alto * 2.2)).rg * 0.3).b;
        let u_alto = (b - 0.32) * 2.8;
        let umbral_alto = 0.72 - cob * 0.28;
        return smoothstep(umbral_alto, umbral_alto + 0.35, u_alto);
    }
    let escala_f = n.forma.escala_forma[i];
    let zonas = vol_ruido2d(t, s, xz / n.forma.escala_zonas).b;
    let muestra_forma = vol_ruido2d(t, s, xz / escala_f + f32(i) * 0.37);
    let forma = muestra_forma.r * 0.75 + muestra_forma.a * 0.25;
    let u = (forma * 0.7 + zonas * 0.3 - 0.36) * 3.2;
    // Umbral y rampa medidos sobre la textura (tools): con cob = 1, ~64 % del plano con nube y ~34 % densa.
    // Porqué: docs/efectos/niebla-y-nubes.md §Cobertura (F-4)
    let umbral = n.forma.umbral_cobertura.x - cob * n.forma.umbral_cobertura.y;
    return sqrt(smoothstep(umbral, umbral + n.forma.rampa_cobertura, u));
}

// Transmitancia de las nubes hacia la luz en el punto `mundo`: la cobertura donde el rayo hacia la luz
// cruza la mitad de cada capa baja, al cuadrado (sin pasos).
fn vol_sombra_nubes(mundo: vec3<f32>, luz: vec3<f32>, n: VolNubes, t: texture_2d<f32>, s: sampler) -> f32 {
    if luz.y <= 0.02 {
        return 1.0;
    }
    var tau = 0.0;
    for (var i = 0; i < 2; i++) {
        let h = VOL_MAR + VOL_BASE[i] + VOL_ESPESOR[i] * 0.5;
        if mundo.y < h {
            let p = mundo + luz * ((h - mundo.y) / luz.y);
            let c = vol_cobertura(p.xz, i, n, t, s);
            tau += c * c * n.forma.sombra_tau * n.perfil.densidad[i];
        }
    }
    // Altoestratos (fino/04 §6): lámina fina; su espesor óptico crece con el camino oblicuo (1 / seno de la elevación),
    // así que con el sol rasante apagan la luz directa aunque a mediodía apenas sombreen.
    // Porqué: docs/efectos/niebla-y-nubes.md §Sombra de los altoestratos
    let h_alto = VOL_MAR + VOL_BASE.z + VOL_ESPESOR.z * 0.5;
    if mundo.y < h_alto {
        let p = mundo + luz * ((h_alto - mundo.y) / luz.y);
        let c = vol_cobertura(p.xz, 2, n, t, s);
        tau += c * n.perfil.densidad.z * n.forma.sigma.z * VOL_ESPESOR.z * n.forma.sombra_alto / max(luz.y, 0.05);
    }
    return exp(-tau);
}

// 1 bajo las nubes bajas, 0 por encima de su techo (el velo de la lluvia sobre el cielo se va al subir).
fn vol_bajo_las_nubes(y: f32) -> f32 {
    return 1.0 - smoothstep(VOL_MAR + VOL_BASE.x, VOL_MAR + VOL_BASE.x + VOL_ESPESOR.x, y);
}
