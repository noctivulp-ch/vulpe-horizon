// Exposición previa analítica: la que comparten todas las etapas para codificar la escena.
// Porqué: docs/efectos/cielo-y-atmosfera.md §Exposición previa

struct ColParametrosExposicion {
    seno_sol: f32,          // frame.sun_direction.y
    cielo_en_el_ojo: f32,   // luz de cielo en la cámara, suavizada (0 en una cueva)
    ev_dia: f32,            // log2 de la exposición con el sol alto
    ev_noche: f32,          // log2 de la exposición de noche
    ev_interior: f32,       // log2 de la exposición sin cielo a la vista
}

// Interpola en EV (en log), no en exposición lineal: el paso por el atardecer queda parejo. Dentro de una
// cueva manda la exposición de interior, que sigue a la luz de cielo en la cámara.
fn col_exposicion_previa(p: ColParametrosExposicion) -> f32 {
    let dia = smoothstep(-0.2, 0.15, p.seno_sol);
    let fuera = mix(p.ev_noche, p.ev_dia, dia);
    let afuera = smoothstep(0.2, 0.9, p.cielo_en_el_ojo);
    return exp2(mix(max(p.ev_interior, fuera), fuera, afuera));
}
