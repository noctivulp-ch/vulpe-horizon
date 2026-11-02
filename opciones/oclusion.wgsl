// Ajustes de la oclusión ambiental. Porqué: docs/efectos/oclusion-ambiental.md §Opciones
override ao: u32 = 1u;                  // apagada, normal, alta
override ao_fuerza: f32 = 1.0;

const OPC_AO_RADIO: f32 = 1.5;          // bloques
const OPC_AO_CURVA: f32 = 2.5;          // exponente sobre la AO: oscurece los huecos y deja lo abierto

struct OpcAo {
    muestras: i32,          // 0 apagada
    fuerza: f32,
}

fn opc_ao() -> OpcAo {
    return OpcAo(array<i32, 3>(0, 7, 20)[min(ao, 2u)], ao_fuerza);
}
