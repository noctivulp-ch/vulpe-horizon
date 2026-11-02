// MaterialInput -> superficie del núcleo, y vuelta a Surface. Porqué: docs/efectos/nucleo.md §Adaptadores

struct AdpSuperficie {
    albedo: vec4<f32>,      // textura por tinte (bioma, sombreado de cara, oclusión)
    luz_vanilla: vec3<f32>, // color del mapa de luz de vanilla para este punto
    posicion: vec3<f32>,    // relativa a la cámara, en bloques
    normal: vec3<f32>,
}

fn adp_material_superficie(input: MaterialInput) -> AdpSuperficie {
    return AdpSuperficie(input.albedo * input.tint, input.lightmap, input.position, input.normal);
}

fn adp_material_salida(color: vec4<f32>) -> Surface {
    return Surface(color);
}
