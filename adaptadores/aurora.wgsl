// La aurora desde frame y las opciones: la noche, el suelo de referencia (del mod nativo si lo hay) y el
// mapa. Solo en post. Porqué: docs/efectos/aurora.md §Adaptadores

// Escala de la luz emitida en la escala común: el mapa trae la radiancia del fractal del cielo.
const ADP_AURORA_ESCALA: f32 = 0.5;

// Las vistas de depuración de la aurora van en la opción de depuración del pack.
fn adp_aurora_depuracion() -> u32 {
    switch opc_depuracion().vista {
        case OPC_VISTA_AURORA_CONOS: { return VOL_AURORA_DEPURAR_CONOS; }
        case OPC_VISTA_AURORA_SIN_VENTANA: { return VOL_AURORA_DEPURAR_SIN_VENTANA; }
        default: { return 0u; }
    }
}

fn adp_aurora(alcance: f32) -> VolAurora {
    let o = opc_aurora();
    let ma = opc_estilo_aurora();
    let noche = adp_factor_noche();
    // frame.mods[0].w: altura media del terreno (válida si mods[1].x = 1); si no, la fija.
    let medido = frame.mods[0].x > 0.5 && frame.mods[1].x > 0.5;
    let suelo = select(OPC_AURORA_SUELO, frame.mods[0].w, medido);
    let base = suelo + OPC_AURORA_FIN_VELO * ma.mult_velo;
    let con_mod = frame.mods[0].x > 0.5;
    let dia = select(0.0, floor(frame.mods[0].z), con_mod) + frame.day_time;
    let activa = o.activa && opc_fractal().activo && noche > 0.0 && adp_es_superficie();
    let radio = OPC_AURORA_RADIO * ma.mult_radio;
    let largo = OPC_AURORA_LARGO * ma.mult_largo;
    return VolAurora(activa, noche, min(radio, alcance), base, base + largo,
                     OPC_AURORA_INTENSIDAD * ma.mult_intensidad * ADP_AURORA_ESCALA * o.brillo, dia, adp_aurora_depuracion(), o.muestras);
}

