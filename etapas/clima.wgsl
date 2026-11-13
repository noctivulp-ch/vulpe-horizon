// Etapa weather: compone la luz de la lluvia y la nieve (subsistema 16). Porqué: docs/efectos/lluvia-y-nieve.md
fn weather(input: WeatherInput) -> vec4<f32> {
    // Con el mod dibujando la lluvia y la nieve como partículas (26, bit 7 de frame.mods), el pack no dibuja las suyas;
    // el mojado, los charcos y la niebla de lluvia siguen. Porqué: docs/efectos/lluvia-y-nieve.md §«Partículas del mod (F-51)»
    if adp_mod().clima_particulas {
        return vec4<f32>(0.0);
    }
    return adp_clima(input);
}
