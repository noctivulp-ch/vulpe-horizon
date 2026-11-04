// Curvas de la luz de cielo y de bloque de Minecraft (0..1) a intensidad. Porqué: docs/efectos/luz-de-superficie.md §Curvas

// Muy cerrada al principio, casi lineal al final: los huecos interiores se oscurecen rápido y el
// exterior queda pleno.
fn luz_curva_cielo(l: f32) -> f32 {
    let x = clamp(l, 0.0, 1.0);
    return (x * x + pow(x, 15.0)) * 0.5;
}

// Luz de una antorcha por nivel de luz de bloque (nivel / 15), en la escala común (1 = sol en el cenit sobre blanco de
// Lambert), del canal más fuerte del color: medida en paridad/03 (16 niveles), interpolada. Pegada a la fuente ≈ 1,5
// veces el sol de mediodía; a 3 bloques (nivel 12), 0,23.
const LUZ_TABLA_BLOQUE = array<f32, 16>(0.0, 0.0006768, 0.002807, 0.006561, 0.01215, 0.01982, 0.02991, 0.04282, 0.0591,
    0.07952, 0.1052, 0.1395, 0.2277, 0.4489, 0.8639, 1.472);

fn luz_curva_bloque(l: f32) -> f32 {
    let f = clamp(l, 0.0, 1.0) * 15.0;
    let i = min(i32(f), 14);
    return mix(LUZ_TABLA_BLOQUE[i], LUZ_TABLA_BLOQUE[i + 1], f - f32(i));
}
