// Etapa tonemap (API 0.2): el mapeo de tonos, la gradación, el aislamiento y los efectos de cámara corren en 07-final;
// esta etapa pasa el resultado lineal tal cual y evita que Horizon aplique una segunda curva encima.
// Porqué: docs/decisiones/0005-api-0-2.md
fn tonemap(input: TonemapInput) -> vec3<f32> {
    return clamp(input.color, vec3<f32>(0.0), vec3<f32>(frame.headroom));
}
