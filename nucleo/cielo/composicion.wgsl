// Montaje del cielo: el suelo bajo el horizonte y el velo de la lluvia. Porqué: docs/efectos/cielo-y-atmosfera.md §Montaje

// 1 sobre el horizonte, cae como una gaussiana a 0 en unos pocos grados por debajo (sin escalón).
fn cie_factor_suelo(dir_y: f32, anchura: f32) -> f32 {
    let bajo = min(dir_y, 0.0) / anchura;
    return exp(-bajo * bajo);
}

struct CieLluvia {
    lluvia: f32,            // 0..1
    tormenta: f32,          // 0..1
    cielo_medio: vec3<f32>, // radiancia media del cielo despejado
}

// Cuánto de bruma (y no de suelo) hay en una dirección bajo el horizonte: 1 cerca de él, 0 mirando hacia abajo
// más de unos 30°. Lo comparten el cielo bajo el horizonte y la niebla de borde, para que casen.
fn cie_peso_bruma_horizonte(dir_y: f32) -> f32 {
    return 1.0 - smoothstep(0.15, 0.5, max(-dir_y, 0.0));
}

// Color del «suelo» que se ve bajo el horizonte más allá del terreno: oscuro y teñido del cielo, no el
// suelo iluminado de la tabla (que sale casi blanco con la exposición del día).
fn cie_color_bajo_horizonte(cielo_medio: vec3<f32>, suelo: vec3<f32>, oscuridad: f32) -> vec3<f32> {
    return mix(suelo, cielo_medio, 0.6) * oscuridad;
}

// Mezcla el cielo hacia un gris uniforme del color medio, más cerca del horizonte.
fn cie_aplicar_lluvia(cielo: vec3<f32>, dir_y: f32, l: CieLluvia) -> vec3<f32> {
    let gris = mix(vec3<f32>(col_luminancia(l.cielo_medio)), l.cielo_medio, 0.35) * 1.1 * (1.0 - 0.6 * l.tormenta);
    let peso = l.lluvia * mix(0.75, 1.0, exp(-max(dir_y, 0.0) * 4.0));
    return mix(cielo, gris, peso);
}
