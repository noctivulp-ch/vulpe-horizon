// Codificación reversible de la escena en el «picture» de 8 bits. Porqué: docs/decisiones/0004-codificacion-del-picture.md

struct ColCodificacion {
    exposicion: f32,    // exposición previa E
    blanco: f32,        // punto blanco W del mapeo por canal
}

fn col_codificar_escena(luz: vec3<f32>, k: ColCodificacion) -> vec3<f32> {
    return col_lineal_a_srgb(col_tonemap_reinhard_maximo(luz * k.exposicion, k.blanco));
}

fn col_decodificar_escena(valor: vec3<f32>, k: ColCodificacion) -> vec3<f32> {
    return col_tonemap_reinhard_maximo_inversa(col_srgb_a_lineal(valor), k.blanco) / k.exposicion;
}
