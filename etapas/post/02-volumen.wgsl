// Pasada 1 (media resolución, destino «volumen»): aire, niebla y nubes en un solo raymarch (subsistema 05).
// Porqué: docs/efectos/niebla-y-nubes.md
fn post(input: PostInput) -> vec4<f32> {
    if opc_quitar(1u) {
        return adp_volumen_salida(VolResultado(vec3<f32>(0.0), 1.0, 0.0, vec3<f32>(0.0)));
    }
    return adp_volumen_salida(adp_volumen(input.uv, input.pixel));
}
