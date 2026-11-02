// Etapa material: compone. Por ahora, la iluminación de vanilla (albedo · tinte · mapa de luz).
fn material(input: MaterialInput) -> Surface {
    let s = adp_material_superficie(input);
    return adp_material_salida(s.albedo * vec4<f32>(s.luz_vanilla, 1.0));
}
