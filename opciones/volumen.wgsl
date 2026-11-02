// Ajustes de la niebla volumétrica y las nubes. Porqué: docs/efectos/niebla-y-nubes.md §Opciones
override niebla: bool = true;
override niebla_pasos: i32 = 8;
override niebla_cantidad: f32 = 1.0;
override niebla_lluvia: f32 = 1.0;
const NIEBLA_BRUMA: f32 = 1.0;
const NIEBLA_CAIDA: f32 = 25.0;          // por mil y bloque
const NIEBLA_ALCANCE: f32 = 512.0;       // bloques
override nubes: u32 = 1u;                   // apagadas, todas, solo cúmulos, solo altoestratos
override nubes_calidad: u32 = 1u;           // baja, media, alta
const NUBES_VIENTO: f32 = 1.0;
override nubes_sombras: f32 = 100.0;        // %
const TIEMPO_ALEATORIO: bool = true;

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
    capas: vec3<f32>,       // 1 por capa dibujada (cúmulos pequeños, grandes, altoestratos)
    pasos_nubes: i32,
    viento: f32,
    sombra_nubes: f32,
    aleatorio: bool,
}

fn opc_volumen() -> OpcVolumen {
    let pasos_nubes = array<i32, 3>(8, 14, 20)[min(nubes_calidad, 2u)];
    return OpcVolumen(
        niebla, niebla_pasos, niebla_cantidad, niebla_lluvia, NIEBLA_BRUMA, NIEBLA_CAIDA * 0.001, NIEBLA_ALCANCE,
        nubes != 0u, array<vec3<f32>, 4>(vec3<f32>(0.0), vec3<f32>(1.0), vec3<f32>(1.0, 1.0, 0.0), vec3<f32>(0.0, 0.0, 1.0))[min(nubes, 3u)], pasos_nubes, NUBES_VIENTO, nubes_sombras * 0.01, TIEMPO_ALEATORIO,
    );
}

// Otras dimensiones (17).
override niebla_nether: f32 = 1.0;
override niebla_end: f32 = 1.0;
