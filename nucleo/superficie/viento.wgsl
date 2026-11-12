// Vegetación ondulante: suma de senos con fase espacial (Sousa, GPU Gems 3 cap. 16). Porqué: docs/efectos/vegetacion-ondulante.md

struct SupViento {
    tiempo: f32,            // segundos × velocidad
    fuerza: f32,            // opción × (1 + lluvia)
    planta_periodo: f32,    // s, del vaivén principal
    planta_amplitud: f32,   // bloques
    hoja_periodo: f32,
    hoja_amplitud: f32,
    hoja_vertical: f32,     // fracción vertical del vaivén de las hojas
}

// Forma del movimiento (formas/vegetacion.md, F-38): longitud de onda de la ola en el mundo, periodos lentos y la
// respiración común a todo el prado. Porqué: docs/efectos/vegetacion-ondulante.md §«Forma (F-38)»
const SUP_VIENTO_ONDA: f32 = 6.3;               // bloques: en fase a ~6, en contrafase a ~3
const SUP_VIENTO_PLANTA_PERIODO_Z: f32 = 7.0;   // s, el eje lento de las plantas
const SUP_VIENTO_HOJA_PERIODOS: vec2<f32> = vec2<f32>(18.5, 1.2); // s: segundo eje horizontal y vertical de las hojas
const SUP_VIENTO_RESPIRA_PERIODO: f32 = 6.3;    // s, rachas: de 0,2 a 1,2 de la amplitud media, todo el prado a la vez

fn sup_viento_respira(t: f32) -> f32 {
    return 0.7 + 0.5 * sin(t * MAT_TAU / SUP_VIENTO_RESPIRA_PERIODO);
}

// Desplazamiento de una planta en `mundo` (bloques): una ola que viaja en x (rápida) y en z (lenta) con la misma
// longitud de onda, un poco desfasada con la altura, con sesgo hacia un lado y la respiración común. La y baja lo que
// se inclina la planta: se dobla, no se desliza.
fn sup_viento_planta(mundo: vec3<f32>, v: SupViento) -> vec3<f32> {
    let t = v.tiempo;
    let k = MAT_TAU / SUP_VIENTO_ONDA;
    let alto = mundo.y * 0.1;
    let x = sin(t * MAT_TAU / v.planta_periodo - mundo.x * k + alto) * 0.6 + 0.25;
    let z = sin(t * MAT_TAU / SUP_VIENTO_PLANTA_PERIODO_Z - mundo.z * k + alto + 1.7) * 0.45 + 0.1;
    let h = vec2<f32>(x, z) * v.planta_amplitud * sup_viento_respira(t) * v.fuerza;
    return vec3<f32>(h.x, -length(h), h.y);
}

// Hojas y colgantes: temblor en tres ejes (4,4 s, 18,5 s y 1,2 s en vertical con una quinta parte), con la fase en los
// tres ejes a la misma longitud de onda: la copa ondula por zonas. No bajan.
fn sup_viento_hoja(mundo: vec3<f32>, v: SupViento) -> vec3<f32> {
    let t = v.tiempo;
    let k = MAT_TAU / SUP_VIENTO_ONDA;
    let fase = (mundo.x + mundo.y + mundo.z) * k;
    let d = vec3<f32>(
        sin(t * MAT_TAU / v.hoja_periodo - fase),
        sin(t * MAT_TAU / SUP_VIENTO_HOJA_PERIODOS.y - fase + 2.1) * v.hoja_vertical,
        sin(t * MAT_TAU / SUP_VIENTO_HOJA_PERIODOS.x - fase + 4.0),
    );
    return d * v.hoja_amplitud * sup_viento_respira(t) * v.fuerza;
}
