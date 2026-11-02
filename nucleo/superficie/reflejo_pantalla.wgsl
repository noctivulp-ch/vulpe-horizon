// Reflejos en espacio de pantalla: trazado del rayo reflejado contra la profundidad de la escena.
// Matrices como datos y profundidad por parámetro. Porqué: docs/efectos/luz-de-superficie.md §Reflejos de pantalla

struct SupCamara {
    vista_proyeccion: mat4x4<f32>,      // relativa a la cámara → recorte (profundidad invertida)
    inversa: mat4x4<f32>,               // recorte → relativa a la cámara
    resolucion: vec2<f32>,
}

struct SupImpacto {
    uv: vec2<f32>,
    peso: f32,      // 0 sin impacto; se funde hacia los bordes de la pantalla
}

fn sup_a_pantalla(c: SupCamara, p: vec3<f32>) -> vec3<f32> {
    let h = c.vista_proyeccion * vec4<f32>(p, 1.0);
    let ndc = h.xyz / h.w;
    return vec3<f32>(mat_ndc_a_uv(ndc.xy), ndc.z);
}

fn sup_desde_pantalla(c: SupCamara, uv: vec2<f32>, d: f32) -> vec3<f32> {
    return mat_proyectar(c.inversa, vec3<f32>(mat_uv_a_ndc(uv), d));
}

// `origen` y `dir` relativos a la cámara (bloques); `pasos` del trazado; `ruido` 0..1 desplaza el primero.
// Pasos crecientes hasta `alcance` bloques, y 4 pasos de bisección al encontrar el cruce (McGuire y Mara
// 2014 trazan en pantalla con DDA; aquí basta un trazado en el espacio de la escena con pasos crecientes).
fn sup_trazar_reflejo(origen: vec3<f32>, dir: vec3<f32>, c: SupCamara, profundidad: texture_depth_2d, pasos: i32, ruido: f32, alcance: f32) -> SupImpacto {
    var antes = 0.0;
    let lado = vec2<i32>(c.resolucion) - 1;
    for (var i = 0; i < pasos; i++) {
        let u = (f32(i) + ruido) / f32(pasos);
        let t = u * u * alcance + 0.05;
        let p = origen + dir * t;
        let s = sup_a_pantalla(c, p);
        if any(s.xy < vec2<f32>(0.0)) || any(s.xy > vec2<f32>(1.0)) || s.z <= 0.0 {
            return SupImpacto(vec2<f32>(0.0), 0.0);
        }
        let d = textureLoad(profundidad, clamp(vec2<i32>(s.xy * c.resolucion), vec2<i32>(0), lado), 0);
        if d <= 0.0 {
            antes = t;
            continue;
        }
        let escena = length(sup_desde_pantalla(c, s.xy, d));
        let rayo = length(p);
        let grosor = 0.3 + t * 0.15;
        if rayo > escena && rayo - escena < grosor {
            // Bisección entre el paso anterior y este.
            var a = antes;
            var b = t;
            for (var k = 0; k < 4; k++) {
                let m = 0.5 * (a + b);
                let q = origen + dir * m;
                let sq = sup_a_pantalla(c, q);
                let dq = textureLoad(profundidad, clamp(vec2<i32>(sq.xy * c.resolucion), vec2<i32>(0), lado), 0);
                if dq > 0.0 && length(q) > length(sup_desde_pantalla(c, sq.xy, dq)) {
                    b = m;
                } else {
                    a = m;
                }
            }
            let f = sup_a_pantalla(c, origen + dir * b);
            let borde = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
            return SupImpacto(f.xy, smoothstep(0.0, 0.08, borde));
        }
        antes = t;
    }
    return SupImpacto(vec2<f32>(0.0), 0.0);
}
