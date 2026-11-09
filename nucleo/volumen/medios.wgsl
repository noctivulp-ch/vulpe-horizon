// Los medios del volumen: aire, niebla global y nubes. Porqué: docs/efectos/niebla-y-nubes.md §Medios

struct VolAjustesNiebla {
    uniforme: f32,          // densidad relativa por hora × tiempo
    manchas: f32,
    cantidad: f32,          // multiplicador global (opción)
    bruma: f32,             // multiplicador del aire (opción)
    caida: f32,             // por bloque, por encima de VOL_CAIDA_DESDE
    viento: vec3<f32>,      // desplazamiento de las manchas, bloques
    ambiente: f32,          // multiplicador de la luz ambiente dispersada (>1 en la tormenta de nieve: blanca)
}

// Perspectiva aérea a escala de Minecraft: Rayleigh y Mie con alturas de escala cortas.
const VOL_AIRE_RAYLEIGH: vec3<f32> = vec3<f32>(0.5e-4, 1.2e-4, 2.9e-4);    // por bloque, al nivel del mar
const VOL_AIRE_MIE: f32 = 1.0e-4;
const VOL_AIRE_ALTURA: f32 = 600.0;
const VOL_NIEBLA_SIGMA: f32 = 0.02;        // por bloque con densidad relativa 1
const VOL_CAIDA_DESDE: f32 = 320.0;         // por encima del velo de la aurora (decisión de Vulpe)
const VOL_MANCHAS_ALTURA: f32 = 24.0;       // las manchas son bruma baja: caen por encima del mar + esto

struct VolAire {
    rayleigh: vec3<f32>,
    mie: f32,
}

fn vol_aire(y: f32, bruma: f32) -> VolAire {
    let d = exp(-max(y - VOL_MAR, 0.0) / VOL_AIRE_ALTURA) * bruma;
    return VolAire(VOL_AIRE_RAYLEIGH * d, VOL_AIRE_MIE * d);
}

// Coeficiente de extinción de la niebla global (por bloque) en `mundo`.
// La densidad efectiva es el cubo del parámetro horario/climático (paridad/05 y fino/05 §1, §4).
fn vol_niebla(mundo: vec3<f32>, a: VolAjustesNiebla, ruido3d: texture_2d<f32>) -> f32 {
    var d = a.uniforme * a.uniforme * a.uniforme;
    if a.manchas > 0.0 {
        let p = (mundo + a.viento) * vec3<f32>(1.0 / 96.0, 1.0 / 40.0, 1.0 / 96.0);
        let n = vol_ruido3d(ruido3d, p).a;
        let mancha = smoothstep(0.45, 0.7, n) * exp(-max(mundo.y - VOL_MAR - VOL_MANCHAS_ALTURA, 0.0) / 12.0);
        let d_manchas = a.manchas * a.manchas * a.manchas;
        d += d_manchas * mancha * 2.0;
    }
    d *= exp(-max(mundo.y - VOL_CAIDA_DESDE, 0.0) * a.caida);
    return d * a.cantidad;
}

// `remap(v, bajo, 1)`: lo que queda por encima de `bajo`, reescalado a 0..1.
fn vol_remapear(v: f32, bajo: f32) -> f32 {
    return clamp((v - bajo) / max(1.0 - bajo, 1e-3), 0.0, 1.0);
}

// Densidad 0..1 de la capa de nubes `i` en `mundo`: cobertura 2D × perfil vertical, erosionada en los bordes.
// `erosion`: falso en las muestras de luz hacia el astro (solo cobertura y forma: la especificación lo prevé
// para el presupuesto).
fn vol_nube(mundo: vec3<f32>, i: i32, n: VolNubes, t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>, erosion: bool) -> f32 {
    let dy = mundo.y - (VOL_MAR + VOL_BASE[i]);
    let h = dy / VOL_ESPESOR[i];
    if h <= 0.0 || h >= 1.0 {
        return 0.0;
    }
    let inclinado = mundo.xz + n.direccion * (h * VOL_ESPESOR[i] * n.forma.inclinacion);
    let cob = vol_cobertura(inclinado, i, n, t2, s2);
    if cob <= 0.0 {
        return 0.0;
    }
    if i == 2 {
        return cob * smoothstep(0.0, 0.3, h) * (1.0 - smoothstep(0.7, 1.0, h)) * n.perfil.densidad[i];
    }
    // El techo de cada cúmulo escala con su cobertura horizontal `cob` (cúpula sobre base plana); con `cob = 1`
    // reproduce la envolvente vertical de paridad/05 §Perfil vertical de los cúmulos.
    if h >= cob {
        return 0.0;
    }
    let h_c = h / max(cob, 1e-3);
    let base = 1.0 - pow(clamp(1.0 - dy / max(n.forma.base_redondeo * cob, 1.0), 0.0, 1.0), 5.0);
    let u_techo = clamp((h_c - n.forma.cupula_desde) / max(1.0 - n.forma.cupula_desde, 1e-3), 0.0, 1.0);
    let techo = 1.0 - pow(u_techo, n.forma.cupula_potencia);
    var d = cob * base * exp(-n.forma.caida_altura * h) * techo;
    if erosion && d > 0.0 {
        // Erosión de Schneider y Vos (2015): `remap(d, ruido · fuerza, 1)` recorta el borde de la envolvente y deja un
        // borde nítido. Dos frecuencias: la gruesa (Perlin-Worley) hace los lóbulos; la fina (Worley), las coliflores
        // arriba y los jirones abajo. En la base, menos (que siga plana). Porqué: docs/efectos/niebla-y-nubes.md §Erosión
        let q = vec3<f32>(inclinado.x, mundo.y, inclinado.y);
        let gruesa = vol_ruido3d(t3, q / n.forma.escala_erosion[i]).r;
        let en_base = mix(n.forma.erosion_base, 1.0, smoothstep(0.0, 0.2, h_c));
        d = vol_remapear(d, (1.0 - gruesa) * n.forma.erosion_fuerza * en_base);
        if d > 0.0 {
            let r = vol_ruido3d(t3, q / n.forma.escala_detalle);
            let fina = r.g * 0.625 + r.b * 0.25 + r.a * 0.125;
            let billow = mix(fina, 1.0 - fina, smoothstep(0.1, 0.6, h_c));
            d = vol_remapear(d, billow * n.forma.detalle_fuerza * en_base);
        }
    }
    return d * n.perfil.densidad[i];
}
