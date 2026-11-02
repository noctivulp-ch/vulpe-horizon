// Exposición previa analítica: la que comparten todas las etapas para codificar la escena.
// Porqué: docs/efectos/cielo-y-atmosfera.md §Exposición previa

struct ColParametrosExposicion {
    seno_sol: f32,          // frame.sun_direction.y
    ev_dia: f32,            // log2 de la exposición con el sol alto
    ev_noche: f32,          // log2 de la exposición de noche
}

// Interpola en EV (en log), no en exposición lineal: el paso por el atardecer queda parejo.
fn col_exposicion_previa(p: ColParametrosExposicion) -> f32 {
    let dia = smoothstep(-0.2, 0.15, p.seno_sol);
    return exp2(mix(p.ev_noche, p.ev_dia, dia));
}
