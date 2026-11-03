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
const OPC_PERFIL_FIJO: u32 = 10u;                      // sin tiempo aleatorio: cúmulos pequeños y grandes

// Geometría y escalas de las nubes (05.4): docs/efectos/niebla-y-nubes.md §Nubes
const OPC_NUBES_ESCALA_ZONAS: f32 = 12000.0;                        // bloques: zonas de varios km donde hay nubes
const OPC_NUBES_ESCALA_FORMA: vec2<f32> = vec2<f32>(3600.0, 6400.0);// bloques: forma de cúmulos pequeños y grandes
const OPC_NUBES_ESCALA_ALTO: f32 = 9000.0;                          // bloques: altoestratos
const OPC_NUBES_ESCALA_EROSION: vec2<f32> = vec2<f32>(220.0, 360.0);// bloques: periodo del ruido 3D de erosión
const OPC_NUBES_INCLINACION: f32 = 0.12;                            // fracción del espesor inclinada por el viento
const OPC_NUBES_BASE_REDONDEO: f32 = 25.0;                          // bloques de redondeo en la base plana
const OPC_NUBES_CAIDA_ALTURA: f32 = 0.5;                            // caída exponencial en altura del vector de paridad
const OPC_NUBES_CUPULA_DESDE: f32 = 0.78;                           // inicio del cierre en cúpula
const OPC_NUBES_CUPULA_POTENCIA: f32 = 1.7;                         // exponente del cierre en cúpula
const OPC_NUBES_EROSION_FUERZA: f32 = 0.32;                         // erosión 3D en bordes y cúpula
const OPC_NUBES_SIGMA: vec3<f32> = vec3<f32>(0.45, 0.45, 0.06);     // extinción por bloque (con densidad 0,5 da ~0,225 y 0,03)
const OPC_NUBES_TRAMO_MAX: f32 = 900.0;                             // bloques: tope del tramo integrado por capa baja
const OPC_NUBES_SOMBRA_TAU: f32 = 6.0;                              // espesor óptico de la sombra en el suelo

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
    forma_nubes: VolFormaNubes,
}

fn opc_volumen() -> OpcVolumen {
    let pasos_nubes = array<i32, 3>(8, 14, 20)[min(nubes_calidad, 2u)];
    let forma = VolFormaNubes(
        OPC_NUBES_ESCALA_ZONAS,
        OPC_NUBES_ESCALA_FORMA,
        OPC_NUBES_ESCALA_ALTO,
        OPC_NUBES_ESCALA_EROSION,
        OPC_NUBES_INCLINACION,
        OPC_NUBES_BASE_REDONDEO,
        OPC_NUBES_CAIDA_ALTURA,
        OPC_NUBES_CUPULA_DESDE,
        OPC_NUBES_CUPULA_POTENCIA,
        OPC_NUBES_EROSION_FUERZA,
        OPC_NUBES_SIGMA,
        OPC_NUBES_TRAMO_MAX,
        OPC_NUBES_SOMBRA_TAU,
    );
    return OpcVolumen(
        niebla, niebla_pasos, niebla_cantidad, niebla_lluvia, NIEBLA_BRUMA, NIEBLA_CAIDA * 0.001, NIEBLA_ALCANCE,
        nubes != 0u, array<vec3<f32>, 4>(vec3<f32>(0.0), vec3<f32>(1.0), vec3<f32>(1.0, 1.0, 0.0), vec3<f32>(0.0, 0.0, 1.0))[min(nubes, 3u)], pasos_nubes, NUBES_VIENTO, nubes_sombras * 0.01, TIEMPO_ALEATORIO,
        forma,
    );
}

// Otras dimensiones (17).
override niebla_nether: f32 = 1.0;
override niebla_end: f32 = 1.0;
