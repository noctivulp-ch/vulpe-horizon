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
    let m = adp_mod();
    let velo_mod = adp_mod_param(26u, 0.0, 5.0, VULPE_AURORA_VELO, 1.0);
    let radio_mod = adp_mod_param(25u, 50.0, 1000.0, VULPE_AURORA_RADIO, 300.0) / 300.0;
    let cortina_mod = adp_mod_param(27u, 0.0, 5.0, VULPE_AURORA_CORTINA, 1.0);
    let suelo = OPC_AURORA_SUELO;
    let base = suelo + OPC_AURORA_FIN_VELO * ma.mult_velo * velo_mod;
    let dia = select(0.0, m.dia, m.tiene_tiempo) + frame.day_time;
    let activa = o.activa && opc_fractal().activo && noche > 0.0 && adp_es_superficie();
    let radio = OPC_AURORA_RADIO * ma.mult_radio * radio_mod;
    let largo = OPC_AURORA_LARGO * ma.mult_largo * cortina_mod;
    return VolAurora(activa, noche, min(radio, alcance), base, base + largo,
                     OPC_AURORA_INTENSIDAD * ma.mult_intensidad * ADP_AURORA_ESCALA * o.brillo, dia, adp_aurora_depuracion(), o.muestras);
}

