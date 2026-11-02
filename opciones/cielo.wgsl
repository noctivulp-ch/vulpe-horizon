// Ajustes del cielo y la atmósfera. Porqué: docs/efectos/cielo-y-atmosfera.md §Opciones
override cielo_brillo: f32 = 0.0;           // pasos (EV)
override cielo_bruma: f32 = 0.0;            // pasos (EV) sobre los aerosoles
override sol_temperatura: f32 = 6000.0;     // K
override luna_brillo: f32 = 0.0;            // pasos (EV)
override estrellas: bool = true;
override estrellas_brillo: f32 = 0.0;       // pasos (EV)

// Proporciones de partida (convenciones.md §Escala de luz), no opciones.
const OPC_LUNA_PROPORCION: f32 = 1.0 / 300.0;
const OPC_LUNA_TEMPERATURA: f32 = 10000.0;
const OPC_SOL_DISCO_RADIO: f32 = 0.014;     // rad: unas tres veces el real
const OPC_SOL_DISCO_BRILLO: f32 = 12.0;     // radiancia del disco / irradiancia del sol
const OPC_ESTRELLAS_BRILLO: f32 = 0.004;
const OPC_MULTIPLE_REFUERZO: f32 = 0.4;
const OPC_BRUMA_BASE: f32 = 5.0;
const OPC_CIELO_SATURACION: f32 = 1.0;
// Brillo propio del cielo dibujado (no de la luz ambiente que da al terreno): docs/efectos/cielo-y-atmosfera.md §Montaje
const OPC_CIELO_BRILLO_DIBUJO: f32 = 2.0;

struct OpcCielo {
    brillo: f32,            // multiplicador
    bruma: f32,             // multiplicador
    sol_color: vec3<f32>,   // luminancia 1
    luna_color: vec3<f32>,  // luminancia 1
    luna_proporcion: f32,
    estrellas: CieAjustesEstrellas,
    estrellas_activas: bool,
}

fn opc_cielo() -> OpcCielo {
    return OpcCielo(
        exp2(cielo_brillo),
        exp2(cielo_bruma) * OPC_BRUMA_BASE,
        atm_cuerpo_negro(sol_temperatura),
        atm_cuerpo_negro(OPC_LUNA_TEMPERATURA),
        OPC_LUNA_PROPORCION * exp2(luna_brillo),
        CieAjustesEstrellas(300.0, 0.99, OPC_ESTRELLAS_BRILLO * exp2(estrellas_brillo)),
        estrellas,
    );
}
