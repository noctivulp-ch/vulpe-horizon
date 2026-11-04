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

// Desplazamiento horizontal de una planta en `mundo` (bloques): periodos distintos en x y z, fase anclada al mundo
// (el viento recorre el campo como una ola), un sesgo en la dirección del viento y una amplitud que respira. La y
// baja lo que se inclina la planta: se dobla, no se desliza.
fn sup_viento_planta(mundo: vec3<f32>, v: SupViento) -> vec3<f32> {
    let t = v.tiempo;
    let w = MAT_TAU / v.planta_periodo;
    let fase = dot(mundo.xz, vec2<f32>(0.35, 0.22)) + mundo.y * 0.1;
    let respira = 0.85 + 0.35 * sin(t * 0.21 + dot(mundo.xz, vec2<f32>(0.02, 0.015)));
    let x = sin(t * w + fase) * 0.6 + 0.25;
    let z = sin(t * w * 0.75 + fase * 1.3 + 1.7) * 0.45 + 0.1;
    let h = vec2<f32>(x, z) * v.planta_amplitud * respira * v.fuerza;
    return vec3<f32>(h.x, -length(h), h.y);
}

// Hojas y colgantes: 3D con poca amplitud vertical y frecuencias algo distintas por eje.
fn sup_viento_hoja(mundo: vec3<f32>, v: SupViento) -> vec3<f32> {
    let t = v.tiempo;
    let w = MAT_TAU / v.hoja_periodo;
    let fase = dot(mundo, vec3<f32>(0.31, 0.17, 0.23));
    let respira = 0.85 + 0.35 * sin(t * 0.19 + dot(mundo.xz, vec2<f32>(0.018, 0.021)));
    let d = vec3<f32>(sin(t * w + fase), sin(t * w * 1.2 + fase * 1.2 + 2.1) * v.hoja_vertical, sin(t * w * 0.8 + fase * 0.8 + 4.0));
    return d * v.hoja_amplitud * respira * v.fuerza;
}
