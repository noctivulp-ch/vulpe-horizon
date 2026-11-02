// Luz directa y ambiente de una superficie. Porqué: docs/efectos/luz-de-superficie.md §Difusa y §Ambiente

// Lambert con un pequeño desplazamiento: empieza a iluminar unos grados después de 90° y satura igual, para
// que las caras rasantes no parpadeen.
fn luz_lambert(n_l: f32) -> f32 {
    return clamp((n_l + 0.05) / 1.05, 0.0, 1.0);
}

// Ambiente hemisférico (RTR 4.ª ed. §10.3): cielo arriba, suelo abajo, con un mínimo.
fn luz_hemisferica(n_y: f32, cielo: vec3<f32>, suelo: vec3<f32>) -> vec3<f32> {
    let t = n_y * 0.5 + 0.5;
    return mix(suelo, cielo, t) * mix(0.55, 1.0, t);
}
