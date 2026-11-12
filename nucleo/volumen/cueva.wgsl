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
fn vol_niebla_cueva(distancia: f32, alcance: f32, dir_y: f32, cueva: f32, a: VolAjustesCueva) -> vec3<f32> {
    if !a.activa || cueva <= 1e-3 || a.mult_luz <= 1e-4 {
        return vec3<f32>(0.0);
    }
    // Tablas de 23 §1: con la fracción de la distancia de renderizado, cuadrática con la caída 1 (0,25 a la mitad);
    // con la vista, vive abajo: 1 mirando a una sima, 0,031 al frente, 0,002 al techo (`e^(−3,4·(1 + y))`, error < 0,01).
    let x = clamp(distancia / max(alcance, 1.0), 0.0, 1.0);
    let f_dist = pow(x, 2.0 * max(a.caida, 0.05));
    let f_dir = exp(-3.4 * (1.0 + clamp(dir_y, -1.0, 1.0)));
    return a.color * (a.brillo_max * a.mult_luz * f_dist * f_dir * cueva);
}
