// Mojado y charcos con la lluvia. Porqué: docs/efectos/luz-de-superficie.md §Humedad

struct SupHumedad {
    mojado: f32,    // 0..1
    charco: f32,    // 0..1
}

// `humedad`: frame.wetness; `cielo`: luz de cielo de Minecraft 0..1; `mundo`: posición absoluta;
// `arriba`: componente y de la normal; `tiempo`: segundos (las gotas escurren en las caras verticales).
fn sup_humedad(humedad: f32, cielo: f32, mundo: vec3<f32>, arriba: f32, tiempo: f32) -> SupHumedad {
    let borde = rui_valor2(mundo.xz * 0.7) * 0.06;
    let expuesto = smoothstep(0.82, 0.92, cielo + borde);
    let mojado = humedad * expuesto;
    var charco = 0.0;
    if arriba > 0.9 && mojado > 0.0 {
        let n = rui_fbm2(mundo.xz / 9.0, rui_fbm_estandar(3));
        charco = smoothstep(0.0, 0.08, mojado * 0.62 - n);
    } else if mojado > 0.0 {
        let gotas = rui_valor2(vec2<f32>(mundo.x + mundo.z, mundo.y * 0.25 + tiempo * 0.4) * 3.0);
        charco = smoothstep(0.7, 0.9, gotas) * mojado * 0.5;
    }
    return SupHumedad(mojado, charco);
}

// Albedo mojado: más oscuro y saturado (los poros se llenan de agua).
fn sup_albedo_mojado(albedo: vec3<f32>, mojado: f32, porosidad: f32) -> vec3<f32> {
    let m = mojado * mix(0.6, 1.0, porosidad);
    return pow(albedo, vec3<f32>(1.0 + 0.7 * m)) * (1.0 - 0.15 * m);
}
