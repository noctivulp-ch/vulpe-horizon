// El tiempo atmosférico: perfiles de nubes del día y horario de la niebla. Porqué: docs/efectos/niebla-y-nubes.md §Tiempo

struct VolPerfil {
    cobertura: vec3<f32>,   // cúmulos pequeños, cúmulos grandes, altoestratos (parámetro del perfil)
    densidad: vec3<f32>,
}

// Los once perfiles del sorteo diario medidos en los vectores de paridad (paridad/05 §Tiempo diario).
const VOL_SECUENCIA_PERFILES: array<u32, 18> = array<u32, 18>(
    1u, 2u, 3u, 4u, 5u, 6u, 1u, 7u, 8u, 6u, 1u, 4u, 1u, 4u, 9u, 10u, 8u, 0u,
);

fn vol_perfil(i: u32) -> VolPerfil {
    switch i {
        case 1u: { return VolPerfil(vec3<f32>(1.0, 0.0, 0.0), vec3<f32>(0.5, 0.0, 0.0)); }     // cúmulos pequeños
        case 2u: { return VolPerfil(vec3<f32>(0.0, 1.0, 1.0), vec3<f32>(0.0, 0.5, 0.5)); }     // grandes y altoestratos
        case 3u: { return VolPerfil(vec3<f32>(0.0, 0.0, 2.0), vec3<f32>(0.0, 0.0, 0.3)); }     // altoestratos cubiertos
        case 4u: { return VolPerfil(vec3<f32>(0.0, 1.9, 0.0), vec3<f32>(0.0, 0.2, 0.0)); }     // grandes extendidos
        case 5u: { return VolPerfil(vec3<f32>(1.0, 0.1, 1.0), vec3<f32>(0.5, 0.5, 0.1)); }     // pequeños y altoestratos
        case 6u: { return VolPerfil(vec3<f32>(0.0, 1.1, 0.0), vec3<f32>(0.0, 0.5, 0.0)); }     // solo cúmulos grandes
        case 7u: { return VolPerfil(vec3<f32>(1.0, 0.0, 1.5), vec3<f32>(0.1, 0.1, 0.25)); }    // pequeños tenues y altoestratos
        case 8u: { return VolPerfil(vec3<f32>(0.0, 0.0, 1.0), vec3<f32>(0.0, 0.0, 0.5)); }     // solo altoestratos
        case 9u: { return VolPerfil(vec3<f32>(1.4, 0.0, 0.0), vec3<f32>(0.5, 0.0, 0.0)); }     // pequeños abundantes
        case 10u: { return VolPerfil(vec3<f32>(1.0, 1.0, 0.0), vec3<f32>(0.25, 0.5, 0.0)); }   // pequeños y grandes
        default: { return VolPerfil(vec3<f32>(0.0), vec3<f32>(0.0)); }                         // despejado
    }
}

fn vol_indice_perfil(paso: u32) -> u32 {
    if paso < 18u {
        return VOL_SECUENCIA_PERFILES[paso];
    }
    return VOL_SECUENCIA_PERFILES[4u + (paso - 4u) % 14u];
}

// Perfiles de lluvia por día (paridad/05 §Con lluvia), modulados por la intensidad.
fn vol_perfil_lluvia(dia: u32, lluvia: f32) -> VolPerfil {
    var c = vec3<f32>(1.5, 1.5, 1.3);
    var d = vec3<f32>(0.25, 0.25, 0.5);
    switch dia & 3u {
        case 0u: {
            c = vec3<f32>(0.0, 1.5, 1.5);
            d = vec3<f32>(0.0, 0.25, 0.5);
        }
        case 1u: {
            c = vec3<f32>(0.0, 1.8, 0.0);
            d = vec3<f32>(0.25 * f32((dia >> 2u) & 1u), 0.1, 0.3 * f32(1u - ((dia >> 2u) & 1u)));
        }
        default: {}
    }
    let escala = mix(0.75, 1.0, lluvia);
    return VolPerfil(c * escala, d);
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
fn vol_perfil_del_momento(m: VolMomento) -> VolPerfil {
    var base = vol_perfil(m.perfil_fijo);
    let dia_u = u32(max(m.dia, 0.0));
    if m.aleatorio {
        let s = max(m.fraccion * 4.0 - 0.5, 0.0);
        let cuarto = u32(floor(s));
        let t = fract(s);
        let a = vol_indice_perfil(dia_u + cuarto);
        let b = vol_indice_perfil(dia_u + cuarto + 1u);
        base = vol_mezclar_perfil(vol_perfil(a), vol_perfil(b), smoothstep(0.2, 0.8, t));
    }
    return vol_mezclar_perfil(base, vol_perfil_lluvia(dia_u, m.lluvia), smoothstep(0.0, 0.6, m.lluvia));
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
    let uniforme = amanecer * 0.06 + atardecer * 0.1 + noche * 0.38;
    let manchas = amanecer * 0.5 + noche * 0.15;
    return VolHorario(uniforme, manchas);
}
