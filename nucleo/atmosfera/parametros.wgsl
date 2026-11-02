// Parámetros físicos de la atmósfera (dos componentes y ozono). Porqué: docs/efectos/cielo-y-atmosfera.md §Modelo
// tools/atmosfera/generar_tabla.py lee de aquí estos valores (los números de atm_tierra en orden y las
// constantes ATM_): no cambiar su formato sin cambiar el lector.

// Irradiancia del sol en lo alto de la atmósfera, escala común: la que deja el sol de mediodía en π
// (blanco perpendicular = 1). La calcula y escribe generar_tabla.py.
const ATM_IRRADIANCIA_SOL: f32 = 3.6298;
// Altura del observador sobre el suelo del planeta con la cámara a ras de suelo, m.
const ATM_ALTURA_OBSERVADOR: f32 = 250.0;
// Albedo medio del suelo para la fila de suelo de la tabla.
const ATM_ALBEDO_SUELO: f32 = 0.25;
// Peso del término isótropo de dispersión múltiple (con 1 el cielo de mediodía salía gris).
const ATM_MULTIPLE: f32 = 0.4;

struct AtmParametros {
    radio_planeta: f32,         // m
    radio_atmosfera: f32,       // m
    rayleigh_dispersion: vec3<f32>,  // m⁻¹ a nivel del mar
    rayleigh_altura: f32,       // altura de escala, m
    mie_dispersion: f32,        // m⁻¹ a nivel del mar (gris)
    mie_absorcion: f32,         // m⁻¹
    mie_altura: f32,            // m
    mie_asimetria: f32,         // g de la fase
    ozono_absorcion: vec3<f32>, // m⁻¹ en el pico
    ozono_centro: f32,          // m
    ozono_semiancho: f32,       // m
}

// Valores de Hillaire 2020 (tabla 1) y Bruneton 2017, con los aerosoles ×5 (halo del sol amplio y blanco como
// en la referencia; docs/efectos/cielo-y-atmosfera.md §Modelo).
fn atm_tierra() -> AtmParametros {
    return AtmParametros(
        6360e3, 6460e3,
        vec3<f32>(5.802e-6, 13.558e-6, 33.1e-6), 8000.0,
        19.98e-6, 2.22e-6, 1200.0, 0.8,
        vec3<f32>(0.650e-6, 1.881e-6, 0.085e-6), 25000.0, 15000.0,
    );
}
