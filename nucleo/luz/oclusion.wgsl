// Oclusión ambiental en pantalla: muestreo de disco con la normal (normal-oriented hemisphere, Bavoil y Sainz
// 2008), radio en el mundo que crece con la distancia, corte por distancia contra los halos. Profundidad y matriz por parámetro.
// Porqué: docs/efectos/oclusion-ambiental.md

struct LuzAo {
    inversa: mat4x4<f32>,   // recorte → relativa a la cámara
    vista_proyeccion: mat4x4<f32>,
    resolucion: vec2<f32>,
    radio_k: f32,           // radio en el mundo = distancia × radio_k, entre radio_min y radio_max (bloques)
    radio_min: f32,
    radio_max: f32,
    escala: f32,            // de la suma de oclusión
    muestras: i32,
    fuerza: f32,
    giro: f32,              // 0..1 por píxel y fotograma
}

fn luz_ao_posicion(c: LuzAo, profundidad: texture_depth_2d, uv: vec2<f32>) -> vec4<f32> {
    let lado = vec2<i32>(c.resolucion) - 1;
    let d = textureLoad(profundidad, clamp(vec2<i32>(uv * c.resolucion), vec2<i32>(0), lado), 0);
    return vec4<f32>(mat_proyectar(c.inversa, vec3<f32>(mat_uv_a_ndc(uv), d)), d);
}

// 1 abierto, 0 cerrado. `p` y `n`: posición (relativa a la cámara) y normal del punto en ejes del mundo.
fn luz_ao(p: vec3<f32>, n: vec3<f32>, c: LuzAo, profundidad: texture_depth_2d) -> f32 {
    let dist = length(p);
    let radio = clamp(dist * c.radio_k, c.radio_min, c.radio_max);
    // Radio en pantalla del radio en el mundo, con tope lejos (a ~50 bloques ya no crece el detalle).
    let centro = mat_proyectar(c.vista_proyeccion, p).xy;
    let borde = mat_proyectar(c.vista_proyeccion, p + normalize(cross(n, vec3<f32>(0.37, 0.71, 0.6))) * radio).xy;
    let radio_uv = clamp(length(borde - centro) * 0.5, 2.0 / c.resolucion.y, 0.08) * mix(1.0, 0.5, smoothstep(10.0, 50.0, dist));
    let uv0 = mat_ndc_a_uv(centro);
    let aspecto = c.resolucion.y / c.resolucion.x;
    var suma = 0.0;
    for (var i = 0; i < c.muestras; i++) {
        let r = sqrt((f32(i) + 0.5) / f32(c.muestras));
        let a = (f32(i) * 2.39996 + c.giro * MAT_TAU);
        let uv = uv0 + vec2<f32>(cos(a) * aspecto, sin(a)) * r * radio_uv;
        let s = luz_ao_posicion(c, profundidad, uv);
        if s.w <= 0.0 || s.w >= 1.0 {
            continue;
        }
        let v = s.xyz - p;
        let l2 = dot(v, v);
        let r2 = radio * radio;
        if l2 >= r2 {
            continue;
        }
        let coseno = dot(v * inverseSqrt(max(l2, 1e-6)), n);
        // Sesgo: una cara plana no se ocluye a sí misma; corte cuadrático estricto para evitar halos en siluetas.
        let peso = max(0.0, 1.0 - l2 / r2);
        suma += max(0.0, coseno - 0.15) * peso;
    }
    return max(1.0 - c.fuerza * suma / f32(c.muestras) * c.escala, 0.0);
}
