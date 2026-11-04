// Ajustes de la oclusión ambiental. Porqué: docs/efectos/oclusion-ambiental.md §Opciones
override ao: u32 = 1u;                  // apagada, normal, alta
override ao_fuerza: f32 = 1.0;

// Ajustados a paridad/08 con tools/paridad/ao_rincon.py (rincón suelo–pared con la pared a 3, 8 y 20 bloques).
const OPC_AO_RADIO_K: f32 = 0.19;       // radio en el mundo por bloque de distancia a la cámara
const OPC_AO_RADIO_MIN: f32 = 0.3;      // bloques
const OPC_AO_RADIO_MAX: f32 = 3.0;      // bloques
const OPC_AO_ESCALA: f32 = 0.8;         // de la suma: la arista queda en ~0,8 de AO cruda (0,77 en el original)
const OPC_AO_CURVA: f32 = 4.0;          // exponente sobre la luz indirecta (x⁴, el del original)

struct OpcAo {
    muestras: i32,          // 0 apagada
    fuerza: f32,
}

fn opc_ao() -> OpcAo {
    return OpcAo(array<i32, 3>(0, 7, 20)[min(ao, 2u)], ao_fuerza);
}
