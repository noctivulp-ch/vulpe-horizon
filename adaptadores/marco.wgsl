// Lo que todas las etapas leen de `frame`, traducido a magnitudes del núcleo.
// Porqué: docs/efectos/nucleo.md §Adaptadores

struct AdpTiempo {
    segundos: f32,          // desde que cargó el pack (vuelve a 0 cada hora)
    hora_del_dia: f32,      // 0 amanecer, 0,25 mediodía, 0,5 atardecer, 0,75 medianoche
}

fn adp_tiempo() -> AdpTiempo {
    return AdpTiempo(frame.time, frame.day_time);
}

fn adp_es_superficie() -> bool {
    return frame.dimension == 0;
}

// 1 con el sol alto en la superficie, 0 de noche o en otras dimensiones.
fn adp_factor_dia() -> f32 {
    return select(0.0, smoothstep(-0.1, 0.1, frame.sun_direction.y), adp_es_superficie());
}
