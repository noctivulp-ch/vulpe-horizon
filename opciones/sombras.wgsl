// Ajustes de las sombras. Porqué: docs/efectos/sombras.md §Opciones
const SOMBRAS_PENUMBRA_MAX: f32 = 30.0;  // radio, texels (el del original)
const SOMBRAS_COLOR: bool = true;

// Radio de la penumbra = mínimo + crecimiento × distancia al ocluyente, en bloques: con el PCF de 8 muestras da una
// anchura de penumbra suave para follaje y copas a distancia (fino/04 §1).
const OPC_SOMBRA_PENUMBRA_MIN: f32 = 0.051;
const OPC_SOMBRA_PENUMBRA_CRECE: f32 = 0.024;

struct OpcSombras {
    ajustes: LuzAjustesSombra,
    color: bool,
}

fn opc_sombras() -> OpcSombras {
    let nivel = opc_calidad_sombras();
    var variable = true;
    var muestras = 8;
    var busqueda = 4;
    switch nivel {
        case 0u: { // Baja: penumbra fija, filtro 4
            variable = false;
            muestras = 4;
            busqueda = 0;
        }
        case 1u: { // Media: variable, búsqueda 4, filtro 8, radio 5 – 30
            variable = true;
            muestras = 8;
            busqueda = 4;
        }
        case 2u: { // Alta: búsqueda 8, filtro 16 (sombras de contacto calidad 2 pendientes)
            variable = true;
            muestras = 16;
            busqueda = 8;
        }
        default: { // Ultra: búsqueda 16, filtro 32 (sombras de contacto calidad 4 pendientes)
            variable = true;
            muestras = 32;
            busqueda = 16;
        }
    }
    let busq_mod = adp_mod_param(20u, 1.0, 64.0, VULPE_SOMBRAS_PROFUNDIDAD_BUSQUEDA, 16.0);
    if busqueda > 0 && abs(busq_mod - 16.0) > 0.01 {
        busqueda = clamp(i32(round(f32(busqueda) * (busq_mod / 16.0))), 1, 64);
    }
    return OpcSombras(
        LuzAjustesSombra(variable, OPC_SOMBRA_PENUMBRA_MIN, SOMBRAS_PENUMBRA_MAX, muestras, OPC_SOMBRA_PENUMBRA_CRECE, busqueda),
        SOMBRAS_COLOR,
    );
}
