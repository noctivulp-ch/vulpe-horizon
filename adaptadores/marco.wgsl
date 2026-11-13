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
    return select(0.0, clamp(-frame.sun_direction.y * 2.0, 0.0, 1.0), adp_es_superficie());
}

// La misma en todas las etapas: es la clave de la codificación del «picture» (ADR 0004).
fn adp_codificacion() -> ColCodificacion {
    let p = ColParametrosExposicion(frame.sun_direction.y, frame.eye_light_smooth.y, OPC_EV_DIA, OPC_EV_NOCHE, OPC_EV_INTERIOR);
    var e = col_exposicion_previa(p);
    // Fuera del Overworld no hay sol: un valor fijo por dimensión (17); la automática corrige.
    if frame.dimension == -1 {
        e = exp2(OPC_EV_NETHER);
    } else if frame.dimension != 0 {
        e = exp2(OPC_EV_END);
    }
    return ColCodificacion(e, OPC_BLANCO);
}

// Detector de cueva (23 §1), compartido por la niebla de cueva y la de borde: sin luz de cielo en la cámara (menos del
// 1 %), con el suavizado de Horizon (vida media de 2 s). El «ánimo de cueva» de vanilla no está en `Frame`.
fn adp_detector_cueva() -> f32 {
    return 1.0 - smoothstep(OPC_CUEVA_DETECTOR.x, OPC_CUEVA_DETECTOR.y, frame.eye_light_smooth.y);
}

// Clima local (21): tormenta de calor (bioma caliente sin precipitación) o de frío (bioma frío con nieve), con la fuerza
// de la lluvia. Su tipo y su peso se guardan entre fotogramas en el téxel (6,0) de bloom2 como `tipo·2 + peso`, y los dos
// pasan por el mismo fundido: da igual entrar con lluvia o que empiece a llover dentro (observaciones del dueño 1.1 y
// 1.2). Porqué: docs/efectos/niebla-local.md §«Fundido del clima (F-43)»
struct AdpClimaLocal {
    tipo: u32,      // 0 ninguno, 1 calor, 2 frío
    peso: f32,      // 0..1, ya fundido
}

fn adp_clima_local_objetivo() -> AdpClimaLocal {
    var tipo = 0u;
    if frame.temperature > OPC_LOCAL_CALOR && frame.precipitation == 0u {
        tipo = 1u;
    } else if frame.temperature < OPC_LOCAL_FRIO && frame.precipitation == 2u {
        tipo = 2u;
    }
    return AdpClimaLocal(tipo, select(0.0, frame.rain, tipo > 0u));
}

fn adp_clima_local_decodificar(v: f32) -> AdpClimaLocal {
    let tipo = u32(clamp(floor(max(v, 0.0) / 2.0), 0.0, 2.0));
    return AdpClimaLocal(tipo, clamp(v - f32(tipo) * 2.0, 0.0, 1.0));
}

// El estado de este fotograma a partir del anterior: si el tipo cambia, primero se apaga el anterior.
fn adp_clima_local_estado(anterior: f32) -> f32 {
    var c = adp_clima_local_decodificar(anterior);
    let objetivo = adp_clima_local_objetivo();
    let paso = frame.delta_time / OPC_LOCAL_FUNDIDO;
    if c.tipo == objetivo.tipo || c.peso <= 0.0 {
        c.tipo = objetivo.tipo;
        let d = objetivo.peso - c.peso;
        c.peso += clamp(d, -paso, paso);
    } else {
        c.peso = max(c.peso - paso, 0.0);
    }
    return f32(c.tipo) * 2.0 + c.peso;
}
