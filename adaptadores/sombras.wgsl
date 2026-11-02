// El mapa de sombras de Horizon traducido al punto del núcleo: sesgo por la normal, corrección de fugas,
// densidad del mapa por la distorsión, translúcidos y fundido al borde. Solo en material y post (el cielo no
// tiene `shadow_position`). Porqué: docs/efectos/sombras.md §Adaptadores

struct AdpEntradaSombra {
    posicion: vec3<f32>,    // relativa a la cámara
    normal: vec3<f32>,      // geométrica
    luz_cielo: f32,         // de Minecraft, 0..1
    pixel: vec2<f32>,
}

struct AdpResultadoSombra {
    luz: vec3<f32>,         // 0..1 por canal (teñida por translúcidos)
    grosor: f32,            // bloques hasta el ocluyente
}

// Texels del mapa por bloque en el punto de clip `xy`: derivada radial de xy/(|xy|·k + 1 − k).
fn adp_texeles_por_bloque(xy: vec2<f32>) -> f32 {
    let k = frame.shadow_distortion;
    let r = length(xy);
    let den = r * k + 1.0 - k;
    let derivada = (1.0 - k) / (den * den);
    return derivada * frame.shadow_resolution * 0.5 / max(frame.shadow_distance, 1.0);
}

fn adp_bloques_por_profundidad() -> f32 {
    let m = frame.shadow_view_proj;
    return 1.0 / max(length(vec3<f32>(m[0].z, m[1].z, m[2].z)), 1e-6);
}

// Sombra aproximada por la luz de cielo de Minecraft (más allá del mapa, o sin mapa).
fn adp_sombra_aproximada(luz_cielo: f32) -> f32 {
    return smoothstep(0.86, 0.97, luz_cielo);
}

fn adp_sombra_punto(e: AdpEntradaSombra, o: OpcSombras) -> AdpResultadoSombra {
    let aproximada = adp_sombra_aproximada(e.luz_cielo);
    // Sin luz de cielo no hay sol (corrección de fugas, 2.ª parte).
    let mascara = smoothstep(0.02, 0.35, e.luz_cielo);
    if frame.has_shadow == 0u {
        return AdpResultadoSombra(vec3<f32>(aproximada), mix(2.0, 0.0, aproximada));
    }
    let clip = (frame.shadow_view_proj * vec4<f32>(e.posicion, 1.0)).xy;
    let tpb = adp_texeles_por_bloque(clip);
    // Sesgo por la normal (Holbert): ~0,3 texels de mapa en bloques; más un poco hacia la luz.
    let texel = 1.0 / tpb;
    var pos = e.posicion + e.normal * texel * 0.35 + frame.light_direction * texel * 0.15;
    // Fugas (1.ª parte): en interiores, la muestra se acerca al centro del bloque.
    let interior = 1.0 - smoothstep(0.1, 0.6, e.luz_cielo);
    let mundo = pos + frame.camera_position;
    let centro = floor(mundo - e.normal * 0.01) + 0.5;
    pos += (centro - mundo) * interior * 0.6;

    let mapa = shadow_position(pos);
    let ruido = adp_ruido_azul(e.pixel, 1u);
    let punto = LuzPuntoSombra(mapa, tpb, adp_bloques_por_profundidad(), frame.shadow_resolution, ruido);
    let s = luz_sombra(punto, o.ajustes, shadow_map, shadow_sampler);
    var luz = vec3<f32>(s.luz);

    if o.color && s.luz > 0.0 {
        let detras = textureSampleCompareLevel(shadow_map_translucent, shadow_sampler, mapa.xy, mapa.z);
        if detras < 1.0 {
            let lado = vec2<f32>(textureDimensions(shadow_color));
            let c = textureLoad(shadow_color, vec2<i32>(clamp(mapa.xy * lado, vec2<f32>(0.0), lado - 1.0)), 0);
            luz *= mix(luz_tinte_translucido(c, OPC_AGUA_TINTE), vec3<f32>(1.0), detras);
        }
    }
    // Más allá del mapa: fundido al aproximado en el último 20 % (el mapa cubre un cuadrado).
    let borde = smoothstep(0.8, 1.0, max(abs(clip.x), abs(clip.y)));
    let lejos = select(borde, 0.0, frame.in_water > 0.5);
    luz = mix(luz, vec3<f32>(aproximada), lejos) * mascara;
    return AdpResultadoSombra(luz, mix(s.grosor, 2.0 * (1.0 - aproximada), lejos));
}
