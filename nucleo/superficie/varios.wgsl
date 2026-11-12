// Curvatura del mundo, olas grandes del agua en los vértices e infrarrojo (24). Puras. Porqué: docs/efectos/varios.md

// Bajada de un punto con la distancia horizontal a la cámara (relativa): a 128 bloques, 0,1 por punto del ajuste.
fn sup_curvatura(rel: vec3<f32>, ajuste: f32) -> f32 {
    let d2 = dot(rel.xz, rel.xz);
    return -ajuste * 0.1 * d2 / (128.0 * 128.0);
}

// Ondas largas en vertical cuya amplitud crece con la distancia (de 0 a 0,4 bloques a 64). `mundo` absoluto.
fn sup_olas_vertice(mundo: vec3<f32>, distancia: f32, segundos: f32, fuerza: f32) -> f32 {
    let a = fuerza * 0.4 * clamp(distancia / 64.0, 0.0, 1.0);
    let w = sin(dot(mundo.xz, vec2<f32>(0.11, 0.07)) + segundos * 0.9) * 0.6
          + sin(dot(mundo.xz, vec2<f32>(-0.05, 0.13)) + segundos * 1.3) * 0.4;
    return a * w;
}

// Película infrarroja: la vegetación pasa a rosa con su misma luminancia.
fn sup_infrarrojo(albedo: vec3<f32>, color: vec3<f32>, cantidad: f32) -> vec3<f32> {
    let l = dot(albedo, vec3<f32>(0.2126, 0.7152, 0.0722));
    let rosa = color * (l / dot(color, vec3<f32>(0.2126, 0.7152, 0.0722)));
    return mix(albedo, rosa, cantidad);
}
