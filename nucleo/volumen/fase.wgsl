// Fase de la niebla y las nubes: varios lóbulos de Henyey-Greenstein con el efecto «powder».
// Porqué: docs/efectos/niebla-y-nubes.md §Fase

fn vol_hg(c: f32, g: f32) -> f32 {
    let g2 = g * g;
    let den = max(1.0 + g2 - 2.0 * g * c, 1e-4);
    return (1.0 - g2) / (4.0 * MAT_PI * den * sqrt(den));
}

// Fase total de la niebla y las nubes medida en el original (fino/05 §Medidos, «Factor de dispersión múltiple y fase
// total por densidad local»): 9 densidades (extinción por bloque, 0,001..0,5) × 7 ángulos (0, 10, 30, 60, 90, 150,
// 180°). Es el factor que multiplica la irradiancia directa del astro, lóbulo trasero incluido. Con densidad baja el
// halo frontal vale 20 y de lado 0,17; con 0,5 por bloque se vuelve casi isótropa (1,2) con más luz de espaldas (2,6).
// Interpolación lineal en el ángulo y en log de la densidad. Porqué: docs/efectos/niebla-y-nubes.md §Fase medida (F-6)
const VOL_FASE_ANGULOS = array<f32, 7>(0.0, 10.0, 30.0, 60.0, 90.0, 150.0, 180.0);
const VOL_FASE_LOG_DENSIDAD = array<f32, 9>(-3.0, -2.699, -2.301, -2.0, -1.699, -1.301, -1.0, -0.699, -0.301);
const VOL_FASE_TABLA = array<f32, 63>(
    20.03, 9.982, 1.437, 0.3193, 0.1695, 0.1718, 0.1899,   // 0,001
    19.99, 9.965, 1.438, 0.3206, 0.1708, 0.174, 0.1924,    // 0,002
    19.87, 9.915, 1.439, 0.3247, 0.1749, 0.1808, 0.2003,   // 0,005
    19.67, 9.827, 1.442, 0.3319, 0.1821, 0.1927, 0.214,    // 0,01
    19.23, 9.637, 1.447, 0.3475, 0.1978, 0.2186, 0.2439,   // 0,02
    17.64, 8.952, 1.465, 0.4041, 0.2557, 0.315, 0.3551,    // 0,05
    14.15, 7.435, 1.494, 0.5325, 0.3927, 0.5457, 0.6214,   // 0,1
    5.795, 3.656, 1.461, 0.8823, 0.8228, 1.296, 1.486,     // 0,2
    1.159, 1.159, 1.159, 1.194, 1.344, 2.262, 2.594,       // 0,5
);

fn vol_fase_fila(fila: i32, grados: f32) -> f32 {
    var j = 0;
    for (var k = 0; k < 5; k++) {
        if grados > VOL_FASE_ANGULOS[k + 1] {
            j = k + 1;
        }
    }
    let a0 = VOL_FASE_ANGULOS[j];
    let a1 = VOL_FASE_ANGULOS[j + 1];
    let t = clamp((grados - a0) / (a1 - a0), 0.0, 1.0);
    return mix(VOL_FASE_TABLA[fila * 7 + j], VOL_FASE_TABLA[fila * 7 + j + 1], t);
}

// `densidad`: extinción local por bloque (niebla: σ del paso; nubes: σ·forma).
fn vol_fase_medida(c: f32, densidad: f32) -> f32 {
    let grados = degrees(acos(clamp(c, -1.0, 1.0)));
    let l = clamp(log(max(densidad, 1e-6)) / log(10.0), VOL_FASE_LOG_DENSIDAD[0], VOL_FASE_LOG_DENSIDAD[8]);
    var i = 0;
    for (var k = 0; k < 7; k++) {
        if l > VOL_FASE_LOG_DENSIDAD[k + 1] {
            i = k + 1;
        }
    }
    let l0 = VOL_FASE_LOG_DENSIDAD[i];
    let l1 = VOL_FASE_LOG_DENSIDAD[i + 1];
    let t = clamp((l - l0) / (l1 - l0), 0.0, 1.0);
    return mix(vol_fase_fila(i, grados), vol_fase_fila(i + 1, grados), t);
}

// Nubes: la tabla con la extinción local de la nube.
fn vol_fase(c: f32, densidad: f32) -> f32 {
    return vol_fase_medida(c, densidad);
}

// Niebla: la misma tabla (fino/05 §2: «la misma función de fase sirve para la niebla y para las nubes»).
fn vol_fase_niebla(c: f32, densidad: f32) -> f32 {
    return vol_fase_medida(c, densidad);
}

// Fase de aerosoles del aire (Mie): tres lóbulos ajustados a la tabla «Halo solar de la perspectiva aérea» de fino/05
// (se aplica dos veces a la luz del sol: como fase de los aerosoles y como «fase solar directa»; F-5).
// Porqué: docs/efectos/niebla-y-nubes.md §Perspectiva aérea (F-5)
fn vol_fase_aire_mie(c: f32) -> f32 {
    return vol_hg(c, 0.9) * 0.5 + vol_hg(c, 0.55) * 5.0 + vol_hg(c, 0.3) * 1.0;
}

// Fase cenital del ambiente de la niebla (fino/05 §2 y su tabla medida: 0,5 en el nadir, 1,97 a −30°, 2,46 en el
// horizonte, 2,5 hacia arriba): `2,5 − 2·max(−y, 0)²` pasa por los cinco puntos con error < 0,04.
// Porqué: docs/efectos/niebla-y-nubes.md §Ambiente de la niebla (F-3)
fn vol_fase_cenital(dir_y: f32) -> f32 {
    let abajo = max(-dir_y, 0.0);
    return 2.5 - 2.0 * abajo * abajo;
}
