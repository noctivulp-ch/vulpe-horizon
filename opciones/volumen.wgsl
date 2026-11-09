// Ajustes de la niebla volumétrica y las nubes. Porqué: docs/efectos/niebla-y-nubes.md §Opciones
override niebla_cantidad: i32 = 100;        // % (§1) (0 = sin niebla volumétrica)
override perspectiva_aerea: f32 = 1.0;     // bruma de la distancia (§1)
override nubes_velocidad: f32 = 1.0;        // velocidad de las nubes (§1)
override nubes_sombras: i32 = 100;          // % (§1) (0 = apagadas)

const OPC_NIEBLA_LLUVIA_DEFECTO: f32 = 1.0;
const NIEBLA_CAIDA: f32 = 25.0;             // por mil y bloque
const OPC_NUBES_DEFECTO: u32 = 1u;          // todas las capas por defecto
const NUBES_VIENTO: f32 = 1.0;
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
const OPC_NUBES_EROSION_FUERZA: f32 = 0.45;                         // erosión gruesa: recorte de la envolvente (lóbulos)
const OPC_NUBES_EROSION_BASE: f32 = 0.4;                            // fracción de la erosión que queda en la base plana
const OPC_NUBES_ESCALA_DETALLE: f32 = 70.0;                         // bloques: periodo del ruido 3D fino (coliflores)
const OPC_NUBES_DETALLE_FUERZA: f32 = 0.35;                         // erosión fina
const OPC_NUBES_SIGMA: vec3<f32> = vec3<f32>(0.45, 0.45, 0.06);     // extinción por bloque (con densidad 0,5 da ~0,225 y 0,03)
const OPC_NUBES_TRAMO_MAX: f32 = 900.0;                             // bloques: tope del tramo integrado por capa baja
const OPC_NUBES_SOMBRA_TAU: f32 = 6.0;                              // espesor óptico de la sombra en el suelo

// Otras dimensiones (17).
const OPC_NIEBLA_NETHER_DEFECTO: f32 = 1.0;
const OPC_NIEBLA_END_DEFECTO: f32 = 1.0;

fn opc_niebla_nether() -> f32 {
    return OPC_NIEBLA_NETHER_DEFECTO * opc_estilo_atmosfera_nether();
}

fn opc_niebla_end() -> f32 {
    return OPC_NIEBLA_END_DEFECTO * opc_estilo_tormenta_end().densidad;
}

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
    let nivel_niebla = opc_calidad_niebla();
    var pasos_niebla = 6;
    var alcance_niebla = 512.0;
    switch nivel_niebla {
        case 0u: { // Baja: 4 pasos, 256 bloques
            pasos_niebla = 4;
            alcance_niebla = 256.0;
        }
        case 1u: { // Media: 6 pasos, 512 bloques
            pasos_niebla = 6;
            alcance_niebla = 512.0;
        }
        case 2u: { // Alta: 12 pasos, 1024 bloques
            pasos_niebla = 12;
            alcance_niebla = 1024.0;
        }
        default: { // Ultra: 24 pasos, 2048 bloques
            pasos_niebla = 24;
            alcance_niebla = 2048.0;
        }
    }

    let nivel_nubes = opc_calidad_nubes();
    var capas = array<vec3<f32>, 4>(vec3<f32>(0.0), vec3<f32>(1.0), vec3<f32>(1.0, 1.0, 0.0), vec3<f32>(0.0, 0.0, 1.0))[min(OPC_NUBES_DEFECTO, 3u)];
    var pasos_nubes = 14;
    switch nivel_nubes {
        case 0u: { // Baja: ×0,5 pasos, sin cúmulos pequeños
            pasos_nubes = 7;
            capas.x = 0.0;
        }
        case 1u: { // Media: ×1, tres capas
            pasos_nubes = 14;
        }
        case 2u: { // Alta: ×2
            pasos_nubes = 28;
        }
        default: { // Ultra: ×3
            pasos_nubes = 42;
        }
    }

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
        OPC_NUBES_EROSION_BASE,
        OPC_NUBES_ESCALA_DETALLE,
        OPC_NUBES_DETALLE_FUERZA,
        OPC_NUBES_SIGMA,
        OPC_NUBES_TRAMO_MAX,
        OPC_NUBES_SOMBRA_TAU,
    );

    let mod_cuevas = opc_estilo_cuevas();
    let mod_horaria = opc_estilo_niebla_horaria();
    let niebla_activa = niebla_cantidad > 0 && mod_cuevas.niebla_cueva;
    let cant = f32(niebla_cantidad) * 0.01;
    let lluvia = OPC_NIEBLA_LLUVIA_DEFECTO * mod_horaria.niebla_lluvia;
    let caida = NIEBLA_CAIDA * 0.001 * mod_cuevas.caida;
    let viento = NUBES_VIENTO * nubes_velocidad;
    let sombra_nubes = f32(nubes_sombras) * 0.01;

    return OpcVolumen(
        niebla_activa, pasos_niebla, cant, lluvia, perspectiva_aerea, caida, alcance_niebla,
        OPC_NUBES_DEFECTO != 0u, capas, pasos_nubes, viento, sombra_nubes, TIEMPO_ALEATORIO,
        forma,
    );
}
