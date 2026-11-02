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

// 1 de noche cerrada, 0 de día (convenciones: aparece con el sol bajando del horizonte).
fn adp_factor_noche() -> f32 {
    return clamp(-frame.sun_direction.y * 2.0, 0.0, 1.0);
}

// La misma en todas las etapas: es la clave de la codificación del «picture» (ADR 0004).
fn adp_codificacion() -> ColCodificacion {
    let e = col_exposicion_previa(ColParametrosExposicion(frame.sun_direction.y, OPC_EV_DIA, OPC_EV_NOCHE));
    return ColCodificacion(e, OPC_BLANCO);
}
