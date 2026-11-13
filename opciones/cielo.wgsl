// Ajustes del cielo y la atmósfera. Porqué: docs/efectos/cielo-y-atmosfera.md §Opciones
override orbita_sol: i32 = -35;             // grados: inclinación de la órbita del sol (§1)
const OPC_CIELO_BRILLO_DEFECTO: f32 = 0.0;  // pasos (EV), resuelto por estilo_cielo / mod nativo
const CIELO_BRUMA: f32 = 0.0;               // pasos (EV) sobre los aerosoles
const SOL_TEMPERATURA: f32 = 6000.0;        // K
const OPC_LUNA_BRILLO_DEFECTO: f32 = 0.0;   // pasos (EV), resuelto por estilo_noches / mod nativo
const OPC_ESTRELLAS_DEFECTO: bool = true;
const ESTRELLAS_BRILLO: f32 = 0.0;          // pasos (EV)

// Proporciones de partida (convenciones.md §Escala de luz), no opciones.
const OPC_LUNA_PROPORCION: f32 = 1.0 / 300.0;
const OPC_LUNA_TEMPERATURA: f32 = 10000.0;
// Disco del sol (paridad/01, tabla del disco): pleno hasta ~0,95°, nulo hacia 1,6°; radiancia 702,9 × luz directa.
const OPC_SOL_DISCO_RADIO: f32 = 0.02225;   // rad (1,275°): radio medio del perfil
const OPC_SOL_DISCO_BORDE: f32 = 0.255;     // fracción del radio: borde de 0,95° a 1,6°
const OPC_SOL_DISCO_BRILLO: f32 = 702.9;    // radiancia del disco / luz directa del sol
// Destello analítico del disco en el bloom (el «picture» de 8 bits recorta el disco: ADR 0004).
// Porqué: docs/efectos/bloom.md §Destello del sol
const OPC_DESTELLO_MUESTRAS: i32 = 8;       // muestras de profundidad en el borde del disco para su visibilidad
const OPC_SOL_RAMPA_GRADOS: f32 = 3.0;      // grados sobre el horizonte donde satura la luz directa (fino/01 §5)
const OPC_LUNA_RAMPA_GRADOS: f32 = 3.0;     // grados bajo el horizonte donde satura la luna (fino/01 §5)
const OPC_ESTRELLAS_BRILLO: f32 = 0.004;
const OPC_CIELO_SATURACION: f32 = 1.0;
// Brillo propio del cielo dibujado en la escala común (paridad/01 da radiancia directa sin duplicar): fino/01 §2
const OPC_CIELO_BRILLO_DIBUJO: f32 = 1.0;

// Cinturón de Venus y sombra de la Tierra en el crepúsculo (01.1): docs/efectos/cielo-y-atmosfera.md §Cinturón de Venus
const OPC_VENUS_SOL_MIN: f32 = -0.26;               // seno de elevación solar donde termina el crepúsculo (~-10°)
const OPC_VENUS_SOL_MAX: f32 = 0.18;                // seno de elevación solar donde empieza el crepúsculo (~+10°)
const OPC_VENUS_VERDE_NARANJA: f32 = 0.22;          // respuesta del verde al pico naranja (~600 nm) de la luz rasante
const OPC_VENUS_VERDE_AZUL: f32 = 0.48;             // piso de verde respecto al azul estratosférico
const OPC_VENUS_ROJO_OZONO: f32 = 0.25;             // absorción de Chappuis sobre el rojo (680 -> ~600 nm) en la estratosfera
const OPC_VENUS_MULTIPLE_LOCAL: f32 = 6.0;          // refuerzo de dispersión múltiple cálida en la banda iluminada
const OPC_VENUS_COLOR: vec3<f32> = vec3<f32>(1.0, 0.56, 0.62);
const OPC_VENUS_ALTURA_FIN: f32 = 18000.0;          // m: techo de la banda de dispersión múltiple cálida
const OPC_SOMBRA_TIERRA_COLOR: vec3<f32> = vec3<f32>(0.46, 0.58, 0.88);
const OPC_SOMBRA_TIERRA_PISO: f32 = 0.0022;         // radiancia ambiente mínima de la bóveda azul sobre la sombra
const OPC_SOMBRA_LIMBO: f32 = 0.008;                // extinción de la troposfera baja en el terminador (coseno cenital)
const OPC_REFRACCION_HORIZONTE: f32 = 0.020;        // refracción rasante en el horizonte hacia el sol
const OPC_LUNA_CREPUSCULO_INICIO: f32 = -0.16;      // el halo de la luna entra tras el crepúsculo civil
const OPC_LUNA_CREPUSCULO_FIN: f32 = -0.05;
const OPC_VENUS_ELEVACION_FIN: f32 = 0.34;          // seno de ~20°: por encima, el cielo vuelve al azul

struct OpcCielo {
    brillo: f32,            // multiplicador
    bruma: f32,             // multiplicador
    sol_color: vec3<f32>,   // luminancia 1
    luna_color: vec3<f32>,  // luminancia 1
    luna_proporcion: f32,
    estrellas: CieAjustesEstrellas,
    estrellas_activas: bool,
    venus: AtmVenus,
}

fn opc_cielo() -> OpcCielo {
    let mod_cielo = opc_estilo_cielo();
    let mod_noches = opc_estilo_noches();
    let venus = AtmVenus(
        OPC_VENUS_SOL_MIN,
        OPC_VENUS_SOL_MAX,
        OPC_VENUS_VERDE_NARANJA,
        OPC_VENUS_VERDE_AZUL,
        OPC_VENUS_ROJO_OZONO,
        OPC_VENUS_MULTIPLE_LOCAL,
        OPC_VENUS_COLOR,
        OPC_VENUS_ALTURA_FIN,
        OPC_SOMBRA_TIERRA_COLOR,
        OPC_SOMBRA_TIERRA_PISO,
        OPC_SOMBRA_LIMBO,
        OPC_REFRACCION_HORIZONTE,
        OPC_LUNA_CREPUSCULO_INICIO,
        OPC_LUNA_CREPUSCULO_FIN,
        OPC_VENUS_ELEVACION_FIN,
    );
    let brillo_mod = adp_mod_param(0u, 0.0, 5.0, VULPE_CIELO_BRILLO_MANUAL, 1.0);
    let sol_mod = adp_mod_param(8u, 0.0, 10.0, VULPE_SOL_INTENSIDAD, 1.0);
    let luna_mod = adp_mod_param(9u, 0.0, 5.0, VULPE_LUNA_INTENSIDAD, 1.0);
    return OpcCielo(
        exp2(OPC_CIELO_BRILLO_DEFECTO) * mod_cielo.brillo * brillo_mod,
        exp2(CIELO_BRUMA),
        atm_cuerpo_negro(SOL_TEMPERATURA) * sol_mod,
        atm_cuerpo_negro(OPC_LUNA_TEMPERATURA),
        OPC_LUNA_PROPORCION * exp2(OPC_LUNA_BRILLO_DEFECTO) * mod_noches.mult_luna * luna_mod,
        CieAjustesEstrellas(300.0, 0.99, OPC_ESTRELLAS_BRILLO * exp2(ESTRELLAS_BRILLO)),
        OPC_ESTRELLAS_DEFECTO,
        venus,
    );
}

// Piso del crepúsculo (28 §3, F-55): hasta −6° «todo conserva luz» y de −6° a −12° el cielo cae ~6 veces. La
// dispersión se apaga antes; esta tabla da, por elevación del sol en grados, la luminancia mínima del ambiente como
// fracción de la del sol en el horizonte. Se aplica como ganancia ≥ 1 a la dispersión múltiple del sol (cielo, nubes,
// niebla) y al ambiente de las superficies. Porqué: docs/efectos/cielo-y-atmosfera.md §«Crepúsculo (F-55)»
const OPC_CREPUSCULO_ELEV = array<f32, 7>(-14.0, -12.0, -10.0, -8.0, -6.0, -3.0, 0.0);
const OPC_CREPUSCULO_PISO = array<f32, 7>(0.0, 0.04, 0.15, 0.5, 1.0, 1.0, 1.0);
// La luz que añade el piso se acerca a gris en esta fracción (28 §2: a −6° la sombra es gris lila, 92,89,105).
const OPC_CREPUSCULO_GRIS: f32 = 0.7;
