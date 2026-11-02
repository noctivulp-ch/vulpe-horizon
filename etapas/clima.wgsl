// Etapa weather: compone la luz de la lluvia y la nieve (subsistema 16). Porqué: docs/efectos/lluvia-y-nieve.md
fn weather(input: WeatherInput) -> vec4<f32> {
    return adp_clima(input);
}
