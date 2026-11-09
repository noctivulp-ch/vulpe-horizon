// Ajustes de los presets de calidad. Porqué: docs/efectos/calidad.md §Presets de calidad
override calidad_general: u32 = 1u;
override calidad_sombras: u32 = 0u;
override calidad_niebla: u32 = 0u;
override calidad_nubes: u32 = 0u;
override calidad_ao: u32 = 0u;
override calidad_reflejos: u32 = 0u;
override calidad_fractal: u32 = 0u;

const CALIDAD_BAJA: u32 = 0u;
const CALIDAD_MEDIA: u32 = 1u;
const CALIDAD_ALTA: u32 = 2u;
const CALIDAD_ULTRA: u32 = 3u;

// Resuelve el nivel de calidad: 0u («según la general») hereda `calidad_general`,
// y 1u..4u fijan Baja (0), Media (1), Alta (2) o Ultra (3).
fn opc_nivel_calidad(especifico: u32, general: u32) -> u32 {
    if especifico == 0u {
        return min(general, 3u);
    }
    return min(especifico - 1u, 3u);
}

fn opc_calidad_sombras() -> u32 {
    return opc_nivel_calidad(calidad_sombras, calidad_general);
}

fn opc_calidad_niebla() -> u32 {
    return opc_nivel_calidad(calidad_niebla, calidad_general);
}

fn opc_calidad_nubes() -> u32 {
    return opc_nivel_calidad(calidad_nubes, calidad_general);
}

fn opc_calidad_ao() -> u32 {
    return opc_nivel_calidad(calidad_ao, calidad_general);
}

fn opc_calidad_reflejos() -> u32 {
    return opc_nivel_calidad(calidad_reflejos, calidad_general);
}

fn opc_calidad_fractal() -> u32 {
    return opc_nivel_calidad(calidad_fractal, calidad_general);
}
