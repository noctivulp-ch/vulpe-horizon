// Un solo raymarch para aire, niebla y nubes, con una sola transmitancia. Porqué: docs/efectos/niebla-y-nubes.md §Raymarch

struct VolRayo {
    camara: vec3<f32>,      // posición absoluta de la cámara
    dir: vec3<f32>,         // unitaria
    escena: f32,            // distancia a lo que hay detrás, bloques
    ruido: f32,             // 0..1 por píxel y fotograma
    cielo: bool,            // el píxel es cielo (ya lleva su atmósfera: no se le integra aire)
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
    aurora: VolAurora,
}

const VOL_NUBES_DISTANCIA: f32 = 6000.0;   // bloques: más allá las nubes no se integran

struct VolResultado {
    luz: vec3<f32>,
    transmitancia: f32,
    ventana: f32,           // bloques de cono de la aurora atravesados (06)
    color_ventana: vec3<f32>, // color de esos conos, pesado
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
                    mapa: texture_depth_2d, comparacion: sampler_comparison, t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>,
                    ta: texture_2d<f32>, sa: sampler) {
    let cos_luz = dot(rayo.dir, luz.direccion);
    let fase_aire_r = atm_fase_elek(cos_luz);
    let fase_aire_m = vol_fase_aire_mie(cos_luz);
    let largo = t1 - t0;
    // La sombra de las nubes varía despacio: se evalúa en los extremos del tramo y se interpola.
    let nubes_cerca = vol_sombra_nubes(rayo.camara + rayo.dir * t0, luz.direccion, a.nubes, t2, s2);
    let nubes_lejos = vol_sombra_nubes(rayo.camara + rayo.dir * t1, luz.direccion, a.nubes, t2, s2);
    // El aire se integra también en los píxeles de cielo (fino/05 §3): es lo que da la aureola del sol y el velo
    // claro del cielo de día. Su ambiente es la radiancia media del cielo sin la ganancia de superficie.
    // Porqué: docs/efectos/niebla-y-nubes.md §Perspectiva aérea (F-2)
    let bruma = a.niebla.bruma;
    let ambiente = luz.cielo * OPC_AIRE_AMBIENTE;
    let f = 10.0;
    var anterior = 0.0;
    for (var i = 0; i < a.pasos_niebla; i++) {
        let u = (f32(i) + rayo.ruido) / f32(a.pasos_niebla);
        let t = t0 + (pow(f, u) - 1.0) / (f - 1.0) * largo;
        let siguiente = (pow(f, (f32(i) + 1.0) / f32(a.pasos_niebla)) - 1.0) / (f - 1.0) * largo;
        let paso = max(siguiente - anterior, 1e-3);
        let desde = t0 + anterior;
        anterior = siguiente;
        let p_rel = rayo.dir * t;
        let mundo = rayo.camara + p_rel;
        let aire = vol_aire(mundo.y, bruma);
        var niebla = vol_niebla(mundo, a.niebla, t3);
        // Aurora (06): luz de las cortinas y niebla que despejan los conos en el tramo del paso que cruza el velo.
        if a.aurora.activa && niebla > 0.0 {
            let au = vol_aurora_tramo(rayo.camara, rayo.dir, desde, t0 + siguiente, rayo.ruido, niebla, (*r).transmitancia, a.aurora, ta, sa);
            (*r).luz += au.luz;
            (*r).ventana += au.ventana;
            (*r).color_ventana += au.color_ventana;
            niebla *= 1.0 - au.despeje * au.fraccion;
        }
        var visible = 1.0;
        if a.con_sombra {
            let m = luz_posicion_mapa(a.mapa, p_rel);
            if all(m.xy > vec2<f32>(0.0)) && all(m.xy < vec2<f32>(1.0)) {
                visible = textureSampleCompareLevel(mapa, comparacion, m.xy, m.z);
            }
        }
        let sol_aire = luz.irradiancia * visible;
        visible *= mix(1.0, mix(nubes_cerca, nubes_lejos, (t - t0) / max(largo, 1.0)), a.sombra_nubes);
        let sol = luz.irradiancia * visible;
        // La dispersión del sol en el aire va modulada otra vez por la fase de aerosoles («fase solar directa», fino/05 §3
        // y su tabla «Halo solar»: ×1700 en el centro del sol frente a 90°, ×0,07 de espaldas). Porqué: docs/efectos/niebla-y-nubes.md §Perspectiva aérea (F-5)
        let fuente_aire = (aire.rayleigh * fase_aire_r + aire.mie * fase_aire_m) * (sol_aire * fase_aire_m) + (aire.rayleigh + aire.mie) * ambiente;
        // Ambiente de la niebla: radiancia media del cielo × fase cenital medida (F-3), con la escala base de opciones.
        let fase_cenital = vol_fase_cenital(rayo.dir.y) * OPC_NIEBLA_AMBIENTE_BASE;
        let fuente_niebla = niebla * (sol * vol_fase_niebla(cos_luz, niebla)
                          + luz.cielo * a.niebla.ambiente * fase_cenital);
        // La transmitancia cuenta la media de los tres canales del aire (implementacion/02 §4): tiñe lo que suma, oscurece en gris.
        let sigma = (dot(aire.rayleigh, vec3<f32>(1.0 / 3.0)) + aire.mie * 1.1) + niebla;
        vol_tramo(r, fuente_aire + fuente_niebla, sigma, paso);
    }
}

// Refuerzo de la luz de cielo dentro de la nube con la elevación del astro (seno): 1 hasta ~5°, 1,09 a 10°, 1,52 a 20°,
// 1,85 a 30°, 2 desde 45° (tabla de fino/05 P1; ajuste 1 + 1 − e^(−(elev/22°)³), error < 0,07).
fn vol_nube_refuerzo_cielo(seno: f32) -> f32 {
    let e = degrees(asin(clamp(seno, 0.0, 1.0))) / 22.0;
    return 2.0 - exp(-e * e * e);
}

// Oscurecimiento de la luz de cielo con la forma local: 1 en el borde, 0,76 en el interior denso (tabla de fino/05 P1;
// ajuste 0,7578 + 0,2422·e^(−4·forma), error < 0,01).
fn vol_nube_cielo_forma(forma: f32) -> f32 {
    return 0.7578 + 0.2422 * exp(-4.0 * clamp(forma, 0.0, 1.0));
}

// La capa de nubes `i` en [t0, t1].
fn vol_tramo_nubes(r: ptr<function, VolResultado>, impacto: ptr<function, f32>, i: i32, t0: f32, t1_entrada: f32, rayo: VolRayo,
                   luz: VolLuz, a: VolAjustes, t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>) {
    let tope = select(min(t0 + a.nubes.forma.tramo_max, VOL_NUBES_DISTANCIA), VOL_NUBES_DISTANCIA, i == 2);
    let t1 = min(t1_entrada, tope);
    if t1 <= t0 {
        return;
    }
    let cos_luz = dot(rayo.dir, luz.direccion);
    let y0 = VOL_MAR + VOL_BASE[i];
    let pasos = select(a.pasos_nubes, 3, i == 2);
    let largo = t1 - t0;
    let curvar = select(clamp((largo - 250.0) / 650.0, 0.0, 0.7), 0.0, i == 2);
    let sigma_nube = a.nubes.forma.sigma[i];
    var anterior = 0.0;
    for (var j = 0; j < pasos; j++) {
        let u = (f32(j) + rayo.ruido) / f32(pasos);
        let u1 = (f32(j) + 1.0) / f32(pasos);
        let s = mix(u, u * u, curvar);
        let siguiente = mix(u1, u1 * u1, curvar) * largo;
        let paso = max(siguiente - anterior, 1e-3);
        anterior = siguiente;
        let t = t0 + s * largo;
        let mundo = rayo.camara + rayo.dir * t;
        let d = vol_nube(mundo, i, a.nubes, t2, s2, t3, true, t * a.nubes.forma.huella_por_bloque);
        if d <= 0.001 {
            continue;
        }
        // Primer punto con nube de verdad en este rayo: ahí se corta la niebla (fino/05 §1).
        if d > a.nubes.forma.impacto_umbral {
            *impacto = min(*impacto, t);
        }
        // Autosombra (fino/05 P1, medida): la nube acumulada hacia el astro en tres tomas (forma × densidad, sin
        // erosión), menos con el astro alto, apaga la luz directa con exp(−5·acumulado).
        // Porqué: docs/efectos/niebla-y-nubes.md §«Luz de las nubes medida» (F-14)
        let tramo_sol = a.nubes.forma.autosombra_paso[min(i, 1)] * select(1.0, 4.0, i == 2);
        var hacia = 0.0;
        for (var k = 1; k <= 3; k++) {
            if i == 2 && k == 2 {
                continue;
            }
            hacia += vol_nube(mundo + luz.direccion * (tramo_sol * f32(k)), i, a.nubes, t2, s2, t3, false, 0.0);
        }
        var t_sol = exp(-a.nubes.forma.autosombra * hacia * (1.0 - abs(luz.direccion.y)));

        // Sombra proyectada entre capas (fino/05 §5):
        if luz.direccion.y > 0.02 {
            let inv_luz_y = 1.0 / luz.direccion.y;
            // Altoestratos (capa 2) proyectan sombra sobre ambas capas de cúmulos (0 y 1)
            if i < 2 && a.nubes.perfil.cobertura[2] > 0.0 {
                let h2 = VOL_MAR + VOL_BASE[2];
                let p2 = mundo + luz.direccion * ((h2 - mundo.y) * inv_luz_y);
                let cob2 = vol_cobertura(p2.xz, 2, a.nubes, t2, s2);
                t_sol *= exp(-cob2 * a.nubes.forma.sigma[2] * 20.0 * min(inv_luz_y, 4.0));
            }
            // Cúmulos grandes (capa 1) proyectan sombra sobre cúmulos pequeños (capa 0)
            if i == 0 && a.nubes.perfil.cobertura[1] > 0.0 {
                let h1 = VOL_MAR + VOL_BASE[1] + VOL_ESPESOR[1] * 0.5;
                let p1 = mundo + luz.direccion * ((h1 - mundo.y) * inv_luz_y);
                let cob1 = vol_cobertura(p1.xz, 1, a.nubes, t2, s2);
                t_sol *= exp(-cob1 * cob1 * a.nubes.forma.sigma[1] * 25.0);
            }
        }

        // Luz de cielo dentro de la nube (fino/05 P1, medida): el ambiente de la niebla por un refuerzo con la elevación
        // del astro (1 → 2) y un oscurecimiento con la forma local (1 → 0,76).
        let forma_local = d / max(a.nubes.perfil.densidad[i], 1e-3);
        var ambiente = luz.cielo * (a.nubes.forma.ambiente * vol_nube_refuerzo_cielo(luz.direccion.y) * vol_nube_cielo_forma(forma_local));
        // Cúmulos grandes reducen luz ambiental de cielo sobre cúmulos pequeños inferiores:
        if i == 0 && a.nubes.perfil.cobertura[1] > 0.0 {
            let cob_cenit = vol_cobertura(mundo.xz, 1, a.nubes, t2, s2);
            ambiente *= mix(1.0, 0.4, cob_cenit);
        }

        // Neblina atmosférica interna: las nubes lejanas se funden suavemente con el horizonte atmosférico
        let dist_horiz = length(rayo.dir.xz) * t;
        let niebla_ext = 1.0 - exp(-dist_horiz * (0.00012 + a.niebla.uniforme * 0.0004));
        let lejos = 1.0 - smoothstep(VOL_NUBES_DISTANCIA * 0.7, VOL_NUBES_DISTANCIA, t);
        let sigma = sigma_nube * d * lejos;
        // La fase total medida, con la densidad adimensional (forma × densidad del perfil) que usa el original.
        var luz_nube = luz.irradiancia * t_sol * vol_fase(cos_luz, d) * a.nubes.forma.fase_escala + ambiente;
        luz_nube = mix(luz_nube, luz.cielo, niebla_ext);
        let fuente = sigma * luz_nube;
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
                t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>, ta: texture_2d<f32>, sa: sampler) -> VolResultado {
    // Orden del original (fino/05 §1): primero las nubes, anotando la distancia al primer punto con nube de verdad;
    // después el aire y la niebla desde la cámara hasta la geometría, su alcance o esa nube, lo que llegue antes (no
    // hasta el plano de la base de los cúmulos); las nubes se componen detrás.
    // Porqué: docs/efectos/niebla-y-nubes.md §«Niebla hasta la primera nube» (F-17)
    var nubes = VolResultado(vec3<f32>(0.0), 1.0, 0.0, vec3<f32>(0.0));
    var impacto = 1e30;
    if a.con_nubes {
        var inicio = array<f32, 3>(1e30, 1e30, 1e30);
        var fin = array<f32, 3>(0.0, 0.0, 0.0);
        for (var i = 0; i < 3; i++) {
            if a.nubes.perfil.cobertura[i] > 0.0 {
                let y0 = VOL_MAR + VOL_BASE[i];
                let l = vol_losa(rayo.camara.y, rayo.dir.y, y0, y0 + VOL_ESPESOR[i]);
                if l.y > l.x {
                    inicio[i] = l.x;
                    fin[i] = min(l.y, rayo.escena);
                }
            }
        }
        var hecho = array<bool, 3>(false, false, false);
        for (var k = 0; k < 3; k++) {
            var elegido = -1;
            var menor = 1e29;
            for (var j = 0; j < 3; j++) {
                if !hecho[j] && inicio[j] < menor {
                    menor = inicio[j];
                    elegido = j;
                }
            }
            if elegido < 0 || nubes.transmitancia < 0.01 {
                break;
            }
            hecho[elegido] = true;
            if fin[elegido] > inicio[elegido] {
                vol_tramo_nubes(&nubes, &impacto, elegido, inicio[elegido], fin[elegido], rayo, luz, a, t2, s2, t3);
            }
        }
    }
    var r = VolResultado(vec3<f32>(0.0), 1.0, 0.0, vec3<f32>(0.0));
    if a.con_niebla {
        let hasta = min(min(rayo.escena, a.alcance), impacto);
        if hasta > 0.0 {
            vol_tramo_niebla(&r, 0.0, hasta, rayo, luz, a, mapa, comparacion, t2, s2, t3, ta, sa);
        }
    }
    r.luz += r.transmitancia * nubes.luz;
    r.transmitancia *= nubes.transmitancia;
    if a.aurora.activa {
        r.luz += vol_aurora_ventana(rayo.camara, rayo.dir, r.ventana, r.color_ventana, a.aurora, ta, sa);
    }
    return r;
}
