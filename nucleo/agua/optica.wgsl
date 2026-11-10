// Óptica del agua: absorción, dispersión, Fresnel, ventana de Snell y detección del cielo vanilla en el espejo.
// Porqué: docs/efectos/agua.md §Absorción y §Reflejo

struct AguOlas {
    fuerza: f32,        // amplitud relativa (opción × lluvia)
    tiempo: f32,        // segundos × velocidad
    calma: f32,         // escala mínima del oleaje en las zonas en calma
    agudeza: f32,       // de las cáusticas (1 neutro)
}

struct AguMedio {
    absorcion: vec3<f32>,   // σ_a por bloque
    dispersion: f32,        // σ_s por bloque (gris)
    color_disperso: vec3<f32>,
}

// `absorcion` es la extinción total por bloque (la de la transmitancia medida, paridad 07); `claridad` la divide.
fn agu_medio(claridad: f32, absorcion: vec3<f32>, dispersion: f32, color_disperso: vec3<f32>) -> AguMedio {
    let c = max(claridad, 0.05);
    return AguMedio(absorcion / c, dispersion / c, color_disperso);
}

fn agu_transmitancia(m: AguMedio, distancia: f32) -> vec3<f32> {
    return exp(-m.absorcion * max(distancia, 0.0));
}

// Lo que se ve a través del agua: lo refractado absorbido más la luz dispersada por el agua (es lo que hace el
// agua profunda azul oscuro y no negra).
fn agu_a_traves(refractado: vec3<f32>, distancia: f32, ambiente: vec3<f32>, m: AguMedio) -> vec3<f32> {
    let t = agu_transmitancia(m, distancia);
    let disperso = m.color_disperso * ambiente * (1.0 - exp(-m.dispersion * distancia * 8.0));
    return refractado * t + disperso;
}

// Fresnel de una interfaz agua-aire vista desde el lado del aire (Schlick).
fn agu_fresnel(cos_vista: f32, f0: f32) -> f32 {
    return f0 + (1.0 - f0) * pow(1.0 - clamp(cos_vista, 0.0, 1.0), 5.0);
}

// Vista desde dentro (n 1,333 → 1): por fuera del ángulo crítico (~48,6° de la normal) reflexión total.
fn agu_fresnel_dentro(cos_vista: f32, f0: f32) -> f32 {
    let seno2 = (1.0 - cos_vista * cos_vista) * 1.777;
    if seno2 >= 1.0 {
        return 1.0;
    }
    let cos_t = sqrt(1.0 - seno2);
    return f0 + (1.0 - f0) * pow(1.0 - cos_t, 5.0);
}

// Peso 0..1 de que un téxel del espejo sea cielo vanilla: parecido de color con el degradado vanilla esperado en la
// dirección reflejada (cenit `cielo`, horizonte `niebla`, en espacio de pantalla), y elevación. Si el color falla
// (de noche todo es casi negro), manda la elevación.
fn agu_peso_cielo(texel: vec3<f32>, elevacion_seno: f32, cielo: vec3<f32>, niebla: vec3<f32>) -> f32 {
    let esperado = mix(niebla, cielo, smoothstep(0.0, 0.5, elevacion_seno));
    let diferencia = length(texel - esperado) / (length(esperado) + 0.05);
    let color = 1.0 - smoothstep(0.08, 0.25, diferencia);
    let alto = smoothstep(0.0, 0.26, elevacion_seno);
    let oscuro = 1.0 - smoothstep(0.02, 0.1, length(esperado));
    return max(color * alto, alto * oscuro);
}
