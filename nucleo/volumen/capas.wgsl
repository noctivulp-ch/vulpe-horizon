// Las capas de nubes: alturas, cobertura 2D y la sombra que dejan en el suelo. Compartido: lo usan el
// cielo (lluvia por encima de las nubes), el material (sombras de nubes) y el volumen.
// Porqué: docs/efectos/niebla-y-nubes.md §Nubes

const VOL_MAR: f32 = 63.0;
// Base y espesor (bloques sobre el mar): cúmulos pequeños, cúmulos grandes, altoestratos.
const VOL_BASE: vec3<f32> = vec3<f32>(175.0, 450.0, 2000.0);
const VOL_ESPESOR: vec3<f32> = vec3<f32>(100.0, 200.0, 12.0);
// Tamaño de un periodo de la textura de ruido 2D, en bloques, por uso.
const VOL_ESCALA_ZONAS: f32 = 6000.0;   // dónde hay nubes
const VOL_ESCALA_FORMA: f32 = 3200.0;   // forma de los cúmulos (el canal G trae 16 celdas: ~200 bloques)
const VOL_ESCALA_ALTO: f32 = 9000.0;

struct VolNubes {
    perfil: VolPerfil,
    viento: vec2<f32>,      // desplazamiento acumulado, bloques
    direccion: vec2<f32>,   // dirección del viento, unitaria (inclinación de los cúmulos)
}

// Cobertura 0..1 de la capa `i` (0, 1, 2) en el punto horizontal `xz` (mundo).
fn vol_cobertura(xz_entrada: vec2<f32>, i: i32, n: VolNubes, t: texture_2d<f32>, s: sampler) -> f32 {
    let xz = xz_entrada + n.viento * select(1.0, 1.6, i == 2);
    let cob = n.perfil.cobertura[i];
    if cob <= 0.0 {
        return 0.0;
    }
    if i == 2 {
        let b = vol_ruido2d(t, s, xz / VOL_ESCALA_ALTO + vol_ruido2d(t, s, xz / 20000.0).rg * 0.3).b;
        return smoothstep(1.0 - cob, 1.0 - cob + 0.25, b);
    }
    let zonas = vol_ruido2d(t, s, xz / VOL_ESCALA_ZONAS).r;
    let forma = vol_ruido2d(t, s, xz / VOL_ESCALA_FORMA + f32(i) * 0.37).g;
    let v = forma * 0.7 + zonas * 0.6 - 0.3;
    return smoothstep(1.0 - cob, 1.0 - cob + 0.18, v);
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
            tau += c * c * 3.0 * n.perfil.densidad[i];
        }
    }
    return exp(-tau);
}

// 1 bajo las nubes bajas, 0 por encima de su techo (el velo de la lluvia sobre el cielo se va al subir).
fn vol_bajo_las_nubes(y: f32) -> f32 {
    return 1.0 - smoothstep(VOL_MAR + VOL_BASE.x, VOL_MAR + VOL_BASE.x + VOL_ESPESOR.x, y);
}
