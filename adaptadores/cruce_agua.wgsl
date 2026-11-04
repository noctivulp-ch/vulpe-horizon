// Cruzar la superficie del agua: con la cámara a menos de OPC_AGUA_CRUCE de ella, el plano cercano puede cortarla y
// parte de la pantalla queda al otro lado. Horizon da `water_plane` solo con el espejo de `reflection`, que el pack no
// usa: el nivel de una fuente es un entero + 8/9 y se confirma con una sonda de profundidad junto a la línea donde ese
// nivel corta el plano cercano; si la línea no cae en la pantalla, el mapa de sombras translúcido o lo confirmado en
// los fotogramas anteriores (texel (2,0).a de bloom2). Porqué: docs/efectos/agua.md §«Cruzar la superficie»

struct AdpSondaAgua {
    nivel: f32,         // la superficie candidata, relativa a la cámara
    en_banda: bool,     // la cámara está a menos de OPC_AGUA_CRUCE de ella
    vista: f32,         // 1 la sonda la ve, 0 la sonda ve otra cosa, −1 la sonda no cae en la pantalla
}

fn adp_sonda_agua() -> AdpSondaAgua {
    let e = frame.camera_position.y;
    let abajo = floor(e - OPC_AGUA_NIVEL) + OPC_AGUA_NIVEL;
    let nivel = select(abajo, abajo + 1.0, abajo + 1.0 - e < e - abajo) - e;
    if abs(nivel) > OPC_AGUA_CRUCE {
        return AdpSondaAgua(nivel, false, -1.0);
    }
    // Columna central: el alto del punto del plano cercano es lineal en v.
    let y0 = view_position(vec2<f32>(0.5, 0.0), 1.0).y;
    let y1 = view_position(vec2<f32>(0.5, 1.0), 1.0).y;
    let v = (nivel - y0) / (y1 - y0);
    // Del lado en que el plano cercano queda en el medio del ojo, donde la superficie se ve a centímetros.
    let lado = select(-1.0, 1.0, (y1 > y0) == (nivel < 0.0));
    let sonda = vec2<f32>(0.5, v + lado * OPC_AGUA_SONDA);
    if sonda.y < 0.0 || sonda.y > 1.0 {
        return AdpSondaAgua(nivel, true, -1.0);
    }
    let d = depth_at(sonda);
    if d <= 0.0 {
        return AdpSondaAgua(nivel, true, 0.0);
    }
    let q = view_position(sonda, d);
    let esperada = abs(nivel) / max(abs(normalize(q).y), 1e-3);
    let hay = abs(length(q) - esperada) < 0.05 + 0.2 * esperada;
    return AdpSondaAgua(nivel, true, select(0.0, 1.0, hay));
}

// Prueba independiente de la pantalla, en el mapa de sombras: el agua está en el nivel si la luz llega justo encima
// de él, no llega justo debajo solo por algo translúcido, y ese algo es un fluido (alfa 1 en shadow_color).
fn adp_agua_en_sombras(nivel: f32) -> bool {
    if frame.has_shadow != 1u {
        return false;
    }
    // Apartado hacia la luz: bajo la cámara está la sombra del propio jugador.
    let l = frame.light_direction.xz;
    let lado = l / max(length(l), 1e-3) * OPC_AGUA_SOMBRA_APARTE;
    let encima = shadow_position(vec3<f32>(lado.x, nivel + OPC_AGUA_SOMBRA_MARGEN, lado.y));
    let debajo = shadow_position(vec3<f32>(lado.x, nivel - OPC_AGUA_SOMBRA_MARGEN, lado.y));
    let luz_encima = textureSampleCompareLevel(shadow_map_translucent, shadow_sampler, encima.xy, encima.z);
    let solido = textureSampleCompareLevel(shadow_map, shadow_sampler, debajo.xy, debajo.z);
    let translucido = textureSampleCompareLevel(shadow_map_translucent, shadow_sampler, debajo.xy, debajo.z);
    let texel = vec2<i32>(debajo.xy * vec2<f32>(textureDimensions(shadow_color)));
    let fluido = textureLoad(shadow_color, texel, 0).a > 0.995;
    return luz_encima > 0.5 && solido > 0.5 && translucido < 0.5 && fluido;
}

fn adp_id_nivel_agua(nivel: f32) -> f32 {
    return floor(frame.camera_position.y + nivel) + OPC_AGUA_ESTADO_BASE;
}

// El estado que se guarda: el id del nivel si se sabe que tiene agua, 0 si no.
fn adp_estado_agua(anterior: f32) -> f32 {
    let s = adp_sonda_agua();
    if !s.en_banda {
        return 0.0;
    }
    let id = adp_id_nivel_agua(s.nivel);
    if s.vista >= 0.0 {
        return select(0.0, id, s.vista > 0.5);
    }
    // Sin sonda: con el ojo dentro, la superficie de encima es agua; si no, lo que se supiera de este nivel.
    let ojo = frame.eye_in == 1u && s.nivel > 0.0;
    return select(0.0, id, ojo || adp_agua_en_sombras(s.nivel) || abs(anterior - id) < 0.5);
}

// x: la superficie del agua junto a la cámara, relativa a ella; y: 1 si la hay.
fn adp_plano_agua_cercano() -> vec2<f32> {
    let s = adp_sonda_agua();
    if !s.en_banda {
        return vec2<f32>(0.0);
    }
    var hay = s.vista > 0.5;
    if s.vista < 0.0 {
        let guardado = textureLoad(bloom2, vec2<i32>(2, 0), 0).a;
        hay = abs(guardado - adp_id_nivel_agua(s.nivel)) < 0.5 || (frame.eye_in == 1u && s.nivel > 0.0)
              || adp_agua_en_sombras(s.nivel);
    }
    return vec2<f32>(s.nivel, select(0.0, 1.0, hay));
}

// Si el píxel está bajo el agua: manda el punto del plano cercano de ese píxel, no lo que hay en el ojo.
fn adp_pixel_bajo_agua(uv: vec2<f32>) -> bool {
    let plano = adp_plano_agua_cercano();
    if plano.y < 0.5 {
        return frame.in_water > 0.5;
    }
    return view_position(uv, 1.0).y < plano.x;
}
