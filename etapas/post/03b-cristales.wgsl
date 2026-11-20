// Pasada 3b: capas climáticas sobre cristal transparente (`glass` y `glass_pane`) por DDA en `cristal_mapa`.
// Separada de `03-composicion` para no aumentar la presión de registros del sombreado principal en escenas
// sin cristal: cuando no hay cristal transparente cerca o el clima está inactivo sale en 1 lectura.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §Arquitectura y coste
fn post(input: PostInput) -> vec4<f32> {
    let base = textureLoad(composicion_base, vec2<i32>(input.pixel), 0);
    if !OPC_CRISTAL_ACTIVO || !adp_es_superficie() || frame.has_ray_tracing == 0u {
        return base;
    }
    let resumen = cristal_sim[ADP_CS_RESUMEN];
    if resumen.x < 0.5 || resumen.y < 0.5 {
        return base;
    }
    let p = adp_post_pixel(input);
    let dir = adp_post_direccion(p);
    let dist = adp_post_distancia(p);
    let c = adp_cristales_post(base.rgb, p, dir, dist);
    return vec4<f32>(c, base.a);
}
