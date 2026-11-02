// Un solo raymarch para aire, niebla y nubes, con una sola transmitancia. Porqué: docs/efectos/niebla-y-nubes.md §Raymarch

struct VolRayo {
    camara: vec3<f32>,      // posición absoluta de la cámara
    dir: vec3<f32>,         // unitaria
    escena: f32,            // distancia a lo que hay detrás, bloques (enorme en el cielo)
    ruido: f32,             // 0..1 por píxel y fotograma
}

struct VolLuz {
    direccion: vec3<f32>,   // hacia el astro que ilumina
    irradiancia: vec3<f32>, // perpendicular, escala común (π = sol de mediodía)
    cielo: vec3<f32>,       // radiancia media del cielo
    suelo: vec3<f32>,
}

struct VolAjustes {
    niebla: VolAjustesNiebla,
    nubes: VolNubes,
    alcance: f32,           // longitud del tramo de niebla, bloques
    pasos_niebla: i32,
    pasos_nubes: i32,
    con_niebla: bool,
    con_nubes: bool,
    con_sombra: bool,
    sombra_nubes: f32,      // 0..1
    mapa: LuzMapa,
}

const VOL_NUBES_DISTANCIA: f32 = 6000.0;   // bloques: más allá las nubes no se integran

struct VolResultado {
    luz: vec3<f32>,
    transmitancia: f32,
}

// Integración analítica de un tramo (Hillaire 2015), con la extinción gris del medio.
fn vol_tramo(r: ptr<function, VolResultado>, fuente: vec3<f32>, sigma: f32, paso: f32) {
    let s = max(sigma, 1e-7);
    let t = exp(-s * paso);
    (*r).luz += (*r).transmitancia * fuente * (1.0 - t) / s;
    (*r).transmitancia *= t;
}

// Distancias de entrada y salida del rayo en la losa horizontal [y0, y1]; x >= y si no la cruza.
fn vol_losa(camara_y: f32, dir_y: f32, y0: f32, y1: f32) -> vec2<f32> {
    if abs(dir_y) < 1e-5 {
        return select(vec2<f32>(1.0, 0.0), vec2<f32>(0.0, 1e9), camara_y >= y0 && camara_y <= y1);
    }
    let a = (y0 - camara_y) / dir_y;
    let b = (y1 - camara_y) / dir_y;
    return vec2<f32>(max(min(a, b), 0.0), max(max(a, b), 0.0));
}

// Aire y niebla en [t0, t1] (por debajo del plano de nubes).
fn vol_tramo_niebla(r: ptr<function, VolResultado>, t0: f32, t1: f32, rayo: VolRayo, luz: VolLuz, a: VolAjustes,
                    mapa: texture_depth_2d, comparacion: sampler_comparison, t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>) {
    let cos_luz = dot(rayo.dir, luz.direccion);
    let fase_aire_r = atm_fase_rayleigh(cos_luz);
    let fase_aire_m = vol_hg(cos_luz, 0.76);
    let largo = t1 - t0;
    // La sombra de las nubes varía despacio: se evalúa en los extremos del tramo y se interpola.
    let nubes_cerca = vol_sombra_nubes(rayo.camara + rayo.dir * t0, luz.direccion, a.nubes, t2, s2);
    let nubes_lejos = vol_sombra_nubes(rayo.camara + rayo.dir * t1, luz.direccion, a.nubes, t2, s2);
    // El cielo ya lleva su atmósfera (01): el aire solo se integra delante del terreno.
    let bruma = select(a.niebla.bruma, 0.0, rayo.escena > 1e8);
    let ambiente = mix(luz.suelo, luz.cielo, 0.7);
    let f = 10.0;
    var anterior = 0.0;
    for (var i = 0; i < a.pasos_niebla; i++) {
        let u = (f32(i) + rayo.ruido) / f32(a.pasos_niebla);
        let t = t0 + (pow(f, u) - 1.0) / (f - 1.0) * largo;
        let siguiente = (pow(f, (f32(i) + 1.0) / f32(a.pasos_niebla)) - 1.0) / (f - 1.0) * largo;
        let paso = max(siguiente - anterior, 1e-3);
        anterior = siguiente;
        let p_rel = rayo.dir * t;
        let mundo = rayo.camara + p_rel;
        let aire = vol_aire(mundo.y, bruma);
        let niebla = vol_niebla(mundo, a.niebla, t3);
        var visible = 1.0;
        if a.con_sombra {
            let m = luz_posicion_mapa(a.mapa, p_rel);
            if all(m.xy > vec2<f32>(0.0)) && all(m.xy < vec2<f32>(1.0)) {
                visible = textureSampleCompareLevel(mapa, comparacion, m.xy, m.z);
            }
        }
        visible *= mix(1.0, mix(nubes_cerca, nubes_lejos, (t - t0) / max(largo, 1.0)), a.sombra_nubes);
        let sol = luz.irradiancia * visible;
        let fuente_aire = aire.rayleigh * (sol * fase_aire_r + ambiente) + aire.mie * (sol * fase_aire_m + ambiente);
        let fuente_niebla = niebla * (sol * vol_fase_niebla(cos_luz)
                          + luz.cielo * a.niebla.ambiente * mix(0.05, 0.15, rayo.dir.y * 0.5 + 0.5));
        let sigma = (col_luminancia(aire.rayleigh) + aire.mie * 1.1) + niebla;
        vol_tramo(r, fuente_aire + fuente_niebla, sigma, paso);
    }
}

// La capa de nubes `i` en [t0, t1].
fn vol_tramo_nubes(r: ptr<function, VolResultado>, i: i32, t0: f32, t1_entrada: f32, rayo: VolRayo, luz: VolLuz, a: VolAjustes,
                   t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>) {
    let t1 = min(t1_entrada, VOL_NUBES_DISTANCIA);
    if t1 <= t0 {
        return;
    }
    let cos_luz = dot(rayo.dir, luz.direccion);
    let y0 = VOL_MAR + VOL_BASE[i];
    let pasos = select(a.pasos_nubes, 3, i == 2);
    let paso = (t1 - t0) / f32(pasos);
    let sigma_nube = select(0.25, 0.03, i == 2);
    for (var j = 0; j < pasos; j++) {
        let t = t0 + paso * (f32(j) + rayo.ruido);
        let mundo = rayo.camara + rayo.dir * t;
        let d = vol_nube(mundo, i, a.nubes, t2, s2, t3, true);
        if d <= 0.001 {
            continue;
        }
        // Luz: Beer con dos muestras hacia el astro, a distancias crecientes (sin erosión).
        var hacia = 0.0;
        hacia += vol_nube(mundo + luz.direccion * 8.0, i, a.nubes, t2, s2, t3, false) * 8.0;
        hacia += vol_nube(mundo + luz.direccion * 28.0, i, a.nubes, t2, s2, t3, false) * 20.0;
        let t_sol = exp(-sigma_nube * hacia * 1.2);
        let altura = clamp((mundo.y - y0) / VOL_ESPESOR[i], 0.0, 1.0);
        let ambiente = luz.cielo * mix(0.35, 1.1, altura) + luz.suelo * (1.0 - altura) * 0.3;
        // Se funden con la distancia: cerca del horizonte cada paso cubre cientos de bloques.
        let lejos = 1.0 - smoothstep(VOL_NUBES_DISTANCIA * 0.5, VOL_NUBES_DISTANCIA, t);
        let sigma = sigma_nube * d * lejos;
        let fuente = sigma * (luz.irradiancia * t_sol * vol_fase(cos_luz, d * 4.0) + ambiente);
        vol_tramo(r, fuente, sigma, paso);
        if (*r).transmitancia < 0.01 {
            break;
        }
    }
}

// La niebla solo existe por debajo del plano de nubes; las capas de nubes, en sus losas. Los cuatro tramos no
// se solapan: se integran en el orden en que el rayo los cruza (de delante hacia atrás), esté la cámara por
// debajo, dentro o por encima de cada capa.
fn vol_integrar(rayo: VolRayo, luz: VolLuz, a: VolAjustes, mapa: texture_depth_2d, comparacion: sampler_comparison,
                t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>) -> VolResultado {
    var r = VolResultado(vec3<f32>(0.0), 1.0);
    var inicio = array<f32, 4>(1e30, 1e30, 1e30, 1e30);
    var fin = array<f32, 4>(0.0, 0.0, 0.0, 0.0);
    if a.con_niebla {
        let bajo = vol_losa(rayo.camara.y, rayo.dir.y, -1e6, VOL_MAR + VOL_BASE.x);
        if bajo.y > bajo.x {
            inicio[0] = bajo.x;
            fin[0] = min(min(bajo.y, rayo.escena), bajo.x + a.alcance);
        }
    }
    if a.con_nubes {
        for (var i = 0; i < 3; i++) {
            if a.nubes.perfil.cobertura[i] > 0.0 {
                let y0 = VOL_MAR + VOL_BASE[i];
                let l = vol_losa(rayo.camara.y, rayo.dir.y, y0, y0 + VOL_ESPESOR[i]);
                if l.y > l.x {
                    inicio[i + 1] = l.x;
                    fin[i + 1] = min(l.y, rayo.escena);
                }
            }
        }
    }
    var hecho = array<bool, 4>(false, false, false, false);
    for (var k = 0; k < 4; k++) {
        var elegido = -1;
        var menor = 1e29;
        for (var j = 0; j < 4; j++) {
            if !hecho[j] && inicio[j] < menor {
                menor = inicio[j];
                elegido = j;
            }
        }
        if elegido < 0 || r.transmitancia < 0.01 {
            break;
        }
        hecho[elegido] = true;
        if fin[elegido] <= inicio[elegido] {
            continue;
        }
        if elegido == 0 {
            vol_tramo_niebla(&r, inicio[0], fin[0], rayo, luz, a, mapa, comparacion, t2, s2, t3);
        } else {
            vol_tramo_nubes(&r, elegido - 1, inicio[elegido], fin[elegido], rayo, luz, a, t2, s2, t3);
        }
    }
    return r;
}
