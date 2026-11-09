// Niebla de cueva (05.3): niebla tenue, azul oscura, que crece con la distancia en cuevas
// y es más fuerte mirando hacia abajo y al frente que mirando hacia arriba.
// Porqué: docs/efectos/niebla-y-nubes.md §Niebla de cueva

struct VolAjustesCueva {
    activa: bool,
    caida: f32,
    mult_luz: f32,
    distancia_escala: f32,
    color: vec3<f32>,
    brillo_max: f32,
}

// Devuelve la luz aditiva de la niebla de cueva en unidades lineales de la escena.
// `distancia`: distancia en bloques al terreno (no aplica en cielo).
// `dir_y`: componente vertical del rayo de vista (-1 abajo, 0 frente, +1 arriba).
// `cueva`: factor 0..1 de cueva (basado en la luz de cielo en la cámara).
fn vol_niebla_cueva(distancia: f32, dir_y: f32, cueva: f32, a: VolAjustesCueva) -> vec3<f32> {
    if !a.activa || cueva <= 1e-3 || a.mult_luz <= 1e-4 {
        return vec3<f32>(0.0);
    }
    // Crece con la distancia según la caída exponencial del preset de cuevas.
    let escala = a.distancia_escala / max(a.caida, 0.1);
    let f_dist = 1.0 - exp(-distancia / escala);
    // Más fuerte mirando hacia abajo y al frente que mirando hacia arriba.
    let f_dir = mix(1.0, 0.25, clamp(dir_y, 0.0, 1.0));
    // Niebla aditiva y débil, nunca más clara que la luz mínima de la cueva.
    let intensidad = a.brillo_max * a.mult_luz * f_dist * f_dir * cueva;
    return a.color * intensidad;
}
