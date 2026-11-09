// Ajustes del relieve geométrico (subsistema 18).
// Porqué: docs/efectos/relieve.md §Opciones

override relieve: f32 = 0.25;

const OPC_RELIEVE_DISTANCIA: f32 = 12.0;
const OPC_RELIEVE_CELDAS: u32 = 16u;
const OPC_RELIEVE_ESCALONADO: bool = false;

struct OpcRelieve {
    activa: bool,
    profundidad: f32,
    distancia: f32,
    celdas: u32,
    escalonado: bool,
}

fn opc_relieve() -> OpcRelieve {
    let prof = max(relieve, 0.0);
    let activa = prof > 0.001;
    let dist = select(OPC_RELIEVE_DISTANCIA, 6.0, calidad_general == 0u);
    return OpcRelieve(
        activa,
        prof,
        dist,
        OPC_RELIEVE_CELDAS,
        OPC_RELIEVE_ESCALONADO,
    );
}
