// Curvas de la luz de cielo y de bloque de Minecraft (0..1) a intensidad. Porqué: docs/efectos/luz-de-superficie.md §Curvas

// Muy cerrada al principio, casi lineal al final: los huecos interiores se oscurecen rápido y el
// exterior queda pleno.
fn luz_curva_cielo(l: f32) -> f32 {
    let x = clamp(l, 0.0, 1.0);
    return (x * x + pow(x, 15.0)) * 0.5;
}

// (1 − √(1 − l))²: de inversa del cuadrado a lineal; más un refuerzo cúbico por encima de 0,7 (pegado a la
// fuente se nota mucho). `refuerzo` es el valor que alcanza en l = 1.
fn luz_curva_bloque(l: f32, refuerzo: f32) -> f32 {
    let x = clamp(l, 0.0, 1.0);
    let base = (1.0 - sqrt(1.0 - x));
    let suave = base * base;
    let cerca = smoothstep(0.7, 1.0, x);
    return mix(suave, refuerzo, cerca * cerca * cerca);
}
