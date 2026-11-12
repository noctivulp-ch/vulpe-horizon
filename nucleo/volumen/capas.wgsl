// Las capas de nubes: alturas, cobertura 2D y la sombra que dejan en el suelo. Compartido: lo usan el
// cielo (lluvia por encima de las nubes), el material (sombras de nubes) y el volumen.
// Porqué: docs/efectos/niebla-y-nubes.md §Nubes

const VOL_MAR: f32 = 63.0;
// Base y espesor (bloques sobre el mar): cúmulos pequeños (Y 250..350), grandes (Y 500..700), altoestratos (Y 2000).
const VOL_BASE: vec3<f32> = vec3<f32>(187.0, 437.0, 1937.0);
const VOL_ESPESOR: vec3<f32> = vec3<f32>(100.0, 200.0, 12.0);

struct VolFormaNubes {
    escala_zonas: vec2<f32>,    // bloques por mosaico del ruido grande: pequeños, grandes (formas/nubes.md §3)
    escala_forma: vec2<f32>,    // bloques por mosaico del ruido de forma: pequeños, grandes
    escala_alto: f32,
    escala_erosion: vec4<f32>,  // erosión gruesa, bloques por mosaico 3D: pequeños (horizontal, vertical), grandes (§5)
    inclinacion: f32,
    erosion_fuerza: f32,        // fracción de la erosión que se resta (§5: la mitad)
    erosion_media: f32,         // lo que se resta en la versión barata (sombra, luz hacia el astro): 0,135
    escala_detalle: vec4<f32>,  // erosión fina, igual que escala_erosion
    sigma: vec3<f32>,
    tramo_max: f32,
    autosombra: f32,        // la luz directa dentro de la nube cae con exp(−autosombra·acumulado hacia el astro)
    autosombra_paso: vec2<f32>, // bloques entre tomas hacia el astro (cúmulos; los altoestratos, ×4 y dos tomas)
    ambiente: f32,          // fracción del ambiente de superficie que es el de la niebla y las nubes
    impacto_umbral: f32,
    huella_por_bloque: f32, // bloques que cubre un píxel del volumen por bloque de distancia
    sombra_tau: f32,
    sombra_umbral: f32,
    sombra_alto: f32,       // multiplicador del espesor óptico oblicuo de los altoestratos sobre el suelo
    pesos_pequenos: vec3<f32>, // «valor» de los pequeños: x·|grande − z| + y·(1 − forma) (§3, cordones)
    pesos_grandes: vec2<f32>,  // «valor» de los grandes: x·grande + y·forma (§3, masas)
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
    // formas/nubes.md §3. Los canales de la textura propia se llevan a los percentiles de los ruidos del original:
    // «suave» (A, sesgado a oscuro) desde R, «medio» (B) desde B o desde R. «valor» es 0 donde más nube.
    // Porqué: docs/efectos/niebla-y-nubes.md §«Forma de las nubes (F-36)»
    var valor = 0.0;
    if i == 0 {
        // Pequeños: cordones donde el ruido grande está cerca de su percentil 70, rotos por la forma (A invertido²).
        let grande = 0.49 + (vol_ruido2d(t, s, xz / n.forma.escala_zonas.x).b - 0.5) * 1.25;
        let suave = clamp(0.24 + (vol_ruido2d(t, s, xz / n.forma.escala_forma.x).r - 0.49) * 1.13, 0.0, 1.0);
        let forma = (1.0 - suave) * (1.0 - suave);
        let w = n.forma.pesos_pequenos;
        valor = w.x * abs(grande - w.z) + w.y * (1.0 - forma);
    } else {
        // Grandes: masas donde los dos ruidos son bajos a la vez; ejes cambiados para no coincidir con los pequeños.
        let q = xz.yx + vec2<f32>(0.37 * n.forma.escala_zonas.y);
        let grande = 0.49 + (vol_ruido2d(t, s, q / n.forma.escala_zonas.y).b - 0.5) * 1.25;
        let medio = 0.49 + (vol_ruido2d(t, s, q / n.forma.escala_forma.y).r - 0.49) * 1.54;
        valor = n.forma.pesos_grandes.x * grande + n.forma.pesos_grandes.y * medio;
    }
    return clamp((cob - valor) / sqrt(cob), 0.0, 1.0);
}

// Perfil vertical de los cúmulos (formas/nubes.md §4), por fracción del espesor; se le resta a la forma lo que le
// falta para 1. Tablas medidas: 11 puntos cada una.
const VOL_PERFIL_H = array<array<f32, 11>, 2>(
    array<f32, 11>(0.0, 0.02, 0.05, 0.10, 0.25, 0.40, 0.60, 0.80, 0.90, 0.95, 1.0),
    array<f32, 11>(0.0, 0.025, 0.05, 0.125, 0.25, 0.5, 0.75, 0.9, 0.975, 1.0, 1.0),
);
const VOL_PERFIL_V = array<array<f32, 11>, 2>(
    array<f32, 11>(0.0, 0.34, 0.66, 0.88, 0.88, 0.82, 0.74, 0.67, 0.41, 0.23, 0.0),
    array<f32, 11>(0.0, 0.66, 0.90, 0.94, 0.88, 0.78, 0.69, 0.41, 0.12, 0.0, 0.0),
);

fn vol_perfil_cumulo(h: f32, i: i32) -> f32 {
    let capa = min(i, 1);
    for (var k = 1; k < 11; k++) {
        let h1 = VOL_PERFIL_H[capa][k];
        if h <= h1 {
            let h0 = VOL_PERFIL_H[capa][k - 1];
            let f = clamp((h - h0) / max(h1 - h0, 1e-4), 0.0, 1.0);
            return mix(VOL_PERFIL_V[capa][k - 1], VOL_PERFIL_V[capa][k], f);
        }
    }
    return 0.0;
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
