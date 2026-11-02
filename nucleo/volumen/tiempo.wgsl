// El tiempo atmosférico: perfiles de nubes del día y horario de la niebla. Porqué: docs/efectos/niebla-y-nubes.md §Tiempo

struct VolPerfil {
    cobertura: vec3<f32>,   // cúmulos pequeños, cúmulos grandes, altoestratos (0..1)
    densidad: vec3<f32>,
}

fn vol_perfil(i: u32) -> VolPerfil {
    var c = vec3<f32>(0.0);
    switch i {
        case 1u: { c = vec3<f32>(0.45, 0.0, 0.0); }     // cúmulos pequeños
        case 2u: { c = vec3<f32>(0.0, 0.45, 0.0); }     // cúmulos grandes
        case 3u: { c = vec3<f32>(0.35, 0.35, 0.0); }    // pequeños y grandes
        case 4u: { c = vec3<f32>(0.0, 0.0, 0.7); }      // altoestratos
        case 5u: { c = vec3<f32>(0.35, 0.0, 0.6); }     // altoestratos y cúmulos
        case 6u: { c = vec3<f32>(0.0, 0.6, 0.0); }      // solo grandes, densos
        case 7u: { c = vec3<f32>(0.25, 0.0, 0.0); }     // pequeños dispersos
        case 8u: { c = vec3<f32>(0.0, 0.0, 0.4); }      // altoestratos finos
        case 9u: { c = vec3<f32>(0.3, 0.25, 0.4); }     // mixto
        case 10u: { c = vec3<f32>(0.55, 0.5, 0.5); }    // nublado
        default: {}                                     // despejado
    }
    return VolPerfil(c, vec3<f32>(1.0));
}

// Perfiles de lluvia (ligera, media, fuerte) según la intensidad.
fn vol_perfil_lluvia(lluvia: f32) -> VolPerfil {
    let c = mix(vec3<f32>(0.65, 0.6, 0.7), vec3<f32>(0.95, 0.9, 0.9), lluvia);
    return VolPerfil(c, vec3<f32>(mix(1.3, 1.8, lluvia)));
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

// Se sortea un perfil por cuarto de día con un hash del día; se funde con el siguiente al final del cuarto.
fn vol_perfil_del_momento(m: VolMomento) -> VolPerfil {
    var base = vol_perfil(m.perfil_fijo);
    if m.aleatorio {
        let cuarto = floor(m.fraccion * 4.0);
        let t = fract(m.fraccion * 4.0);
        let a = rui_pcg(u32(m.dia) * 4u + u32(cuarto)) % 11u;
        let b = rui_pcg(u32(m.dia) * 4u + u32(cuarto) + 1u) % 11u;
        base = vol_mezclar_perfil(vol_perfil(a), vol_perfil(b), smoothstep(0.8, 1.0, t));
    }
    return vol_mezclar_perfil(base, vol_perfil_lluvia(m.lluvia), smoothstep(0.0, 0.6, m.lluvia));
}

struct VolHorario {
    uniforme: f32,      // densidad relativa de la niebla uniforme
    manchas: f32,       // y de la niebla en manchas
}

// Densidades relativas por hora (especificación 05 §3): jirones al amanecer, nada a mediodía, bruma al
// atardecer, niebla densa de noche. Transiciones de ~0,08 de día.
fn vol_horario(fraccion: f32) -> VolHorario {
    let f = fract(fraccion);
    let amanecer = 1.0 - smoothstep(0.0, 0.08, min(f, 1.0 - f) - 0.0);
    let atardecer = 1.0 - smoothstep(0.0, 0.08, abs(f - 0.5));
    let noche = smoothstep(0.5, 0.6, f) * (1.0 - smoothstep(0.92, 1.0, f));
    let uniforme = amanecer * 0.06 + atardecer * 0.1 + noche * 0.45;
    let manchas = amanecer * 0.5 + noche * 0.15;
    return VolHorario(uniforme, manchas);
}
