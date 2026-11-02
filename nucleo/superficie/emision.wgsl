// Emisión de luz propia. Porqué: docs/efectos/luz-de-superficie.md §Emisión

// Sin paquete PBR: emiten los téxeles brillantes del bloque (la llama de la antorcha, no el palo).
fn sup_emision_texeles(albedo: vec3<f32>, emision_bloque: f32) -> f32 {
    if emision_bloque <= 0.0 {
        return 0.0;
    }
    let brillo = max(albedo.r, max(albedo.g, albedo.b));
    return smoothstep(0.35, 0.75, brillo) * emision_bloque;
}
