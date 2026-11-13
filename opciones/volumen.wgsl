// Ajustes de la niebla volumétrica y las nubes. Porqué: docs/efectos/niebla-y-nubes.md §Opciones
override niebla_cantidad: i32 = 100;        // % (§1) (0 = sin niebla volumétrica)
override perspectiva_aerea: f32 = 1.0;     // bruma de la distancia (§1)
override nubes_velocidad: f32 = 1.0;        // velocidad de las nubes (§1)
override nubes_sombras: i32 = 100;          // % (§1) (0 = apagadas)

const OPC_NIEBLA_LLUVIA_DEFECTO: f32 = 1.0;
// Ambiente que dispersa el aire y la niebla, como fracción de la luz ambiente de superficie (fino/05 P2–P3, medido): el
// aire, la mitad por unidad de extinción y sin fase; la niebla, 3/4 por la fase cenital (0,5 abajo .. 2,5 arriba).
const OPC_AIRE_AMBIENTE: f32 = 0.5;
const OPC_NIEBLA_AMBIENTE_BASE: f32 = 0.75;
const NIEBLA_CAIDA: f32 = 25.0;             // por mil y bloque
const OPC_NUBES_DEFECTO: u32 = 1u;          // todas las capas por defecto
const NUBES_VIENTO: f32 = 1.0;
const TIEMPO_ALEATORIO: bool = true;

const OPC_VIENTO: vec2<f32> = vec2<f32>(3.0, 1.2);     // bloques por segundo con la opción a 1
const OPC_PERFIL_FIJO: u32 = 10u;                      // sin tiempo aleatorio: cúmulos pequeños y grandes

// Geometría y escalas de las nubes (05.4 y fino/05 §5): docs/efectos/niebla-y-nubes.md §Nubes
// Escalas de formas/nubes.md (F-36): bloques por mosaico de la textura, sacados del semiancho de autocorrelación de cada
// canal (B 41 px, R 20 px de 256) y del tamaño de onda del original. Porqué: docs/efectos/niebla-y-nubes.md §«Forma de las nubes (F-36)»
const OPC_NUBES_ESCALA_ZONAS: vec2<f32> = vec2<f32>(3280.0, 6550.0);  // ruido grande: ondas de ~3 000 y ~6 000 bloques
const OPC_NUBES_ESCALA_FORMA: vec2<f32> = vec2<f32>(920.0, 3350.0);   // ruido de forma: ondas de ~400 y ~1 500 bloques
const OPC_NUBES_ESCALA_ALTO: f32 = 4500.0;                         // bloques: altoestratos
// Erosión: grano grueso 75×18 y 210×50, fino 25×6 y 60×14 bloques (horizontal × vertical) → mosaico de 4 y 8 celdas.
const OPC_NUBES_ESCALA_EROSION: vec4<f32> = vec4<f32>(300.0, 72.0, 840.0, 200.0);
const OPC_NUBES_ESCALA_DETALLE: vec4<f32> = vec4<f32>(200.0, 48.0, 480.0, 112.0);
const OPC_NUBES_INCLINACION: f32 = 0.12;                           // fracción del espesor inclinada por el viento
const OPC_NUBES_EROSION_FUERZA: f32 = 0.5;                         // se resta la mitad de la erosión (§5)
const OPC_NUBES_EROSION_MEDIA: f32 = 0.135;                        // erosión media de la versión barata (§5)
// Pesos del «valor» ajustados sobre la textura (cobertura 1): pequeños 79 % del plano con nube y 18 % densa (meta 82/12),
// grandes 75 % y 6 % (meta 74/5).
const OPC_NUBES_PESOS_PEQUENOS: vec3<f32> = vec3<f32>(3.0, 0.68, 0.595);
const OPC_NUBES_PESOS_GRANDES: vec2<f32> = vec2<f32>(0.5, 1.2);
const OPC_NUBES_SIGMA: vec3<f32> = vec3<f32>(0.45, 0.45, 0.06);    // extinción por bloque
const OPC_NUBES_TRAMO_MAX: f32 = 800.0;                            // bloques: tope del tramo integrado por capa baja
const OPC_NUBES_SOMBRA_TAU: f32 = 200.0;                           // transmitancia de la sombra = exp(−200·d²), d la densidad acumulada (fino/04 tabla B)
const OPC_NUBES_SOMBRA_UMBRAL: f32 = 0.13;                         // cobertura que pierden los cúmulos por la erosión antes de la densidad (fino/04 «Respuesta a la pregunta 9»)
const OPC_NUBES_SOMBRA_ALTO: f32 = 1.0;                            // × la aportación de los altoestratos a la suma de la sombra
// Luz de las nubes medida (fino/05 P1): la fase total sin escala añadida, y la autosombra exp(−5·acumulado) con tomas
// cada 20 bloques hacia el astro en los cúmulos (pequeños, grandes).
const OPC_NUBES_FASE_ESCALA: f32 = 1.0;
const OPC_NUBES_IMPACTO_UMBRAL: f32 = 0.02;                        // densidad desde la que la nube corta la niebla (el «umbral tenue» de fino/05 §1, sin medir)
const OPC_NUBES_HUELLA: f32 = 0.0023;                             // bloques por píxel del volumen (½ resolución, 70° a 1080 px) por bloque de distancia
const OPC_NUBES_AUTOSOMBRA: f32 = 5.0;
const OPC_NUBES_AUTOSOMBRA_PASO: vec2<f32> = vec2<f32>(20.0, 20.0);

// Otras dimensiones (17).
const OPC_NIEBLA_NETHER_DEFECTO: f32 = 1.0;
const OPC_NIEBLA_END_DEFECTO: f32 = 1.0;

fn opc_niebla_nether() -> f32 {
    return OPC_NIEBLA_NETHER_DEFECTO * opc_estilo_atmosfera_nether();
}

fn opc_niebla_end() -> f32 {
    return OPC_NIEBLA_END_DEFECTO * opc_estilo_tormenta_end().densidad;
}

// Niebla de cueva (05.3): constantes con nombre y ajuste desde estilo_cuevas
const OPC_NIEBLA_CUEVA_COLOR: vec3<f32> = vec3<f32>(0.5, 0.5, 0.52); // tinte neutro, sin azul saturado (banco cueva-oscura)
const OPC_NIEBLA_CUEVA_DISTANCIA: f32 = 32.0;                         // bloques: escala de distancia
const OPC_NIEBLA_CUEVA_BRILLO: f32 = 0.0004;                          // irradiancia base reducida para evitar iluminar el fondo de cueva

fn opc_niebla_cueva() -> VolAjustesCueva {
    let mod_cuevas = opc_estilo_cuevas();
    return VolAjustesCueva(
        mod_cuevas.niebla_cueva,
        mod_cuevas.caida,
        mod_cuevas.mult_luz_minima,
        OPC_NIEBLA_CUEVA_DISTANCIA,
        OPC_NIEBLA_CUEVA_COLOR,
        OPC_NIEBLA_CUEVA_BRILLO,
    );
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
        OPC_NUBES_EROSION_FUERZA,
        OPC_NUBES_EROSION_MEDIA,
        OPC_NUBES_ESCALA_DETALLE,
        OPC_NUBES_SIGMA,
        OPC_NUBES_TRAMO_MAX,
        OPC_NUBES_AUTOSOMBRA,
        OPC_NUBES_AUTOSOMBRA_PASO,
        OPC_NIEBLA_AMBIENTE_BASE,
        OPC_NUBES_IMPACTO_UMBRAL,
        OPC_NUBES_HUELLA,
        OPC_NUBES_SOMBRA_TAU,
        OPC_NUBES_SOMBRA_UMBRAL,
        OPC_NUBES_SOMBRA_ALTO,
        OPC_NUBES_PESOS_PEQUENOS,
        OPC_NUBES_PESOS_GRANDES,
        OPC_NUBES_FASE_ESCALA,
    );

    let mod_cuevas = opc_estilo_cuevas();
    let mod_horaria = opc_estilo_niebla_horaria();
    let caida_mod = adp_mod_param(22u, 0.0, 1.0, VULPE_NIEBLA_ALTURA_CAIDA, 0.1) / 0.1;
    let niebla_activa = niebla_cantidad > 0 && mod_cuevas.niebla_cueva;
    let cant = f32(niebla_cantidad) * 0.01;
    let lluvia = OPC_NIEBLA_LLUVIA_DEFECTO * mod_horaria.niebla_lluvia;
    let caida = NIEBLA_CAIDA * 0.001 * mod_cuevas.caida * caida_mod;
    let viento = NUBES_VIENTO * nubes_velocidad;
    let sombra_nubes = f32(nubes_sombras) * 0.01;

    return OpcVolumen(
        niebla_activa, pasos_niebla, cant, lluvia, perspectiva_aerea, caida, alcance_niebla,
        OPC_NUBES_DEFECTO != 0u, capas, pasos_nubes, viento, sombra_nubes, TIEMPO_ALEATORIO,
        forma,
    );
}

// Niebla local de bioma y de clima (21): perfiles por defecto del inventario (extinción por bloque y color lineal).
// Porqué: docs/efectos/niebla-local.md
const OPC_LOCAL_ALCANCE: f32 = 64.0;          // bloques: la niebla local es cercana
const OPC_LOCAL_CALOR: f32 = 1.0;             // temperatura del bioma por encima de la cual es «zona caliente»
const OPC_LOCAL_FRIO: f32 = 0.4;              // por debajo, «zona fría»
const OPC_LOCAL_FUNDIDO: f32 = 4.0;          // segundos en que el clima local entra o sale del todo (F-43; el mod usa lo mismo para el bioma)
const OPC_LOCAL_VIENTO: f32 = 1.0;            // × el viento de la niebla global
const OPC_LOCAL_DESCENSO: f32 = 0.3;          // bloques por segundo que bajan las manchas (sin medir)
// Calor con lluvia: despejado, polvo, tormenta de arena (uno por día).
const OPC_LOCAL_CALOR_UNIF = array<f32, 3>(0.0, 0.03, 0.08);
const OPC_LOCAL_CALOR_MANCHAS = array<f32, 3>(0.0, 0.2, 0.5);
const OPC_LOCAL_CALOR_COLOR = array<vec3<f32>, 3>(vec3<f32>(0.0), vec3<f32>(1.0, 0.5, 0.3), vec3<f32>(2.0, 0.6, 0.2));
// Frío con nieve: nevada ligera, tormenta de nieve, ventisca (uno por día).
const OPC_LOCAL_FRIO_UNIF = array<f32, 3>(0.0085, 0.03, 0.07);
const OPC_LOCAL_FRIO_MANCHAS = array<f32, 3>(0.0, 0.2, 0.3);
const OPC_LOCAL_FRIO_COLOR: vec3<f32> = vec3<f32>(2.0, 3.0, 5.0);
// Bioma (siempre): pantano, jungla, jardín pálido (este, solo con el mod).
const OPC_LOCAL_BIOMA_UNIF = array<f32, 3>(0.01, 0.01, 0.07);
const OPC_LOCAL_BIOMA_MANCHAS = array<f32, 3>(0.05, 0.0, 0.0);
const OPC_LOCAL_BIOMA_COLOR = array<vec3<f32>, 3>(vec3<f32>(0.9, 1.0, 0.3), vec3<f32>(0.5, 1.0, 0.8), vec3<f32>(0.18, 0.2, 0.16));
const OPC_CUEVA_DETECTOR: vec2<f32> = vec2<f32>(0.005, 0.03); // luz de cielo suavizada de la cámara: cueva del todo .. nada (23 §1)
const OPC_INMERSION_FIN: vec3<f32> = vec3<f32>(1.0, 2.0, 5.0); // fin de la niebla de vanilla: lava, nieve en polvo, ceguera (bloques)
