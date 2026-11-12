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
    autosombra: f32,        // la luz directa dentro de la nube cae con exp(−autosombra·acumulado hacia el astro)
    autosombra_paso: vec2<f32>, // bloques entre tomas hacia el astro (cúmulos; los altoestratos, ×4 y dos tomas)
    ambiente: f32,          // fracción del ambiente de superficie que es el de la niebla y las nubes
    exponente_cobertura: f32,
    impacto_umbral: f32,
    huella_por_bloque: f32, // bloques que cubre un píxel del volumen por bloque de distancia    // densidad (forma × densidad del perfil) desde la que un punto cuenta como nube que corta la niebla
    sombra_tau: f32,
    sombra_umbral: f32,
    sombra_alto: f32,       // multiplicador del espesor óptico oblicuo de los altoestratos sobre el suelo
    umbral_cobertura: vec2<f32>, // umbral de la cobertura 2D de los cúmulos: x − cob·y (F-4)
    rampa_cobertura: f32,   // anchura de la rampa sobre el umbral
    fase_escala: f32,       // escala del término solar de las nubes sobre la fase medida (F-6)
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
    return pow(smoothstep(umbral, umbral + n.forma.rampa_cobertura, u), n.forma.exponente_cobertura);
}

// Transmitancia de las nubes hacia la luz en el punto `mundo`: la cobertura donde el rayo hacia la luz
// cruza la mitad de cada capa baja, al cuadrado (sin pasos).
fn vol_sombra_nubes(mundo: vec3<f32>, luz: vec3<f32>, n: VolNubes, t: texture_2d<f32>, s: sampler) -> f32 {
    if luz.y <= 0.02 {
        return 1.0;
    }
    // Densidad acumulada de las capas hacia el sol: cobertura sin erosión menos un umbral medio, por la densidad del
    // perfil; la transmitancia es exp(−k·d²) (tabla B de fino/04 §Medidos: 0,61 con 0,05; 0,135 con 0,1).
    // Porqué: docs/efectos/sombras.md §«Sombra de nubes medida» (F-13)
    var d = 0.0;
    for (var i = 0; i < 2; i++) {
        let h = VOL_MAR + VOL_BASE[i] + VOL_ESPESOR[i] * 0.5;
        if mundo.y < h {
            let p = mundo + luz * ((h - mundo.y) / luz.y);
            let c = vol_cobertura(p.xz, i, n, t, s);
            d += max(c - n.forma.sombra_umbral, 0.0) * n.perfil.densidad[i];
        }
    }
    // Altoestratos (fino/04 «Respuesta a la pregunta 9»): entran en la misma suma, sin umbral y por 1 − |seno de la
    // elevación| (con el sol bajo pesan mucho más).
    let h_alto = VOL_MAR + VOL_BASE.z + VOL_ESPESOR.z * 0.5;
    if mundo.y < h_alto {
        let p = mundo + luz * ((h_alto - mundo.y) / luz.y);
        d += vol_cobertura(p.xz, 2, n, t, s) * n.perfil.densidad.z * (1.0 - abs(luz.y)) * n.forma.sombra_alto;
    }
    let tau = n.forma.sombra_tau * d * d;
    return exp(-tau);
}

// 1 bajo las nubes bajas, 0 por encima de su techo (el velo de la lluvia sobre el cielo se va al subir).
fn vol_bajo_las_nubes(y: f32) -> f32 {
    return 1.0 - smoothstep(VOL_MAR + VOL_BASE.x, VOL_MAR + VOL_BASE.x + VOL_ESPESOR.x, y);
}
