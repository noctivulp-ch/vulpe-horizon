// Luz directa y ambiente de una superficie. Porqué: docs/efectos/luz-de-superficie.md §Difusa y §Ambiente

// Lambert con margen (implementacion/01 §1.2): cero por debajo de un coseno de 0,06 y de ahí en línea recta hasta 1.
fn luz_lambert(n_l: f32) -> f32 {
    return clamp((n_l - 0.06) / 0.94, 0.0, 1.0);
}

// Modulación direccional de la luz de cielo (fino/03 §2 y paridad/03): normal en norma L1, factor dependiente
// del nivel de luz de cielo (isótropo en penumbra) y cota superior recortada por oclusión ambiental.
fn luz_direccion_cielo(n: vec3<f32>, luz_cielo: f32, cruzada: bool, ao: f32) -> f32 {
    let sum_l1 = abs(n.x) + abs(n.y) + abs(n.z);
    let ny_l1 = select(n.y / max(sum_l1, 1e-5), 1.0, cruzada);
    let f_base = select(
        mix(0.356, 0.08, clamp(-ny_l1 * 2.0, 0.0, 1.0)),
        mix(0.356, 1.0, ny_l1),
        ny_l1 >= 0.0
    );
    let s = clamp(luz_cielo, 0.0, 1.0);
    let f_dir = mix(1.0, f_base, s);
    let cota_ao = mix(0.356, 1.0, clamp(ao, 0.0, 1.0));
    return min(f_dir, cota_ao);
}

// Ambiente hemisférico para dimensiones Nether y End: cielo arriba, suelo abajo con un mínimo.
fn luz_hemisferica(n_y: f32, cielo: vec3<f32>, suelo: vec3<f32>) -> vec3<f32> {
    let t = n_y * 0.5 + 0.5;
    return mix(suelo, cielo, t) * mix(0.55, 1.0, t);
}
