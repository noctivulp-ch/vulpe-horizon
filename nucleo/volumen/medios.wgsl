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
fn vol_niebla(mundo: vec3<f32>, a: VolAjustesNiebla, ruido3d: texture_2d<f32>) -> f32 {
    var d = a.uniforme;
    if a.manchas > 0.0 {
        let p = (mundo + a.viento) * vec3<f32>(1.0 / 96.0, 1.0 / 40.0, 1.0 / 96.0);
        let n = vol_ruido3d(ruido3d, p).a;
        let mancha = smoothstep(0.45, 0.7, n) * exp(-max(mundo.y - VOL_MAR - VOL_MANCHAS_ALTURA, 0.0) / 12.0);
        d += a.manchas * mancha * 2.0;
    }
    d *= exp(-max(mundo.y - VOL_CAIDA_DESDE, 0.0) * a.caida);
    return d * a.cantidad * VOL_NIEBLA_SIGMA;
}

// Densidad 0..1 de la capa de nubes `i` en `mundo`: cobertura 2D × perfil vertical, erosionada en los bordes.
// `erosion`: falso en las muestras de luz hacia el astro (solo cobertura y forma: la especificación lo prevé
// para el presupuesto).
fn vol_nube(mundo: vec3<f32>, i: i32, n: VolNubes, t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>, erosion: bool) -> f32 {
    let h = (mundo.y - VOL_MAR - VOL_BASE[i]) / VOL_ESPESOR[i];
    if h < 0.0 || h > 1.0 {
        return 0.0;
    }
    // Los cúmulos se inclinan algo con el viento al subir: un 20 % de su espesor en la dirección del viento.
    // (Con el desplazamiento acumulado en vez de la dirección, la inclinación crecía con el tiempo y salían
    // lágrimas tumbadas.)
    let inclinado = mundo.xz + n.direccion * (h * VOL_ESPESOR[i] * 0.2);
    let cob = vol_cobertura(inclinado, i, n, t2, s2);
    if cob <= 0.0 {
        return 0.0;
    }
    if i == 2 {
        return cob * smoothstep(0.0, 0.3, h) * (1.0 - smoothstep(0.7, 1.0, h));
    }
    // Gradiente de altura: base plana redondeada en los primeros ~25 bloques, techo en cúpula. La cobertura
    // se recorta con él (Schneider y Vos 2015): donde hay mucha cobertura la nube es alta; en el borde solo
    // queda una franja baja. Así salen cúpulas y no columnas de paredes rectas.
    let base = smoothstep(0.0, 25.0 / VOL_ESPESOR[i], h);
    let techo = 1.0 - smoothstep(0.55, 1.0, h);
    let gradiente = base * techo;
    var d = clamp((cob - (1.0 - gradiente)) / max(gradiente, 0.05), 0.0, 1.0);
    // Erosión con ruido 3D de dos frecuencias, más fuerte en los bordes (donde d es baja).
    if erosion && d > 0.0 {
        let p = vec3<f32>(inclinado.x, mundo.y, inclinado.y) / 220.0;
        let r = vol_ruido3d(t3, p);
        let e = r.r * 0.6 + r.g * 0.3 + r.b * 0.1;
        d = clamp((d - (1.0 - e) * 0.55 * (1.0 - d)) / max(1.0 - 0.3 * (1.0 - e), 0.3), 0.0, 1.0);
    }
    return d * n.perfil.densidad[i];
}
