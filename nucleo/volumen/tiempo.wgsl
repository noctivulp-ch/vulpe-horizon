// El tiempo atmosférico: perfiles de nubes del día y horario de la niebla. Porqué: docs/efectos/niebla-y-nubes.md §Tiempo

struct VolPerfil {
    cobertura: vec3<f32>,   // cúmulos pequeños, cúmulos grandes, altoestratos (parámetro del perfil)
    densidad: vec3<f32>,
}

// Qué perfiles toca mezclar en un momento: los índices en la tabla de perfiles y el peso del segundo.
struct VolSorteo {
    a: u32,
    b: u32,
    t: f32,
}

fn vol_indice_perfil(paso: u32, secuencia: array<u32, 18>, repite_desde: u32) -> u32 {
    if paso < 18u {
        return secuencia[paso];
    }
    let n = 18u - repite_desde;
    return secuencia[repite_desde + (paso - repite_desde) % n];
}

struct VolLluviaPerfil {
    nubes: VolPerfil,
    niebla_uniforme: f32,
    niebla_manchas: f32,
}

// Perfiles de lluvia por día (paridad/05 §Con lluvia, días 0–7)
fn vol_perfil_lluvia(dia: u32, lluvia: f32) -> VolLluviaPerfil {
    var c = vec3<f32>(0.0, 1.5, 1.5);
    var d = vec3<f32>(0.0, 0.25, 0.5);
    var unif: f32 = 0.2;
    var manchas: f32 = 0.4;

    switch dia % 8u {
        case 0u: {
            c = vec3<f32>(0.0, 1.5, 1.5);
            d = vec3<f32>(0.0, 0.25, 0.5);
            unif = 0.2;
            manchas = 0.4;
        }
        case 1u: {
            c = vec3<f32>(0.0, 1.8, 0.0);
            d = vec3<f32>(0.0, 0.1, 0.3);
            unif = 0.1;
            manchas = 0.2;
        }
        case 2u: {
            c = vec3<f32>(1.5, 1.5, 1.3);
            d = vec3<f32>(0.25, 0.25, 0.5);
            unif = 0.1;
            manchas = 0.2;
        }
        case 3u: {
            c = vec3<f32>(1.5, 1.5, 1.3);
            d = vec3<f32>(0.25, 0.25, 0.5);
            unif = 0.3;
            manchas = 0.2;
        }
        case 4u: {
            c = vec3<f32>(0.0, 1.5, 1.5);
            d = vec3<f32>(0.0, 0.25, 0.5);
            unif = 0.2;
            manchas = 0.4;
        }
        case 5u: {
            c = vec3<f32>(0.0, 1.8, 0.0);
            d = vec3<f32>(0.5, 0.1, 0.0);
            unif = 0.1;
            manchas = 0.2;
        }
        case 6u: {
            c = vec3<f32>(1.5, 1.5, 1.3);
            d = vec3<f32>(0.25, 0.25, 0.5);
            unif = 0.3;
            manchas = 0.2;
        }
        case 7u: {
            c = vec3<f32>(1.5, 1.5, 1.3);
            d = vec3<f32>(0.25, 0.25, 0.5);
            unif = 0.1;
            manchas = 0.2;
        }
        default: {}
    }
    let escala = mix(0.75, 1.0, lluvia);
    return VolLluviaPerfil(VolPerfil(c * escala, d), unif, manchas);
}

fn vol_mezclar_perfil(a: VolPerfil, b: VolPerfil, t: f32) -> VolPerfil {
    return VolPerfil(mix(a.cobertura, b.cobertura, t), mix(a.densidad, b.densidad, t));
}

struct VolMomento {
    dia: f32,           // número de día (0 sin mod nativo)
    fraccion: f32,      // 0..1 desde el amanecer
    lluvia: f32,
    aleatorio: bool,    // tiempo diario aleatorio; si no, perfil fijo
    perfil_fijo: u32,
}

// Cuatro sorteos por día centrados en 3000, 9000, 15000 y 21000 (fracción 0,125; 0,375; 0,625 y 0,875).
fn vol_sorteo(m: VolMomento, secuencia: array<u32, 18>, repite_desde: u32, fundido: vec2<f32>) -> VolSorteo {
    if !m.aleatorio {
        return VolSorteo(m.perfil_fijo, m.perfil_fijo, 0.0);
    }
    let dia_u = u32(max(m.dia, 0.0));
    let s = max(m.fraccion * 4.0 - 0.5, 0.0);
    let cuarto = u32(floor(s));
    let a = vol_indice_perfil(dia_u + cuarto, secuencia, repite_desde);
    let b = vol_indice_perfil(dia_u + cuarto + 1u, secuencia, repite_desde);
    return VolSorteo(a, b, smoothstep(fundido.x, fundido.y, fract(s)));
}

// El perfil del momento a partir de los dos perfiles sorteados, con la lluvia.
fn vol_perfil_del_momento(m: VolMomento, pa: VolPerfil, pb: VolPerfil, t: f32) -> VolPerfil {
    let base = vol_mezclar_perfil(pa, pb, t);
    let pl = vol_perfil_lluvia(u32(max(m.dia, 0.0)), m.lluvia);
    return vol_mezclar_perfil(base, pl.nubes, smoothstep(0.0, 0.6, m.lluvia));
}

struct VolHorario {
    uniforme: f32,      // densidad relativa de la niebla uniforme
    manchas: f32,       // y de la niebla en manchas
}

// Densidades relativas por hora (especificación 05 §3), por franjas: amanecer, mediodía, atardecer y noche (x, y, z, w
// de `uniforme` y `manchas`), con transiciones de `transicion` (fracción del día).
fn vol_horario(fraccion: f32, uniforme: vec4<f32>, manchas: vec4<f32>, transicion: f32) -> VolHorario {
    let f = fract(fraccion);
    let amanecer = 1.0 - smoothstep(0.0, transicion, min(f, 1.0 - f));
    let atardecer = 1.0 - smoothstep(0.0, transicion, abs(f - 0.5));
    let noche = smoothstep(0.5, 0.5 + transicion * 1.25, f) * (1.0 - smoothstep(1.0 - transicion, 1.0, f));
    let mediodia = max(1.0 - amanecer - atardecer - noche, 0.0) * (1.0 - smoothstep(0.5, 0.6, f));
    let pesos = vec4<f32>(amanecer, mediodia, atardecer, noche);
    return VolHorario(dot(pesos, uniforme), dot(pesos, manchas));
}
