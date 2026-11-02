// Ajustes de la niebla volumétrica y las nubes. Porqué: docs/efectos/niebla-y-nubes.md §Opciones
override niebla: bool = true;
override niebla_pasos: i32 = 8;
override niebla_cantidad: f32 = 1.0;
override niebla_lluvia: f32 = 1.0;
override niebla_bruma: f32 = 1.0;
override niebla_caida: f32 = 25.0;          // por mil y bloque
override niebla_alcance: f32 = 512.0;       // bloques
override nubes: bool = true;
override nubes_calidad: u32 = 1u;           // baja, media, alta
override nubes_viento: f32 = 1.0;
override nubes_sombras: f32 = 100.0;        // %
override tiempo_aleatorio: bool = true;

const OPC_VIENTO: vec2<f32> = vec2<f32>(3.0, 1.2);     // bloques por segundo con la opción a 1
const OPC_PERFIL_FIJO: u32 = 3u;                       // sin tiempo aleatorio: pequeños y grandes

struct OpcVolumen {
    niebla: bool,
    pasos: i32,
    cantidad: f32,
    lluvia: f32,
    bruma: f32,
    caida: f32,
    alcance: f32,
    nubes: bool,
    pasos_nubes: i32,
    viento: f32,
    sombra_nubes: f32,
    aleatorio: bool,
}

fn opc_volumen() -> OpcVolumen {
    let pasos_nubes = array<i32, 3>(6, 10, 16)[min(nubes_calidad, 2u)];
    return OpcVolumen(
        niebla, niebla_pasos, niebla_cantidad, niebla_lluvia, niebla_bruma, niebla_caida * 0.001, niebla_alcance,
        nubes, pasos_nubes, nubes_viento, nubes_sombras * 0.01, tiempo_aleatorio,
    );
}
