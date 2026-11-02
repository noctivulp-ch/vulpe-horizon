// Etapa sky: compone. Por ahora, el cielo de vanilla sin cambios.
fn sky(input: SkyInput) -> vec4<f32> {
    let rayo = adp_cielo_rayo(input);
    return adp_cielo_salida(rayo.color_vanilla);
}
